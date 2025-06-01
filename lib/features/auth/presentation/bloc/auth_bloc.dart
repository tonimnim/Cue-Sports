import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pool_billiard_app/core/services/logger_service.dart';
import 'package:pool_billiard_app/core/services/secure_storage_service.dart';
import 'package:dartz/dartz.dart';
import 'package:pool_billiard_app/core/error/failures.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/community.dart';

import 'auth_event.dart';
import 'auth_state.dart';

/// Production-ready Authentication BLoC with Firebase email verification
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoggerService logger;
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;
  final firebase_auth.FirebaseAuth firebaseAuth;
  
  Timer? _emailVerificationTimer;
  int _verificationAttempts = 0;
  static const int _maxVerificationAttempts = 120; // 10 minutes with 5-second intervals

  AuthBloc({
    required this.logger,
    required this.authRepository,
    required this.secureStorage,
    required this.firebaseAuth,
  }) : super(AuthInitial()) {
    // Core authentication events
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ResumeRegistrationEvent>(_onResumeRegistration);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<RefreshTokensEvent>(_onRefreshTokens);
    
    // Registration flow events
    on<StartFanRegistrationEvent>(_onStartFanRegistration);
    on<StartPlayerRegistrationEvent>(_onStartPlayerRegistration);
    on<SelectCommunityEvent>(_onSelectCommunity);
    on<StartEmailVerificationPollingEvent>(_onStartEmailVerificationPolling);
    on<StopEmailVerificationPollingEvent>(_onStopEmailVerificationPolling);
    on<EmailVerificationCompleteEvent>(_onEmailVerificationComplete);
    on<ResendVerificationEmailEvent>(_onResendVerificationEmail);
    on<CreateFirestoreUserEvent>(_onCreateFirestoreUser);
    
    // Payment and cleanup events
    on<VerifyPaymentEvent>(_onVerifyPayment);
    on<FetchCommunitiesEvent>(_onFetchCommunities);
    on<ClearRegistrationDraftEvent>(_onClearRegistrationDraft);
    on<HandlePaymentExpiryEvent>(_onHandlePaymentExpiry);
  }

  @override
  Future<void> close() {
    _emailVerificationTimer?.cancel();
    return super.close();
  }

  /// Check authentication status on app start
  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    try {
      logger.i('🔍 Checking authentication status...');

      // First check local storage for cached auth tokens
      final cachedUser = await authRepository.getCurrentUser();
      
      cachedUser.fold(
        (failure) {
          logger.w('❌ No valid cached session found');
          emit(AuthUnauthenticated());
        },
        (user) {
          if (user == null) {
            logger.i('❌ No authenticated user found');
            emit(AuthUnauthenticated());
            return;
          }
          
          logger.i('✅ User authenticated from cache: ${user.email}');
          
          // Check if player needs to complete payment
          if (user.userType == 'player' && user.paymentStatus == false) {
            final paymentDeadline = user.createdAt.add(const Duration(days: 2));
            if (DateTime.now().isAfter(paymentDeadline)) {
              // Payment deadline expired
              logger.w('⏰ Player payment deadline expired');
              add(HandlePaymentExpiryEvent(userId: user.id));
              return;
            } else {
              // Payment still pending
              logger.i('💳 Player authenticated but payment pending');
              emit(PlayerPaymentRequired(
                user: user,
                paymentDeadline: paymentDeadline,
                paymentId: user.playerPaymentId ?? '',
              ));
              return;
            }
          }
          
          // User is fully authenticated and can access home
          emit(AuthAuthenticated(user: user, isAutoLogin: true));
        },
      );
    } catch (e) {
      logger.e('🔥 Auth status check failed: $e');
      emit(AuthUnauthenticated());
    }
  }

  /// Resume registration from local storage draft
  Future<void> _onResumeRegistration(ResumeRegistrationEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('🔄 Attempting to resume registration...');

      final draft = await secureStorage.getRegistrationDraft();
      if (draft == null) {
        logger.i('❌ No registration draft found');
        emit(AuthUnauthenticated());
        return;
      }

      logger.i('📋 Found registration draft: ${draft.email}, step: ${draft.step}');

      switch (draft.step) {
        case 'details_collected':
          if (draft.draftType == 'fan') {
            emit(RegistrationDraftSaved(
              draft: draft,
              message: 'Fan registration resumed. Ready to create account.',
            ));
          } else {
            emit(RegistrationDraftSaved(
              draft: draft,
              message: 'Player registration resumed. Please select a community.',
            ));
          }
          break;
          
        case 'community_selected':
          emit(RegistrationDraftSaved(
            draft: draft,
            message: 'Community selected. Ready to create account.',
          ));
          break;
          
        case 'auth_account_created':
          if (draft.uid != null) {
            // Continue with email verification polling
            add(StartEmailVerificationPollingEvent(uid: draft.uid!));
      } else {
            // UID missing, restart the flow
            add(CreateFirestoreUserEvent(uid: draft.uid!, draft: draft));
          }
          break;
          
        default:
          logger.w('⚠️ Unknown step in draft: ${draft.step}');
          emit(AuthUnauthenticated());
      }
    } catch (e) {
      logger.e('🔥 Failed to resume registration: $e');
      emit(AuthUnauthenticated());
    }
  }

  /// Start fan registration
  Future<void> _onStartFanRegistration(StartFanRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Preparing fan registration...'));

    try {
      logger.i('🎯 Starting fan registration: ${event.email}');

      // Create registration with Firebase email verification
      final result = await authRepository.registerFan(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) {
          logger.i('📧 Fan registration created. Email verification sent.');
          
          // Save draft for resumption if needed
          final draft = RegistrationDraft(
            draftType: 'fan',
            fullName: event.fullName,
            email: event.email,
            phoneNumber: event.phoneNumber,
            password: event.password,
            uid: user.id,
            step: 'auth_account_created',
            timestamp: DateTime.now(),
          );
          
          secureStorage.saveRegistrationDraft(draft);
          
          emit(EmailVerificationSent(
            email: event.email,
            uid: user.id,
            message: 'We\'ve sent a verification link to ${event.email}. Please check your email.',
          ));
          
          // Start polling for email verification
          add(StartEmailVerificationPollingEvent(uid: user.id));
        },
      );
    } catch (e) {
      logger.e('🔥 Fan registration failed: $e');
      emit(AuthError('Failed to start fan registration: ${e.toString()}'));
    }
  }

  /// Start player registration
  Future<void> _onStartPlayerRegistration(StartPlayerRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Preparing player registration...'));

    try {
      logger.i('⚽ Starting player registration: ${event.email}');

      // Store registration details in secure storage for later use
      final draft = RegistrationDraft(
        draftType: 'player',
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        step: 'details_collected',
        timestamp: DateTime.now(),
      );

      // Save to secure storage
      await secureStorage.saveRegistrationDraft(draft);

      emit(RegistrationDraftSaved(
        draft: draft,
        message: 'Player registration details saved. Please select a community.',
      ));
      
      // The UI should now show community selection screen
    } catch (e) {
      logger.e('🔥 Player registration failed: $e');
      emit(AuthError('Failed to start player registration: ${e.toString()}'));
    }
  }

  /// Select community for player registration
  Future<void> _onSelectCommunity(SelectCommunityEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('🏢 Community selected: ${event.communityId}');

      final currentDraft = await secureStorage.getRegistrationDraft();
      if (currentDraft == null) {
        emit(const AuthError('Registration draft not found. Please start over.'));
        return;
      }

      // Generate payment ID
      final paymentId = 'PB${DateTime.now().millisecondsSinceEpoch}${event.communityId.substring(0, 3).toUpperCase()}';

      // Update draft with community and payment info
      final updatedDraft = currentDraft.copyWith(
        communityId: event.communityId,
        paymentId: paymentId,
        step: 'community_selected',
      );

      await secureStorage.saveRegistrationDraft(updatedDraft);

      // Now create the player account with Firebase
      emit(const AuthLoading(message: 'Creating player account...'));
      
      final result = await authRepository.registerPlayer(
        fullName: updatedDraft.fullName,
        email: updatedDraft.email,
        phoneNumber: updatedDraft.phoneNumber,
        password: updatedDraft.password,
        communityId: event.communityId,
        paymentId: paymentId,
      );
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) {
          logger.i('📧 Player registration created. Email verification sent.');
          
          // Update draft with UID
          final finalDraft = updatedDraft.copyWith(
            uid: user.id,
            step: 'auth_account_created',
          );
          
          secureStorage.saveRegistrationDraft(finalDraft);
          
          emit(EmailVerificationSent(
            email: updatedDraft.email,
            uid: user.id,
            message: 'We\'ve sent a verification link to ${updatedDraft.email}. Please check your email.',
          ));
          
          // Start polling for email verification
          add(StartEmailVerificationPollingEvent(uid: user.id));
        },
      );
    } catch (e) {
      logger.e('🔥 Community selection failed: $e');
      emit(AuthError('Failed to select community: ${e.toString()}'));
    }
  }

  /// Start polling for email verification
  Future<void> _onStartEmailVerificationPolling(StartEmailVerificationPollingEvent event, Emitter<AuthState> emit) async {
    logger.i('⏱️ Starting email verification polling for UID: ${event.uid}');
    
    _verificationAttempts = 0;
    _emailVerificationTimer?.cancel();
    
    emit(PollingEmailVerification(
      email: firebaseAuth.currentUser?.email ?? '',
      uid: event.uid,
      attemptCount: _verificationAttempts,
    ));
    
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        _verificationAttempts++;
        
        if (_verificationAttempts > _maxVerificationAttempts) {
          timer.cancel();
          emit(const AuthError(
            'Email verification timed out. Please try again or contact support.',
          ));
          return;
        }

        // Reload user to get fresh email verification status
        await firebaseAuth.currentUser?.reload();
        final user = firebaseAuth.currentUser;
        
        if (user != null && user.emailVerified) {
          timer.cancel();
          logger.i('✅ Email verification detected!');
          add(EmailVerificationCompleteEvent(uid: user.uid));
        } else {
          // Update polling state with attempt count
          if (!isClosed) {
            emit(PollingEmailVerification(
              email: user?.email ?? '',
              uid: event.uid,
              attemptCount: _verificationAttempts,
            ));
          }
        }
      } catch (e) {
        logger.e('🔥 Error during email verification polling: $e');
        timer.cancel();
        if (!isClosed) {
          emit(AuthError('Error checking email verification: ${e.toString()}'));
        }
      }
    });
  }

  /// Stop email verification polling
  Future<void> _onStopEmailVerificationPolling(StopEmailVerificationPollingEvent event, Emitter<AuthState> emit) async {
    logger.i('🛑 Stopping email verification polling');
    _emailVerificationTimer?.cancel();
  }

  /// Handle email verification completion
  Future<void> _onEmailVerificationComplete(EmailVerificationCompleteEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('✅ Email verification complete for UID: ${event.uid}');

      final draft = await secureStorage.getRegistrationDraft();
      if (draft == null) {
        emit(const AuthError('Registration data lost. Please start over.'));
        return;
      }

      emit(EmailVerified(uid: event.uid, draft: draft));

      // Automatically proceed to create Firestore user
      add(CreateFirestoreUserEvent(uid: event.uid, draft: draft));
    } catch (e) {
      logger.e('🔥 Error handling email verification: $e');
      emit(AuthError('Failed to process email verification: ${e.toString()}'));
    }
  }

  /// Resend verification email
  Future<void> _onResendVerificationEmail(ResendVerificationEmailEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('📧 Resending verification email for UID: ${event.uid}');

      final user = firebaseAuth.currentUser;
      if (user != null && user.uid == event.uid) {
        await user.sendEmailVerification();
        
        // Show success message but don't change main state
        logger.i('✅ Verification email resent');
        } else {
        emit(const AuthError('Session expired. Please start registration again.'));
      }
    } catch (e) {
      logger.e('🔥 Failed to resend verification email: $e');
      emit(AuthError('Failed to resend email: ${e.toString()}'));
    }
  }

  /// Create Firestore user document after email verification
  Future<void> _onCreateFirestoreUser(CreateFirestoreUserEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Completing registration...'));

    try {
      logger.i('📝 Completing email verification for: ${event.draft.email}');

      // Complete email verification and get user
      final result = await authRepository.completeEmailVerification(uid: event.uid);

      result.fold(
        (failure) => emit(AuthError('Failed to complete registration: ${failure.message}')),
        (user) async {
          logger.i('✅ Registration completed: ${user.id}');
          
          // Clear registration draft
          await secureStorage.clearRegistrationDraft();
          
          if (user.userType == 'fan') {
            // Fan registration complete - direct to home
            emit(FanRegistrationComplete(user));
            emit(AuthAuthenticated(user: user));
          } else {
            // Player registration complete - check payment status
            if (user.paymentStatus == false) {
              logger.i('💳 Player needs to complete payment');
              emit(PlayerPaymentRequired(
                user: user,
                paymentDeadline: user.createdAt.add(const Duration(days: 2)),
                paymentId: user.playerPaymentId ?? '',
              ));
            } else {
              // Payment already completed
              emit(PaymentCompleted(user));
              emit(AuthAuthenticated(user: user));
            }
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Failed to create Firestore user: $e');
      emit(AuthError('Failed to complete registration: ${e.toString()}'));
    }
  }

  /// Verify payment completion
  Future<void> _onVerifyPayment(VerifyPaymentEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Verifying payment...'));

    try {
      logger.i('💳 Verifying payment for user: ${event.userId}');

      // Update user payment status in Firestore
      await firebaseAuth.currentUser?.reload();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .update({
        'paymentStatus': true, // Boolean: payment completed
        'playerPaymentStatus': 'completed',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Get updated user data
      final userResult = await authRepository.getUserById(event.userId);
      
      userResult.fold(
        (failure) => emit(AuthError('Failed to verify payment: ${failure.message}')),
        (user) {
          logger.i('✅ Payment verified for user: ${user.email}');
          
          // Update local storage with new payment status
          _saveAuthTokens(user.id);
          
          emit(PaymentCompleted(user));
          
          // Automatically authenticate user after payment
          emit(AuthAuthenticated(user: user));
        },
      );
    } catch (e) {
      logger.e('🔥 Payment verification failed: $e');
      emit(AuthError('Payment verification failed: ${e.toString()}'));
    }
  }

  /// Handle login event
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Logging in...'));

    try {
      final result = await authRepository.login(
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) async {
          logger.i('✅ Login successful: ${user.email}');
          
          // Save auth tokens
          await _saveAuthTokens(user.id);
          
          // Check if player needs to complete payment
          if (user.userType == 'player' && user.paymentStatus == false) {
            logger.i('💳 Player logged in but payment is pending');
            emit(PlayerPaymentRequired(
              user: user,
              paymentDeadline: user.createdAt.add(const Duration(days: 2)),
              paymentId: user.playerPaymentId ?? '',
            ));
          } else {
            // User is fully authenticated and can access home
            emit(AuthAuthenticated(user: user));
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Login failed: $e');
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  /// Logout user
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Signing out...'));

    try {
      // Sign out from Firebase
      await firebaseAuth.signOut();
      
      // Clear all local storage
      await secureStorage.clearAll();
      
      logger.i('👋 Logout successful');
      emit(AuthUnauthenticated());
    } catch (e) {
      logger.e('🔥 Logout failed: $e');
      emit(const AuthError('Failed to log out'));
    }
  }

  /// Send password reset email
  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Sending reset email...'));

    try {
      final result = await authRepository.sendPasswordResetEmail(email: event.email);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(PasswordResetSent(event.email)),
      );
    } catch (e) {
      emit(AuthError('Failed to send reset email: ${e.toString()}'));
    }
  }

  /// Fetch communities
  Future<void> _onFetchCommunities(FetchCommunitiesEvent event, Emitter<AuthState> emit) async {
    emit(CommunitiesLoading());

    try {
      final result = await authRepository.getCommunities();

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (communities) => emit(CommunitiesLoaded(communities)),
      );
    } catch (e) {
      emit(const AuthError('Failed to load communities'));
    }
  }

  /// Clear registration draft
  Future<void> _onClearRegistrationDraft(ClearRegistrationDraftEvent event, Emitter<AuthState> emit) async {
    try {
      await secureStorage.clearRegistrationDraft();
      logger.i('🗑️ Registration draft cleared');
      emit(AuthUnauthenticated());
    } catch (e) {
      logger.e('🔥 Failed to clear registration draft: $e');
    }
  }

  /// Handle payment deadline expiry
  Future<void> _onHandlePaymentExpiry(HandlePaymentExpiryEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('⏰ Handling payment expiry for user: ${event.userId}');

      // Delete user account from Firestore and Firebase Auth
      final userToDelete = firebaseAuth.currentUser;
      if (userToDelete != null && userToDelete.uid == event.userId) {
        await userToDelete.delete();
      }

      // Clear local storage
      await secureStorage.clearAll();

      emit(const RegistrationExpired(
        email: '',
        message: 'Your registration has expired due to incomplete payment. Please register again.',
      ));
    } catch (e) {
      logger.e('🔥 Failed to handle payment expiry: $e');
      emit(const AuthError('Session expired. Please register again.'));
    }
  }

  /// Refresh authentication tokens
  Future<void> _onRefreshTokens(RefreshTokensEvent event, Emitter<AuthState> emit) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await _saveAuthTokens(user.uid);
        logger.i('🔄 Tokens refreshed');
      }
    } catch (e) {
      logger.e('🔥 Token refresh failed: $e');
    }
  }

  /// Save authentication tokens to secure storage
  Future<void> _saveAuthTokens(String uid) async {
    try {
      // Get Firebase ID token
      final user = firebaseAuth.currentUser;
      if (user != null && user.uid == uid) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          // Store tokens in secure storage
          final tokens = AuthTokens(
            accessToken: idToken,
            refreshToken: '', // Firebase handles refresh internally
            uid: uid,
            expiresAt: DateTime.now().add(const Duration(days: 150)),
          );
          
          await secureStorage.saveAuthTokens(tokens);
          logger.i('🔐 Authentication tokens saved');
        }
      }
    } catch (e) {
      logger.e('🔥 Failed to save auth tokens: $e');
    }
  }
}