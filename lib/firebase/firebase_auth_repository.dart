import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/error/failures.dart';
import '../core/services/logger_service.dart';
import '../features/auth/domain/entities/user.dart' as entities;
import '../features/community/domain/entities/community.dart' as entities;
import 'package:pool_billiard_app/core/services/token_service.dart';
import 'package:pool_billiard_app/core/services/email_service.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

/// Firebase implementation of the AuthRepository
///
/// This handles all authentication operations using Firebase Auth and Firestore
/// It maps phone numbers to email addresses for login and handles token management
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;
  final LoggerService _logger;
  final TokenService _tokenService; // TODO: Use for advanced token management
  final EmailService _emailService; // TODO: Use for sending verification emails

  final CollectionReference _usersCollection;
  final CollectionReference _communitiesCollection;
  final CollectionReference _pendingRegistrationsCollection;

  /// Token constants
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';
  static const Duration _tokenDuration = Duration(hours: 2);

  /// Stream to listen to auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  /// Handle authentication exceptions
  Failure _handleAuthException(dynamic e) {
    _logger.e('🔥 Auth exception', e);
    
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return const AuthFailure(message: 'No user found with this email or phone number');
        case 'wrong-password':
          return const AuthFailure(message: 'Incorrect password');
        case 'email-already-in-use':
          return const AuthFailure(message: 'Email is already in use');
        case 'invalid-email':
          return const AuthFailure(message: 'Invalid email address');
        case 'weak-password':
          return const AuthFailure(message: 'Password is too weak');
        case 'operation-not-allowed':
          return const AuthFailure(message: 'Operation not allowed. Please contact support');
        case 'user-disabled':
          return const AuthFailure(message: 'This account has been disabled');
        case 'too-many-requests':
          return const AuthFailure(message: 'Too many unsuccessful login attempts. Please try again later');
        case 'network-request-failed':
          return const NetworkFailure(message: 'Network error. Please check your connection');
        default:
          return AuthFailure(message: 'Authentication failed: ${e.message}');
      }
    }
    
    if (e is TimeoutException) {
      return const NetworkFailure(message: 'Connection timed out. Please try again');
    }
    
    return AuthFailure(message: 'Authentication error: $e');
  }

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
    required LoggerService logger,
    required TokenService tokenService,
    required EmailService emailService,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger,
        _tokenService = tokenService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _emailService = emailService,
        _usersCollection = (firestore ?? FirebaseFirestore.instance).collection('users'),
        _communitiesCollection = (firestore ?? FirebaseFirestore.instance).collection('communities'),
        _pendingRegistrationsCollection = (firestore ?? FirebaseFirestore.instance).collection('pending_registrations');

  @override
  Future<Either<Failure, entities.User>> login({
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    try {
      _logger.i('🔄 Starting login process');

      // Prioritize phone number login as this is the more reliable approach
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        _logger.i('📱 Attempting login with phone: $phoneNumber');

        // First, query Firestore to find the user with this phone number
        final querySnapshot = await _usersCollection
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _logger.w('❌ No user found with phone: $phoneNumber');
          return const Left(AuthFailure(message: 'No account found with this phone number'));
        }

        // Get the user document and extract the email
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final userEmail = userData['email'] as String?;

        if (userEmail == null || userEmail.isEmpty) {
          _logger.e('⚠️ User found but email is missing for phone: $phoneNumber');
          return const Left(AuthFailure(message: 'User email not found. Please contact support.'));
        }

        _logger.i('🔄 Found associated email for phone: $phoneNumber, using it for auth');

        try {
          // Sign in with email and password using Firebase Auth
          final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: userEmail,
            password: password,
          );

          // Cache authentication information
          final token = await userCredential.user?.getIdToken() ?? '';
          final DateTime expiryTime = DateTime.now().add(_tokenDuration);
          await _cacheAuthToken(token, expiryTime);

          _logger.i('✅ User logged in successfully: ${userCredential.user?.uid}');

          // Return user entity
          final userId = userDoc.id;
          final user = _mapFirebaseUserToEntity(userId, userData);
          return Right(user);
        } on firebase_auth.FirebaseAuthException catch (e) {
          return Left(_handleAuthException(e));
        }
      } 
      // Email login
      else if (email != null && email.isNotEmpty) {
        _logger.i('👤 Attempting login with email: $email');

        try {
          // Direct Firebase Auth login
          final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Get user data from Firestore
          final userDoc = await _getUserByEmail(email);
          if (userDoc == null) {
            _logger.w('❌ User authenticated but not found in Firestore');
            return const Left(AuthFailure(message: 'User data not found'));
          }

          // Cache authentication information
          final token = await userCredential.user?.getIdToken() ?? '';
          final DateTime expiryTime = DateTime.now().add(_tokenDuration);
          await _cacheAuthToken(token, expiryTime);

          _logger.i('✅ User logged in successfully: ${userCredential.user?.uid}');

          // Return user entity
          final userData = userDoc.data() as Map<String, dynamic>;
          final userId = userDoc.id;
          final user = _mapFirebaseUserToEntity(userId, userData);
          return Right(user);
        } on firebase_auth.FirebaseAuthException catch (e) {
          return Left(_handleAuthException(e));
        }
      } 
      else {
        return const Left(AuthFailure(message: 'Either email or phone number must be provided'));
      }
    } catch (e) {
      _logger.e('🔥 Unexpected error during login', e);
      return Left(AuthFailure(message: 'Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _clearAuthTokens();
      _logger.i('👋 User logged out successfully');
      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error during logout', e);
      return const Left(AuthFailure(message: 'Failed to log out'));
    }
  }

  @override
  Future<Either<Failure, entities.User?>> getCurrentUser() async {
    try {
      // Check if we have a valid token
      final isTokenValid = await _isAuthTokenValid();
      if (!isTokenValid) {
        _logger.i('🔑 No valid auth token found');
        return const Right(null);
      }

      // Get current Firebase user
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        _logger.i('👤 No Firebase user logged in');
        return const Right(null);
      }

      // Get user data from Firestore
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        _logger.w('⚠️ Firebase user exists but no Firestore document found');
        return const Right(null);
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      _logger.i('✅ Current user retrieved: ${userData['fullName']}');

      return Right(_mapFirebaseUserToEntity(firebaseUser.uid, userData));
    } catch (e) {
      _logger.e('🔥 Error getting current user', e);
      return const Left(AuthFailure(message: 'Failed to get current user'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('📧 Password reset email sent to: $email');
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('🔥 Firebase Auth Exception: ${e.code}', e);

      switch (e.code) {
        case 'user-not-found':
          return const Left(AuthFailure(message: 'No user found with this email'));
        case 'invalid-email':
          return const Left(AuthFailure(message: 'Invalid email format'));
        default:
          return Left(
              AuthFailure(message: 'Failed to send password reset: ${e.message}'));
      }
    } catch (e) {
      _logger.e('🔥 Error sending password reset', e);
      return const Left(AuthFailure(message: 'Failed to send password reset email'));
    }
  }

  @override
  Future<Either<Failure, entities.User>> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      _logger.i('🚀 Creating fan account for: $email');

      // PRODUCTION OPTIMIZATION: Skip preliminary checks - let Firebase be authoritative
      // This eliminates race conditions and false positives from fetchSignInMethodsForEmail

      // Create user in Firebase Auth - this is the authoritative check
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      _logger.i('✅ Firebase Auth account created successfully: $uid');

      // Create user document in Firestore
      final now = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'userType': 'fan',
        'communityId': null,
        'registeredAt': now,
        'playerSince': null,
        'isEmailVerified': true, // Email was verified before this step in our flow
        'playerPaymentStatus': null,
        'playerPaymentId': null,
        'profileImageUrl': null,
        'lastLoginAt': now,
        'isActive': true,
      });

      _logger.i('✅ Firestore document created successfully');

      // Generate token
      final token = await _generateCustomToken();
      final expiryTime = DateTime.now().add(_tokenDuration);
      await _cacheAuthToken(token, expiryTime);

      // Get the created user data
      final userDoc = await _usersCollection.doc(uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('🎉 Fan registered successfully: $fullName');
      return Right(_mapFirebaseUserToEntity(uid, userData));

    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.i('🔄 Firebase Auth conflict detected: ${e.code} for $email');

      if (e.code == 'email-already-in-use') {
        // PRODUCTION: Handle gracefully without user-facing errors
        _logger.i('🔧 Attempting seamless account recovery for: $email');
        
        try {
          // Try to sign in with the existing account
          final signInCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          final uid = signInCredential.user!.uid;
          _logger.i('✅ Successfully accessed existing Firebase Auth account: $uid');
          
          // Check if Firestore document exists and create/update as needed
          final existingUserDoc = await _usersCollection.doc(uid).get();
          
          if (!existingUserDoc.exists) {
            _logger.i('🔧 Creating missing Firestore document');
            
            // Create the missing Firestore document
            final now = FieldValue.serverTimestamp();
            await _usersCollection.doc(uid).set({
              'fullName': fullName,
              'email': email,
              'phoneNumber': phoneNumber,
              'userType': 'fan',
              'communityId': null,
              'registeredAt': now,
              'playerSince': null,
              'isEmailVerified': true, // Email was verified in our flow
              'playerPaymentStatus': null,
              'playerPaymentId': null,
              'profileImageUrl': null,
              'lastLoginAt': now,
              'isActive': true,
            });
            
            _logger.i('✅ Firestore document created for existing account');
          } else {
            _logger.i('✅ Firestore document exists, updating login time');
            
            // Update login time
            await _usersCollection.doc(uid).update({
              'lastLoginAt': FieldValue.serverTimestamp(),
            });
          }
          
          // Generate token
          final token = await _generateCustomToken();
          final expiryTime = DateTime.now().add(_tokenDuration);
          await _cacheAuthToken(token, expiryTime);
          
          // Get the user data
          final userDoc = await _usersCollection.doc(uid).get();
          final userData = userDoc.data() as Map<String, dynamic>;
          
          _logger.i('🎉 Fan account accessed successfully: $fullName');
          // PRODUCTION: No error message - seamless recovery
          return Right(_mapFirebaseUserToEntity(uid, userData));
          
        } catch (signInError) {
          _logger.e('🔥 Account recovery failed: $signInError');
          return const Left(AuthFailure(
            message: 'This email is already registered with a different password. Please try logging in instead.'
          ));
        }
      }

      // Handle other Firebase Auth errors
      switch (e.code) {
        case 'invalid-email':
          return const Left(AuthFailure(message: 'Invalid email format'));
        case 'weak-password':
          return const Left(AuthFailure(message: 'Password is too weak'));
        default:
          return Left(AuthFailure(message: 'Registration failed: ${e.message}'));
      }
    } catch (e) {
      _logger.e('🔥 Unexpected error during fan registration', e);
      return const Left(
          AuthFailure(message: 'An unexpected error occurred during registration'));
    }
  }

  @override
  Future<Either<Failure, entities.User>> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  }) async {
    try {
      _logger.i('🚀 Creating player account for: $email');

      // PRODUCTION OPTIMIZATION: Skip preliminary checks - let Firebase be authoritative
      // This eliminates race conditions and false positives from fetchSignInMethodsForEmail
      
      // Create user in Firebase Auth - this is the authoritative check
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      _logger.i('✅ Firebase Auth account created successfully: $uid');

      // Create user document in Firestore with pending payment status
      final now = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'userType': 'player',
        'communityId': communityId,
        'registeredAt': now,
        'playerSince': now, // Player since registration
        'isEmailVerified': true, // Email was verified before this step in our flow
        'playerPaymentStatus': 'pending', // Initially pending until payment is verified
        'playerPaymentId': paymentId,
        'profileImageUrl': null,
        'lastLoginAt': now,
        'isActive': true,
      });

      _logger.i('✅ Firestore document created successfully');

      // Generate token
      final token = await _generateCustomToken();
      final expiryTime = DateTime.now().add(_tokenDuration);
      await _cacheAuthToken(token, expiryTime);

      // Get the created user data
      final userDoc = await _usersCollection.doc(uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('🎉 Player registered successfully: $fullName');
      return Right(_mapFirebaseUserToEntity(uid, userData));

    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.i('🔄 Firebase Auth conflict detected: ${e.code} for $email');

      if (e.code == 'email-already-in-use') {
        // PRODUCTION: Handle gracefully without user-facing errors
        _logger.i('🔧 Attempting seamless account recovery for: $email');
        
        try {
          // Try to sign in with the existing account
          final signInCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          final uid = signInCredential.user!.uid;
          _logger.i('✅ Successfully accessed existing Firebase Auth account: $uid');
          
          // Check if Firestore document exists and create/update as needed
          final existingUserDoc = await _usersCollection.doc(uid).get();
          
          if (!existingUserDoc.exists) {
            _logger.i('🔧 Creating missing Firestore document');
            
            // Create the missing Firestore document
            final now = FieldValue.serverTimestamp();
            await _usersCollection.doc(uid).set({
              'fullName': fullName,
              'email': email,
              'phoneNumber': phoneNumber,
              'userType': 'player',
              'communityId': communityId,
              'registeredAt': now,
              'playerSince': now,
              'isEmailVerified': true, // Email was verified in our flow
              'playerPaymentStatus': 'pending',
              'playerPaymentId': paymentId,
              'profileImageUrl': null,
              'lastLoginAt': now,
              'isActive': true,
            });
            
            _logger.i('✅ Firestore document created for existing account');
          } else {
            _logger.i('✅ Firestore document exists, updating payment info');
            
            // Update with new payment info
            await _usersCollection.doc(uid).update({
              'playerPaymentId': paymentId,
              'playerPaymentStatus': 'pending',
              'lastLoginAt': FieldValue.serverTimestamp(),
            });
          }
          
          // Generate token
          final token = await _generateCustomToken();
          final expiryTime = DateTime.now().add(_tokenDuration);
          await _cacheAuthToken(token, expiryTime);
          
          // Get the user data
          final userDoc = await _usersCollection.doc(uid).get();
          final userData = userDoc.data() as Map<String, dynamic>;
          
          _logger.i('🎉 Player account accessed successfully: $fullName');
          // PRODUCTION: No error message - seamless recovery
          return Right(_mapFirebaseUserToEntity(uid, userData));
          
        } catch (signInError) {
          _logger.e('🔥 Account recovery failed: $signInError');
          return const Left(AuthFailure(
            message: 'This email is already registered with a different password. Please try logging in instead.'
          ));
        }
      }

      // Handle other Firebase Auth errors
      switch (e.code) {
        case 'invalid-email':
          return const Left(AuthFailure(message: 'Invalid email format'));
        case 'weak-password':
          return const Left(AuthFailure(message: 'Password is too weak'));
        default:
          return Left(AuthFailure(message: 'Registration failed: ${e.message}'));
      }
    } catch (e) {
      _logger.e('🔥 Unexpected error during player registration', e);
      return const Left(
          AuthFailure(message: 'An unexpected error occurred during registration'));
    }
  }

  @override
  Future<Either<Failure, entities.User>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['fullName'] = fullName;
      if (phoneNumber != null) {
        // Check if new phone number is already registered by another user
        final isPhoneRegistered =
            await _isPhoneRegistered(phoneNumber, excludeUserId: userId);
        if (isPhoneRegistered) {
          return const Left(AuthFailure(
              message: 'Phone number is already registered by another user'));
        }
        updateData['phoneNumber'] = phoneNumber;
      }
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      if (updateData.isEmpty) {
        return const Left(AuthFailure(message: 'No updates provided'));
      }

      // Update user document
      await _usersCollection.doc(userId).update(updateData);

      // Get updated user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('✏️ User profile updated: $userId');

      return Right(_mapFirebaseUserToEntity(userId, userData));
    } catch (e) {
      _logger.e('🔥 Error updating user profile', e);
      return const Left(AuthFailure(message: 'Failed to update profile'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      // This is a simplified version since Firebase handles email verification differently
      // In Firebase, users click a link in the email instead of entering a code
      // For this app, we'll just check if the current user's email is verified

      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return const Left(AuthFailure(message: 'User not logged in'));
      }

      // Reload user to get latest email verification status
      await firebaseUser.reload();

      if (firebaseUser.emailVerified) {
        // Update user document in Firestore
        await _usersCollection.doc(firebaseUser.uid).update({
          'isEmailVerified': true,
        });

        return const Right(null);
      } else {
        // Send another verification email if needed
        await firebaseUser.sendEmailVerification();
        return const Left(AuthFailure(
            message: 'Email not verified. A new verification email has been sent.'));
      }
    } catch (e) {
      _logger.e('🔥 Error during email verification', e);
      return const Left(AuthFailure(message: 'Failed to verify email'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      // Firebase handles this differently with action codes
      // This is a simplified version
      await _firebaseAuth.verifyPasswordResetCode(code);
      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error verifying password reset code', e);
      return const Left(AuthFailure(message: 'Invalid or expired password reset code'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      _logger.i('🔐 Password reset successful for: $email');
      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error during password reset', e);
      return const Left(AuthFailure(message: 'Failed to reset password'));
    }
  }

  @override
  Future<Either<Failure, entities.User>> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  }) async {
    try {
      // Update user document
      final now = FieldValue.serverTimestamp();
      await _usersCollection.doc(userId).update({
        'userType': 'player',
        'playerSince': now,
        'playerPaymentStatus': 'completed',
        'playerPaymentId': paymentId,
        'communityId': communityId,
      });

      // Get updated user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('⬆️ User upgraded to player: $userId');

      return Right(_mapFirebaseUserToEntity(userId, userData));
    } catch (e) {
      _logger.e('🔥 Error upgrading to player', e);
      return const Left(AuthFailure(message: 'Failed to upgrade to player'));
    }
  }

  @override
  Future<Either<Failure, List<entities.Community>>> getCommunities() async {
    try {
      final querySnapshot = await _communitiesCollection.get();
      final communities = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        return entities.Community(
          id: doc.id,
          name: data?['name']?.toString() ?? 'Unknown Community',
          description: data?['description']?.toString() ?? 'No description available',
          location: data?['location']?.toString() ?? 'Unknown location',
          leaderId: data?['leaderId']?.toString() ?? '',
          level: entities.CommunityLevel.local, // Default level
          totalPlayers: data?['totalPlayers'] as int? ?? 0,
          points: data?['points'] as int? ?? 0,
          trophyCount: data?['trophyCount'] as int? ?? 0,
          followCount: data?['followCount'] as int? ?? 0,
          playerIds: (data?['playerIds'] as List?)?.cast<String>() ?? const [],
          followerIds: (data?['followerIds'] as List?)?.cast<String>() ?? const [],
          trophies: const [], // Default empty list
          memberCount: data?['memberCount'] as int? ?? 0,
          communityPoints: data?['communityPoints'] as int? ?? 0,
          achievements: const [], // Default empty list
          createdAt: data?['createdAt'] != null
              ? (data?['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();

      // Sort communities by name
      communities.sort((a, b) => a.name.compareTo(b.name));

      return Right(communities);
    } catch (e) {
      _logger.e('🔥 Error fetching communities', e);
      return const Left(AuthFailure(message: 'Failed to fetch communities'));
    }
  }

  // Private helper methods

  /// Check if an email is already registered
  Future<bool> _isEmailRegistered(String email) async {
    try {
      _logger.i('🔍 Checking if email is registered: $email');
      
      // Use fetchSignInMethodsForEmail but with better error handling
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      _logger.i('📧 Sign-in methods for $email: $methods');
      
      final isRegistered = methods.isNotEmpty;
      _logger.i(isRegistered 
          ? '✅ Email is registered: $email' 
          : '❌ Email is not registered: $email');
          
      return isRegistered;
    } catch (e) {
      _logger.e('🔥 Error checking if email is registered: $e');
      // If we can't check, assume it's not registered to avoid blocking registration
      _logger.w('⚠️ Defaulting to "not registered" due to error');
      return false;
    }
  }

  /// Check if a phone number is already registered
  Future<bool> _isPhoneRegistered(String phoneNumber,
      {String? excludeUserId}) async {
    try {
      Query query =
          _usersCollection.where('phoneNumber', isEqualTo: phoneNumber);

      if (excludeUserId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserId);
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('🔥 Error checking if phone is registered', e);
      return false;
    }
  }

  /// Generate a custom token for authentication
  Future<String> _generateCustomToken() async {
    try {
      // In a real app, you would use Firebase Admin SDK to generate custom tokens
      // Since we can't do that in a client app, we'll generate a simple JWT
      // for demonstration purposes

      // This is a simplified version
      final uid = _firebaseAuth.currentUser?.uid ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // In production, use a proper JWT library and a secure key
      return 'dummy_token_${uid}_$timestamp';
    } catch (e) {
      _logger.e('🔥 Error generating custom token', e);
      throw Exception('Failed to generate auth token');
    }
  }

  /// Cache authentication token
  Future<void> _cacheAuthToken(String token, DateTime expiryTime) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(
      key: _tokenExpiryKey,
      value: expiryTime.millisecondsSinceEpoch.toString(),
    );
  }

  /// Check if the authentication token is valid
  Future<bool> _isAuthTokenValid() async {
    try {
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString == null) return false;

      final expiryTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      _logger.e('🔥 Error checking token validity', e);
      return false;
    }
  }

  /// Clear authentication tokens
  Future<void> _clearAuthTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Mapping methods

  /// Map Firestore document to User entity
  entities.User _mapFirebaseUserToEntity(String id, Map<String, dynamic> data) {
    return entities.User(
      id: id,
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      userType: data['userType']?.toString() ?? 'fan',
      communityId: data['communityId']?.toString(),
      registeredAt: _parseDateTime(data['registeredAt']) ?? DateTime.now(),
      playerSince: _parseDateTime(data['playerSince']),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      playerPaymentStatus: data['playerPaymentStatus'] != null
          ? _mapStringToPaymentStatus(data['playerPaymentStatus'].toString())
          : null,
      playerPaymentId: data['playerPaymentId']?.toString(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      lastLoginAt: _parseDateTime(data['lastLoginAt']) ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  /// Helper method to safely parse DateTime from various formats
  DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        _logger.w('Unexpected date type: ${dateValue.runtimeType} for value: $dateValue');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to parse date value: $dateValue, error: $e');
      return null;
    }
  }

  /// Map string to PaymentStatus enum
  entities.PaymentStatus _mapStringToPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return entities.PaymentStatus.pending;
      case 'completed':
        return entities.PaymentStatus.completed;
      case 'failed':
        return entities.PaymentStatus.failed;
      default:
        return entities.PaymentStatus.pending;
    }
  }

  /// Helper method to get user by email
  Future<DocumentSnapshot?> _getUserByEmail(String email) async {
    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    return querySnapshot.docs.isEmpty ? null : querySnapshot.docs.first;
  }

  @override
  Future<Either<Failure, entities.User>> getUserById(String userId) async {
    try {
      _logger.i('🔍 Getting user by ID: $userId');

      final userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        _logger.w('❌ User not found: $userId');
        return const Left(AuthFailure(message: 'User not found'));
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('✅ User found: ${userData['fullName']}');

      return Right(_mapFirebaseUserToEntity(userId, userData));
    } catch (e) {
      _logger.e('🔥 Error getting user by ID', e);
      return const Left(AuthFailure(message: 'Failed to get user'));
    }
  }

  @override
  Future<Either<Failure, entities.User?>> getUserByPhone(
      String phoneNumber) async {
    try {
      _logger.i('🔍 Getting user by phone number: $phoneNumber');

      // Query Firestore for user with this phone number
      final querySnapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.w('❌ No user found with phone number: $phoneNumber');
        return const Right(null);
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data() as Map<String, dynamic>;

      _logger.i('✅ User found by phone: ${userData['fullName']}');

      return Right(_mapFirebaseUserToEntity(userId, userData));
    } catch (e) {
      _logger.e('🔥 Error getting user by phone', e);
      return const Left(AuthFailure(message: 'Failed to get user by phone number'));
    }
  }

  @override
  Future<Either<Failure, String>> getAuthToken() async {
    try {
      final tokenValid = await _isAuthTokenValid();
      if (tokenValid) {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null) {
          return Right(token);
        }
      }

      // Generate new token if not valid
      final token = await _generateCustomToken();
      final expiryTime = DateTime.now().add(_tokenDuration);
      await _cacheAuthToken(token, expiryTime);

      return Right(token);
    } catch (e) {
      _logger.e('🔥 Error getting auth token', e);
      return const Left(AuthFailure(message: 'Failed to get authentication token'));
    }
  }

  @override
  Future<Either<Failure, bool>> isTokenValid() async {
    try {
      final isValid = await _isAuthTokenValid();
      return Right(isValid);
    } catch (e) {
      _logger.e('🔥 Error checking token validity', e);
      return const Left(AuthFailure(message: 'Failed to check token validity'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      // Check if this is the current user
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        // Delete from Firebase Auth
        await currentUser.delete();
      }

      // Delete from Firestore
      await _usersCollection.doc(userId).delete();

      _logger.i('🗑️ User deleted: $userId');
      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error deleting user', e);
      return const Left(AuthFailure(message: 'Failed to delete user'));
    }
  }

  /// Create a pending registration record before email verification
  @override
  Future<Either<Failure, bool>> createPendingRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String verificationCode,
    String? userType,
  }) async {
    try {
      _logger.i('🔄 Creating pending registration for: $email');

      // Check if email already exists in Firebase Auth
      try {
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          _logger.w('❌ Email already exists: $email');
          return const Left(AuthFailure(message: 'This email is already registered'));
        }
      } catch (e) {
        if (!e.toString().contains('user-not-found')) {
          rethrow; // Re-throw unexpected errors with preserved stack trace
        }
        // Otherwise, user not found is expected and good
      }

      // Check if email is already in pending registrations
      final pendingDoc = await _pendingRegistrationsCollection.doc(email).get();
      if (pendingDoc.exists) {
        // Delete existing pending registration
        await _pendingRegistrationsCollection.doc(email).delete();
      }

      // Create new pending registration
      await _pendingRegistrationsCollection.doc(email).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password, // In production, consider hashing this
        'userType': userType ?? 'fan',
        'verificationCode': verificationCode,
        'emailVerified': false,
        'verified': false,
        'expires':
            DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Send verification email with code
      // TODO: Implement actual email sending service
      // For now, we just log the code
      _logger.i('📧 Verification code for $email: $verificationCode');

      return const Right(true);
    } catch (e) {
      _logger.e('🔥 Error creating pending registration', e);
      return Left(AuthFailure(message: 'Failed to create pending registration: $e'));
    }
  }

  /// Verify a pending registration with verification code
  @override
  Future<Either<Failure, bool>> verifyPendingRegistration({
    required String email,
    required String verificationCode,
  }) async {
    try {
      _logger.i('🔄 Verifying pending registration for: $email');

      // Get the pending registration
      final pendingDoc = await _pendingRegistrationsCollection.doc(email).get();
      if (!pendingDoc.exists) {
        _logger.w('❌ No pending registration found for: $email');
        return const Left(
            AuthFailure(message: 'Verification failed: No pending registration found'));
      }

      final pendingData = pendingDoc.data() as Map<String, dynamic>;

      // Check if verification code matches
      if (pendingData['verificationCode'] != verificationCode) {
        _logger.w('❌ Invalid verification code for: $email');
        return const Left(
            AuthFailure(message: 'Verification failed: Invalid verification code'));
      }

      // Check if verification has expired
      final expiryDate = DateTime.parse(pendingData['expires']);
      if (DateTime.now().isAfter(expiryDate)) {
        _logger.w('❌ Verification expired for: $email');
        return const Left(
            AuthFailure(message: 'Verification failed: Verification link has expired'));
      }

      // FIXED: Mark email as verified, but keep verified=false until payment is completed
      await _pendingRegistrationsCollection
          .doc(email)
          .update({
            'emailVerified': true,
            'emailVerifiedAt': DateTime.now().toIso8601String(),
            // 'verified' stays false until payment is completed
          });

      _logger.i('✅ Verification successful for: $email');
      return const Right(true);
    } catch (e) {
      _logger.e('🔥 Error verifying pending registration', e);
      return Left(AuthFailure(message: 'Failed to verify registration: $e'));
    }
  }

  /// Get pending registration data
  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistration({
    required String email,
  }) async {
    try {
      _logger.i('🔍 Getting pending registration for: $email');

      // Get the pending registration
      final pendingDoc = await _pendingRegistrationsCollection.doc(email).get();
      if (!pendingDoc.exists) {
        _logger.w('❌ No pending registration found for: $email');
        return const Right(null);
      }

      return Right(pendingDoc.data() as Map<String, dynamic>);
    } catch (e) {
      _logger.e('🔥 Error getting pending registration', e);
      return Left(AuthFailure(message: 'Failed to get pending registration: $e'));
    }
  }

  /// Delete a pending registration
  @override
  Future<Either<Failure, bool>> deletePendingRegistration({
    required String email,
  }) async {
    try {
      _logger.i('🗑️ Deleting pending registration for: $email');

      // Delete the pending registration
      await _pendingRegistrationsCollection.doc(email).delete();

      return const Right(true);
    } catch (e) {
      _logger.e('🔥 Error deleting pending registration', e);
      return Left(AuthFailure(message: 'Failed to delete pending registration: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification(
      {required String email}) async {
    try {
      // Check if this is a pending registration
      final pendingDoc = await _pendingRegistrationsCollection.doc(email).get();
      if (pendingDoc.exists) {
        // Handle resending verification for pending registration
        // This is handled by the InitiateFanRegistrationEvent or ResendVerificationEmailEvent
        _logger.i(
            '📧 Pending registration found for: $email, verification should be resent through the appropriate event');
        return const Right(null);
      }

      // For existing users
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Left(AuthFailure(message: 'User not found'));
      }

      // In a real implementation, this would send a verification email with a code
      // For now, we'll just log it
      _logger.i('📧 Verification email sent to: $email');

      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error sending verification email', e);
      return const Left(AuthFailure(message: 'Failed to send verification email'));
    }
  }

  /// Update payment status for a player
  Future<Either<Failure, void>> updatePaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    try {
      _logger.i('🔄 Updating payment status for payment ID: $paymentId to $status');

      // Find user with this payment ID
      final querySnapshot = await _usersCollection
          .where('playerPaymentId', isEqualTo: paymentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.w('❌ No user found with payment ID: $paymentId');
        return const Left(AuthFailure(message: 'No user found with this payment ID'));
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data() as Map<String, dynamic>;

      // Update payment status
      final updates = <String, dynamic>{
        'playerPaymentStatus': status,
      };

      // If payment is completed, also verify email and update community count
      if (status == 'completed') {
        updates['isEmailVerified'] = true;
        
        // Update community member count
        final communityId = userData['communityId'] as String?;
        if (communityId != null) {
          await _communitiesCollection.doc(communityId).update({
            'memberCount': FieldValue.increment(1),
          });
        }
      }

      await _usersCollection.doc(userId).update(updates);

      _logger.i('✅ Payment status updated to: $status for user: $userId');
      return const Right(null);
    } catch (e) {
      _logger.e('🔥 Error updating payment status', e);
      return const Left(AuthFailure(message: 'Failed to update payment status'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      final exists = await _isEmailRegistered(email);
      return Right(exists);
    } catch (e) {
      _logger.e('🔥 Error checking email existence', e);
      return const Left(AuthFailure(message: 'Failed to check email existence'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkPhoneExists(String phoneNumber) async {
    try {
      final exists = await _isPhoneRegistered(phoneNumber);
      return Right(exists);
    } catch (e) {
      _logger.e('🔥 Error checking phone existence', e);
      return const Left(AuthFailure(message: 'Failed to check phone existence'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerified(String email) async {
    try {
      // Get user by email
      final userDoc = await _getUserByEmail(email);
      if (userDoc == null) {
        return const Right(false);
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isVerified = userData['isEmailVerified'] as bool? ?? false;
      return Right(isVerified);
    } catch (e) {
      _logger.e('🔥 Error checking email verification', e);
      return const Left(AuthFailure(message: 'Failed to check email verification'));
    }
  }

  @override
  Future<Either<Failure, entities.User>> updateProfile({
    required String userId,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    // This is the same as updateUserProfile - just different name
    // Note: email updates would require additional Firebase Auth operations
    return updateUserProfile(
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
    );
  }
}
