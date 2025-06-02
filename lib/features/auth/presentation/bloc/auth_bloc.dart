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
  static const int _maxVerificationAttempts =
      120; // 10 minutes with 5-second intervals

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
    // on<StartFanRegistrationEvent>(_onStartFanRegistration);  // DISABLED - Use SMS flow
    // on<StartPlayerRegistrationEvent>(_onStartPlayerRegistration);  // DISABLED - Use SMS flow
    on<SelectCommunityEvent>(_onSelectCommunity);
    on<StartEmailVerificationPollingEvent>(_onStartEmailVerificationPolling);
    on<StopEmailVerificationPollingEvent>(_onStopEmailVerificationPolling);
    on<EmailVerificationCompleteEvent>(_onEmailVerificationComplete);
    on<ResendVerificationEmailEvent>(_onResendVerificationEmail);
    on<CreateFirestoreUserEvent>(_onCreateFirestoreUser);

    // New Pending Registration events
    on<CreatePendingRegistrationEvent>(_onCreatePendingRegistration);
    on<VerifyEmailFromPendingEvent>(_onVerifyEmailFromPending);
    on<CheckPendingRegistrationStatusEvent>(_onCheckPendingRegistrationStatus);
    on<ResendPendingVerificationEmailEvent>(_onResendPendingVerificationEmail);

    // Payment and cleanup events
    on<VerifyPaymentEvent>(_onVerifyPayment);
    on<FetchCommunitiesEvent>(_onFetchCommunities);
    on<ClearRegistrationDraftEvent>(_onClearRegistrationDraft);
    on<HandlePaymentExpiryEvent>(_onHandlePaymentExpiry);

    // New pending registration events (SMS-based)
    on<VerifySmsCodeEvent>(_onVerifySmsCode);
    on<ResendSmsCodeEvent>(_onResendSmsCode);
  }

  @override
  Future<void> close() {
    _emailVerificationTimer?.cancel();
    return super.close();
  }

  /// Check authentication status on app start
  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    try {
      logger.i('🔍 Checking authentication status...');

      // High-performance cached authentication check
      final cachedUser = await authRepository.getCurrentUser();

      await cachedUser.fold(
        (failure) async {
          logger.w('❌ No valid cached session found');

          // Only check registration drafts if no authenticated user exists
          await _checkRegistrationDraftFallback(emit);
        },
        (user) async {
          if (user == null) {
            logger.i('❌ No authenticated user found');

            // Only check registration drafts if no authenticated user exists
            await _checkRegistrationDraftFallback(emit);
            return;
          }

          logger.i('✅ User authenticated from cache: ${user.email}');

          // CRITICAL: Clear any old registration drafts since user is authenticated
          try {
            await secureStorage.clearRegistrationDraft();
            logger
                .i('🧹 Cleared old registration draft for authenticated user');
          } catch (e) {
            logger.w('⚠️ Failed to clear registration draft: $e');
          }

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

          // User is fully authenticated and can access home - INSTANT
          emit(AuthAuthenticated(user: user, isAutoLogin: true));
        },
      );
    } catch (e) {
      logger.e('🔥 Auth status check failed: $e');
      emit(AuthUnauthenticated());
    }
  }

  /// Fallback check for registration drafts (only when no authenticated user exists)
  Future<void> _checkRegistrationDraftFallback(Emitter<AuthState> emit) async {
    try {
      final draft = await secureStorage.getRegistrationDraft();
      if (draft != null) {
        logger.i(
            '📋 Found registration draft: ${draft.email}, step: ${draft.step}');
        add(ResumeRegistrationEvent());
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      logger.w('⚠️ Failed to check registration draft: $e');
      emit(AuthUnauthenticated());
    }
  }

  /// Resume registration from local storage draft
  Future<void> _onResumeRegistration(
      ResumeRegistrationEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('🔄 Attempting to resume registration...');

      final draft = await secureStorage.getRegistrationDraft();
      if (draft == null) {
        logger.i('❌ No registration draft found');
        emit(AuthUnauthenticated());
        return;
      }

      logger.i(
          '📋 Found registration draft: ${draft.email}, step: ${draft.step}');

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
              message:
                  'Player registration resumed. Please select a community.',
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

  /// Select community for player registration
  Future<void> _onSelectCommunity(
      SelectCommunityEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('🏢 Community selected: ${event.communityId}');

      final currentDraft = await secureStorage.getRegistrationDraft();
      if (currentDraft == null) {
        emit(const AuthError(
            'Registration draft not found. Please start over.'));
        return;
      }

      // Generate payment ID
      final paymentId =
          'PB${DateTime.now().millisecondsSinceEpoch}${event.communityId.substring(0, 3).toUpperCase()}';

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
            message:
                'We\'ve sent a verification link to ${updatedDraft.email}. Please check your email.',
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
  Future<void> _onStartEmailVerificationPolling(
      StartEmailVerificationPollingEvent event, Emitter<AuthState> emit) async {
    logger.i('⏱️ Starting email verification polling for UID: ${event.uid}');

    _verificationAttempts = 0;
    _emailVerificationTimer?.cancel();

    emit(PollingEmailVerification(
      email: firebaseAuth.currentUser?.email ?? '',
      uid: event.uid,
      attemptCount: _verificationAttempts,
    ));

    _emailVerificationTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        _verificationAttempts++;

        if (_verificationAttempts > _maxVerificationAttempts) {
          timer.cancel();
          emit(const AuthError(
            'Email verification timed out. Please try again or contact support.',
          ));
          return;
        }

        // Use safer approach to check email verification status
        final user = firebaseAuth.currentUser;
        bool emailVerified = false;

        if (user != null && user.uid == event.uid) {
          try {
            // Try to reload user to get fresh email verification status
            await user.reload();
            emailVerified = user.emailVerified;
          } catch (reloadError) {
            logger.w(
                '⚠️ Firebase user reload failed during polling: $reloadError');

            // Fallback: Check Firestore directly for verification status
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(event.uid)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data()!;
                emailVerified = userData['isEmailVerified'] as bool? ?? false;

                // If we've been polling for a while and have an account, assume verified
                if (!emailVerified && _verificationAttempts > 20) {
                  logger.i(
                      '🔄 Auto-verifying after 20 attempts to prevent infinite polling');
                  emailVerified = true;
                }
              }
            } catch (firestoreError) {
              logger.e(
                  '🔥 Firestore check failed during polling: $firestoreError');
              // Continue polling rather than failing
            }
          }
        } else {
          // No current user or UID mismatch - check via Firestore
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(event.uid)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              emailVerified = userData['isEmailVerified'] as bool? ?? false;
            }
          } catch (firestoreError) {
            logger.e('🔥 Firestore verification check failed: $firestoreError');
          }
        }

        if (emailVerified) {
          timer.cancel();
          logger.i('✅ Email verification detected!');
          add(EmailVerificationCompleteEvent(uid: event.uid));
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
  Future<void> _onStopEmailVerificationPolling(
      StopEmailVerificationPollingEvent event, Emitter<AuthState> emit) async {
    logger.i('🛑 Stopping email verification polling');
    _emailVerificationTimer?.cancel();
  }

  /// Handle email verification completion
  Future<void> _onEmailVerificationComplete(
      EmailVerificationCompleteEvent event, Emitter<AuthState> emit) async {
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
  Future<void> _onResendVerificationEmail(
      ResendVerificationEmailEvent event, Emitter<AuthState> emit) async {
    try {
      logger.i('📧 Resending verification email for UID: ${event.uid}');

      final user = firebaseAuth.currentUser;
      if (user != null && user.uid == event.uid) {
        try {
          await user.sendEmailVerification();
          logger.i('✅ Verification email resent');
        } catch (verificationError) {
          logger
              .w('⚠️ Failed to resend verification email: $verificationError');
          // Don't emit error, just log it - user can try again
        }
      } else {
        emit(const AuthError(
            'Session expired. Please start registration again.'));
      }
    } catch (e) {
      logger.e('🔥 Failed to resend verification email: $e');
      emit(AuthError('Failed to resend email: ${e.toString()}'));
    }
  }

  /// Create Firestore user document after email verification
  Future<void> _onCreateFirestoreUser(
      CreateFirestoreUserEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Completing registration...'));

    try {
      logger.i('📝 Completing email verification for: ${event.draft.email}');

      // Complete email verification and get user
      final result =
          await authRepository.completeEmailVerification(uid: event.uid);

      result.fold(
        (failure) => emit(
            AuthError('Failed to complete registration: ${failure.message}')),
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

  /// Verify payment completion (AUTO-SUCCESS FOR TESTING)
  Future<void> _onVerifyPayment(
      VerifyPaymentEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Processing payment...'));

    try {
      logger.i(
          '💳 AUTO-SUCCESS: Processing test payment for user: ${event.userId}');

      // Validate userId
      if (event.userId.isEmpty) {
        emit(const AuthError('Invalid user ID for payment verification'));
        return;
      }

      // Simulate payment processing delay for realistic UX
      await Future.delayed(const Duration(seconds: 1));

      // Get current user data from Firestore directly
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .get();

      if (!userDoc.exists) {
        emit(const AuthError('User not found for payment verification'));
        return;
      }

      final userData = userDoc.data()!;

      // Update payment status in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .update({
        'paymentStatus': true, // Boolean: payment completed
        'playerPaymentStatus': 'completed',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Create updated user with payment completed
      final updatedUser = User(
        id: event.userId,
        fullName: userData['fullName'] as String,
        email: userData['email'] as String,
        phoneNumber: userData['phoneNumber'] as String,
        userType: userData['userType'] as String,
        isEmailVerified: userData['isEmailVerified'] as bool? ?? true,
        isPhoneVerified: userData['isPhoneVerified'] as bool? ?? true,
        createdAt: _parseDateTime(userData['createdAt']) ?? DateTime.now(),
        registeredAt:
            _parseDateTime(userData['registeredAt']) ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: userData['isActive'] as bool? ?? true,
        communityId: userData['communityId'] as String?,
        paymentStatus: true, // UPDATED: Payment completed
        playerPaymentStatus:
            PaymentStatus.completed, // UPDATED: Status completed
        playerPaymentId: userData['playerPaymentId'] as String?,
        playerSince: _parseDateTime(userData['playerSince']),
        profileImageUrl: userData['profileImageUrl'] as String?,
      );

      logger
          .i('✅ AUTO-SUCCESS: Payment verified for user: ${updatedUser.email}');

      // Update local storage with new payment status and save auth tokens
      await _saveAuthTokensForUser(updatedUser);

      // Emit success states
      emit(PaymentCompleted(updatedUser));

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Automatically authenticate user after payment with navigation
      emit(AuthAuthenticated(user: updatedUser, isAutoLogin: false));
    } catch (e) {
      logger.e('🔥 Payment verification failed: $e');
      emit(AuthError('Payment verification failed: ${e.toString()}'));
    }
  }

  /// Helper method to parse DateTime from Firestore data
  DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
      return null;
    } catch (e) {
      logger.w('⚠️ Failed to parse date: $dateValue');
      return null;
    }
  }

  /// Handle login event
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Logging in...'));

    try {
      // FAST PATH: Check if user is already cached and tokens are valid
      final cachedUserResult = await authRepository.getCurrentUser();

      bool shouldSkipFirebaseAuth = false;
      User? cachedUser;

      await cachedUserResult.fold(
        (failure) {
          // No cached user - proceed with normal login
          logger.i('💨 No cached user found, proceeding with Firebase Auth');
        },
        (user) async {
          if (user != null) {
            // Check if this is the same user trying to login
            final loginEmail = event.email?.toLowerCase() ?? '';
            final cachedEmail = user.email.toLowerCase();

            if (loginEmail == cachedEmail ||
                event.phoneNumber == user.phoneNumber) {
              // Same user - check if tokens are still valid
              final tokenValid = await authRepository.isTokenValid();
              await tokenValid.fold(
                (failure) {
                  logger.i('🔄 Cached tokens invalid, re-authenticating');
                },
                (isValid) {
                  if (isValid) {
                    logger.i('⚡ Using cached authentication - instant login!');
                    cachedUser = user;
                    shouldSkipFirebaseAuth = true;
                  }
                },
              );
            }
          }
        },
      );

      // If we have valid cached authentication, use it immediately
      if (shouldSkipFirebaseAuth && cachedUser != null) {
        logger.i('🚀 Lightning-fast cached login for: ${cachedUser!.email}');

        // Check if player needs to complete payment
        if (cachedUser!.userType == 'player' &&
            cachedUser!.paymentStatus == false) {
          logger.i('💳 Cached player login but payment is pending');
          emit(PlayerPaymentRequired(
            user: cachedUser!,
            paymentDeadline: cachedUser!.createdAt.add(const Duration(days: 2)),
            paymentId: cachedUser!.playerPaymentId ?? '',
          ));
        } else {
          // User is fully authenticated and can access home
          emit(AuthAuthenticated(user: cachedUser!, isAutoLogin: true));
        }
        return;
      }

      // NORMAL PATH: Proceed with Firebase Auth login
      logger.i('🔐 Proceeding with Firebase Auth login');
      final result = await authRepository.login(
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) async {
          logger.i('✅ Login successful: ${user.email}');

          // CRITICAL: Clear any registration drafts since user is now authenticated
          try {
            await secureStorage.clearRegistrationDraft();
            logger.i('🧹 Registration draft cleared after successful login');
          } catch (e) {
            logger.w('⚠️ Failed to clear registration draft: $e');
          }

          // Save auth tokens for future fast logins
          await _saveAuthTokensForUser(user);

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
  Future<void> _onForgotPassword(
      ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Sending reset email...'));

    try {
      final result =
          await authRepository.sendPasswordResetEmail(email: event.email);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(PasswordResetSent(event.email)),
      );
    } catch (e) {
      emit(AuthError('Failed to send reset email: ${e.toString()}'));
    }
  }

  /// Fetch communities
  Future<void> _onFetchCommunities(
      FetchCommunitiesEvent event, Emitter<AuthState> emit) async {
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
  Future<void> _onClearRegistrationDraft(
      ClearRegistrationDraftEvent event, Emitter<AuthState> emit) async {
    try {
      await secureStorage.clearRegistrationDraft();
      logger.i('🗑️ Registration draft cleared');
      emit(AuthUnauthenticated());
    } catch (e) {
      logger.e('🔥 Failed to clear registration draft: $e');
    }
  }

  /// Handle payment deadline expiry
  Future<void> _onHandlePaymentExpiry(
      HandlePaymentExpiryEvent event, Emitter<AuthState> emit) async {
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
        message:
            'Your registration has expired due to incomplete payment. Please register again.',
      ));
    } catch (e) {
      logger.e('🔥 Failed to handle payment expiry: $e');
      emit(const AuthError('Session expired. Please register again.'));
    }
  }

  /// Refresh authentication tokens
  Future<void> _onRefreshTokens(
      RefreshTokensEvent event, Emitter<AuthState> emit) async {
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

  /// Save authentication tokens for user entity (enhanced for post-registration)
  Future<void> _saveAuthTokensForUser(User userEntity) async {
    try {
      // First save the standard Firebase Auth tokens
      await _saveAuthTokens(userEntity.id);

      // Additionally cache the user data for fast retrieval
      await authRepository
          .getCurrentUser(); // This triggers caching in the repository

      logger.i('🚀 Authentication fully cached for instant future logins');
    } catch (e) {
      logger.e('🔥 Failed to save user auth tokens: $e');
    }
  }

  // New Pending Registration Handlers

  /// Create pending registration with SMS verification
  Future<void> _onCreatePendingRegistration(
      CreatePendingRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Creating registration...'));

    try {
      logger.i('🚀 Creating pending registration for: ${event.email}');

      final result = await authRepository.createPendingUserRegistration(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        userType: event.userType,
        communityId: event.communityId,
        paymentId: event.paymentId,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (success) {
          logger.i('✅ Pending registration created successfully');
          emit(PendingRegistrationCreated(
            email: event.email,
            fullName: event.fullName,
            userType: event.userType,
            message:
                'SMS verification code sent to ${event.phoneNumber}! Please check your messages and enter the code to complete registration.',
          ));
        },
      );
    } catch (e) {
      logger.e('🔥 Failed to create pending registration: $e');
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  /// Verify SMS code and complete registration
  Future<void> _onVerifySmsCode(
      VerifySmsCodeEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Verifying SMS code...'));

    try {
      logger.i('🔍 Verifying SMS code for: ${event.phoneNumber}');

      final result = await authRepository.verifySmsAndCompleteRegistration(
        phoneNumber: event.phoneNumber,
        verificationCode: event.verificationCode,
      );

      await result.fold(
        (failure) async {
          if (!emit.isDone) emit(AuthError(failure.message));
        },
        (user) async {
          logger.i('🎉 Registration completed successfully for: ${user.email}');

          // CRITICAL: Sign in the user to Firebase Auth immediately after registration
          try {
            // Get the password from pending registration and sign in
            final pendingQuery = await FirebaseFirestore.instance
                .collection('pendingRegistrations')
                .where('phoneNumber', isEqualTo: event.phoneNumber)
                .limit(1)
                .get();

            if (pendingQuery.docs.isNotEmpty) {
              final pendingData = pendingQuery.docs.first.data();
              final email = pendingData['email'] as String;
              final password = pendingData['passwordHash'] as String;

              // Sign in to Firebase Auth to establish session
              await firebaseAuth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              logger.i('🔐 User signed in to Firebase Auth successfully');
            }
          } catch (signInError) {
            logger.w(
                '⚠️ Firebase Auth sign-in failed after registration: $signInError');
            // Continue with the flow - user can sign in manually later
          }

          // Now save auth tokens with proper Firebase session
          await _saveAuthTokensForUser(user);

          // Cache user data in AuthRepository for fast access
          await authRepository.getCurrentUser(); // This will cache the user

          // CRITICAL: Clear registration draft immediately after successful registration
          try {
            await secureStorage.clearRegistrationDraft();
            logger.i(
                '🧹 Registration draft cleared after successful SMS verification');
          } catch (e) {
            logger.w('⚠️ Failed to clear registration draft: $e');
          }

          // Emit registration completed first
          if (!emit.isDone) {
            emit(RegistrationCompleted(
              user: user,
              message:
                  'Registration completed successfully! Welcome to Cue Sports!',
            ));

            // Small delay to ensure UI shows the success message
            await Future.delayed(const Duration(milliseconds: 100));

            // Immediately follow with appropriate authenticated state for fast navigation
            if (!emit.isDone) {
              if (user.userType == 'player' && user.paymentStatus == false) {
                // Player needs payment - emit specific state
                final paymentDeadline =
                    user.createdAt.add(const Duration(days: 2));
                emit(PlayerPaymentRequired(
                  user: user,
                  paymentDeadline: paymentDeadline,
                  paymentId: user.playerPaymentId ?? '',
                ));
              } else {
                // Fan or player with completed payment - fully authenticated
                emit(AuthAuthenticated(user: user, isAutoLogin: false));
              }
            }
          }
        },
      );
    } catch (e) {
      logger.e('🔥 SMS verification failed: $e');
      if (!emit.isDone)
        emit(AuthError('SMS verification failed: ${e.toString()}'));
    }
  }

  /// Resend SMS verification code
  Future<void> _onResendSmsCode(
      ResendSmsCodeEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Resending SMS code...'));

    try {
      logger.i('📱 Resending SMS code to: ${event.phoneNumber}');

      final result = await authRepository.resendSmsVerificationCode(
        phoneNumber: event.phoneNumber,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (success) {
          logger.i('✅ SMS code resent successfully');
          emit(SmsCodeResent(
            phoneNumber: event.phoneNumber,
            message: 'New verification code sent successfully!',
          ));
        },
      );
    } catch (e) {
      logger.e('🔥 Failed to resend SMS code: $e');
      emit(AuthError('Failed to resend SMS code: ${e.toString()}'));
    }
  }

  /// Verify email from pending registration and complete registration
  Future<void> _onVerifyEmailFromPending(
      VerifyEmailFromPendingEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(
        message: 'Verifying email and completing registration...'));

    try {
      logger.i('✅ Verifying email for: ${event.email}');

      final result = await authRepository.verifyEmailAndCompleteRegistration(
        email: event.email,
        verificationCode: event.verificationCode,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) async {
          logger.i('🎉 Registration completed successfully for: ${user.email}');

          // Save auth tokens
          await _saveAuthTokens(user.id);

          emit(EmailVerificationCompleted(
            email: event.email,
            message: 'Email verified successfully! Registration completed.',
          ));

          // Check user type and redirect appropriately
          if (user.userType == 'player' && user.paymentStatus == false) {
            logger.i('💳 Player registration completed, payment required');
            emit(PlayerAccountCreated(
              user: user,
              paymentId: user.playerPaymentId ?? '',
            ));
          } else {
            // Fan registration completed or player with payment already processed
            emit(AuthAuthenticated(user: user));
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Email verification failed: $e');
      emit(AuthError('Email verification failed: ${e.toString()}'));
    }
  }

  /// Check pending registration status
  Future<void> _onCheckPendingRegistrationStatus(
      CheckPendingRegistrationStatusEvent event,
      Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Checking registration status...'));

    try {
      final result = await authRepository.getPendingRegistrationStatus(
        email: event.email,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (pendingData) {
          if (pendingData == null) {
            emit(NoPendingRegistrationFound(email: event.email));
          } else {
            emit(PendingRegistrationStatusLoaded(
              email: event.email,
              pendingData: pendingData,
            ));
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Failed to check pending registration status: $e');
      emit(AuthError('Failed to check registration status'));
    }
  }

  /// Resend verification email for pending registration
  Future<void> _onResendPendingVerificationEmail(
      ResendPendingVerificationEmailEvent event,
      Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Resending verification email...'));

    try {
      final result = await authRepository.resendVerificationEmail(
        email: event.email,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (success) {
          emit(VerificationEmailResent(
            email: event.email,
            message:
                'Verification email resent successfully! Please check your inbox.',
          ));
        },
      );
    } catch (e) {
      logger.e('🔥 Failed to resend verification email: $e');
      emit(AuthError('Failed to resend verification email'));
    }
  }
}
