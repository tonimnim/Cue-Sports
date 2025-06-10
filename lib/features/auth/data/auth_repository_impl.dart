import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' show Either, Right, Left;
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/token_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../firebase/firebase_services.dart';
import '../domain/entities/user.dart';
import '../domain/entities/community.dart'; // Import Community entity
import '../domain/auth_repository.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';
import 'models/user_model.dart';

/// Implementation of AuthRepository that uses remote and local data sources
class AuthRepositoryImpl implements AuthRepository {
  // Constants for Firestore collections
  static const String _pendingRegistrationsCollection = 'pendingRegistrations';

  // Firebase services instance
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;
  final FirebaseServices firebaseServices;
  final TokenService tokenService;
  final EmailService emailService;
  final SmsService smsService;

  AuthRepositoryImpl({
    required this.logger,
    required this.networkInfo,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.firebaseServices,
    required this.tokenService,
    required this.emailService,
    required this.smsService,
  }) {
    // Print debug information when this class is instantiated
    print('DEBUG: AuthRepositoryImpl constructor called');
    print('DEBUG: Logger is ${logger == null ? 'NULL' : 'NOT NULL'}');
    print(
        'DEBUG: FirebaseServices is ${firebaseServices == null ? 'NULL' : 'NOT NULL'}');
    print(
        'DEBUG: RemoteDataSource is ${remoteDataSource == null ? 'NULL' : 'NOT NULL'}');
    print(
        'DEBUG: LocalDataSource is ${localDataSource == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: NetworkInfo is ${networkInfo == null ? 'NULL' : 'NOT NULL'}');
    print(
        'DEBUG: TokenService is ${tokenService == null ? 'NULL' : 'NOT NULL'}');
    print(
        'DEBUG: EmailService is ${emailService == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: SmsService is ${smsService == null ? 'NULL' : 'NOT NULL'}');

    // This is a workaround fix - assign logger to a static var to prevent null issues
    _staticLogger = logger;
  }

  // Static logger for use in methods to prevent null issues
  static LoggerService? _staticLogger;

  /// Helper method to convert a string to UserType enum
  UserType getUserTypeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'PLAYER':
        return UserType.player;
      case 'FAN':
      case 'BASIC':
      default:
        return UserType.fan;
    }
  }

  /// Cache user data for faster retrieval
  Future<void> _cacheUserData({required User user}) async {
    try {
      // Create a new UserModel from the User entity with required fields
      final userModel = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        userType: user.userType, // Already a string
        createdAt: user.createdAt,
        registeredAt: user.registeredAt,
        isEmailVerified: user.isEmailVerified,
        lastLoginAt: user.lastLoginAt,
        isActive: user.isActive,
        communityId: user.communityId,
        playerSince: user.playerSince,
        playerPaymentStatus: user.playerPaymentStatus,
        playerPaymentId: user.playerPaymentId,
        profileImageUrl: user.profileImageUrl,
      );
      await localDataSource.cacheUser(userModel);
      logger.i('User data cached successfully');
    } catch (e) {
      logger.e('Error caching user data: ${e.toString()}');
    }
  }

  /// Cache authentication tokens and user data after successful authentication
  Future<void> _cacheAuthenticationData({required User user}) async {
    try {
      // Cache user data first
      await _cacheUserData(user: user);

      // Get Firebase token and cache it
      final firebaseUser = firebaseServices.auth.currentUser;
      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();

        // Only proceed if token is not null and not empty
        if (token != null && token.isNotEmpty) {
          final expiryTime = DateTime.now().add(const Duration(days: 180));

          // Cache in local data source
          await localDataSource.cacheAuthToken(token, expiryTime);

          // Also cache in token service for consistency
          try {
            await tokenService.saveToken(token);
          } catch (e) {
            // Log but don't fail if token service caching fails
            logger.w('⚠️ Failed to cache token in TokenService: $e');
          }

          logger.i('🔐 Authentication tokens cached successfully');
        } else {
          logger
              .w('⚠️ Firebase token is null or empty, skipping token caching');
        }
      } else {
        logger.w('⚠️ No Firebase user found, skipping token caching');
      }
    } catch (e) {
      logger.e('❌ Failed to cache authentication data: $e');
      // Don't throw - this is not critical for authentication to succeed
    }
  }

  /// Get user by phone number
  @override
  Future<Either<Failure, User?>> getUserByPhone(String phoneNumber) async {
    try {
      // IMPORTANT: Using only print statements for debugging, NO LOGGER REFERENCES
      print('DEBUG: Attempting to lookup user by phone: $phoneNumber');

      // Access Firestore directly to avoid potential issues
      final firestore = FirebaseFirestore.instance;
      print('DEBUG: Using direct FirebaseFirestore.instance');

      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print('DEBUG: Query executed, docs count: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: No user found with phone number: $phoneNumber');
        return const Right(null);
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Print the user data for debugging
      print('DEBUG: User data found: ${userData.toString()}');

      // Add document ID to user data
      userData['id'] = userDoc.id;

      // Convert to user entity through _getUserFromFirestore helper
      final user = await _getUserFromFirestore(userData: userData);

      print('DEBUG: User converted to entity: ${user.email}');
      print(
          'DEBUG: User found by phone: ${user.fullName} (Email: ${user.email})');
      return Right(user);
    } catch (e) {
      print('DEBUG: Error in getUserByPhone: ${e.toString()}');
      return Left(ServerFailure(
          message: 'Failed to get user by phone number: ${e.toString()}'));
    }
  }

  /// Register a new fan user
  @override
  Future<Either<Failure, User>> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('🎯 Starting fan registration for: $email');

        // 1. Create Firebase Auth account first - this gives us the proper UID
        final UserCredential credential =
            await firebaseServices.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. Get the actual Firebase Auth UID - this is the proper user ID
        final String userId = credential.user!.uid;
        logger.i('✅ Firebase Auth account created with UID: $userId');

        // 3. Create user document with the proper Firebase Auth UID
        final userModel = UserModel(
          id: userId, // Use actual Firebase Auth UID
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'fan',
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false, // Will be updated after email verification
          lastLoginAt: DateTime.now(),
          isActive: true,
        );

        // 4. Store user data in Firestore using the Firebase Auth UID as document ID
        await firebaseServices.firestore
            .collection('users')
            .doc(userId) // Use Firebase Auth UID as document ID
            .set(userModel.toJson());

        logger.i('✅ User document created in Firestore with ID: $userId');

        // 5. Send email verification using Firebase Auth built-in method
        try {
          await credential.user!.sendEmailVerification();
          logger.i('✅ Email verification sent to: $email');
        } catch (emailError) {
          logger.w('⚠️ Email verification failed: $emailError');
          // Continue registration - user can verify later
        }

        // 6. Cache user locally for offline access
        await localDataSource.cacheUser(userModel);

        logger.i('✅ Fan registration completed successfully');
        return Right(userModel.toEntity());
      } on FirebaseAuthException catch (e) {
        logger.e('🔥 Firebase Auth error: ${e.code} - ${e.message}');
        return Left(AuthFailure(message: _getAuthErrorMessage(e.code)));
      } catch (e) {
        logger.e('🔥 Fan registration error: $e');
        return Left(
            ServerFailure(message: 'Registration failed: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Register a new player user with payment
  @override
  Future<Either<Failure, User>> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('⚽ Starting player registration for: $email');

        // 1. Create Firebase Auth account first - this gives us the proper UID
        final UserCredential credential =
            await firebaseServices.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. Get the actual Firebase Auth UID - this is the proper user ID
        final String userId = credential.user!.uid;
        logger.i('✅ Firebase Auth account created with UID: $userId');

        // 3. Create player user document with the proper Firebase Auth UID
        final userModel = UserModel(
          id: userId, // Use actual Firebase Auth UID
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'player',
          communityId: communityId,
          playerPaymentId: paymentId,
          playerPaymentStatus: PaymentStatus.pending,
          paymentStatus: false, // Payment not completed yet
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false,
          lastLoginAt: DateTime.now(),
          isActive: true,
        );

        // 4. Store user data in Firestore using the Firebase Auth UID as document ID
        await firebaseServices.firestore
            .collection('users')
            .doc(userId) // Use Firebase Auth UID as document ID
            .set(userModel.toJson());

        logger.i('✅ Player document created in Firestore with ID: $userId');

        // 5. Send email verification using Firebase Auth built-in method
        try {
          await credential.user!.sendEmailVerification();
          logger.i('✅ Email verification sent to: $email');
        } catch (emailError) {
          logger.w('⚠️ Email verification failed: $emailError');
          // Continue registration - user can verify later
        }

        // 6. Cache user locally for offline access
        await localDataSource.cacheUser(userModel);

        logger.i('✅ Player registration completed successfully');
        return Right(userModel.toEntity());
      } on FirebaseAuthException catch (e) {
        logger.e('🔥 Firebase Auth error: ${e.code} - ${e.message}');
        return Left(AuthFailure(message: _getAuthErrorMessage(e.code)));
      } catch (e) {
        logger.e('🔥 Player registration error: $e');
        return Left(
            ServerFailure(message: 'Registration failed: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Helper method to convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Please use a different email or sign in.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  /// Helper method to retrieve user data from Firestore map
  Future<User> _getUserFromFirestore(
      {required Map<String, dynamic> userData}) async {
    try {
      // Create a User entity from the Firestore data
      final now = DateTime.now();
      final userType = userData['userType'] as String? ?? 'fan';

      return User(
        id: userData['id'] as String? ?? '',
        fullName: userData['fullName'] as String? ?? 'Unknown User',
        email: userData['email'] as String? ?? '',
        phoneNumber: userData['phoneNumber'] as String? ?? '',
        userType: userType,
        createdAt: _parseDateTime(userData['registeredAt']) ?? now,
        registeredAt: _parseDateTime(userData['registeredAt']) ?? now,
        playerSince: _parseDateTime(userData['playerSince']),
        isEmailVerified: userData['isEmailVerified'] as bool? ?? false,
        isPhoneVerified: userData['isPhoneVerified'] as bool? ?? false,
        isActive: userData['isActive'] as bool? ?? true,
        lastLoginAt: _parseDateTime(userData['lastLoginAt']) ?? now,
        communityId: userData['communityId'] as String?,
        playerPaymentStatus:
            _paymentStatusFromString(userData['playerPaymentStatus']),
        paymentStatus: userData['paymentStatus'] as bool?,
        playerPaymentId: userData['playerPaymentId'] as String?,
        profileImageUrl: userData['profileImageUrl'] as String?,
      );
    } catch (e) {
      logger.e('Error creating user from Firestore data: $e');
      throw CacheException('Failed to parse user data: ${e.toString()}');
    }
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
        print('DEBUG: Unexpected date type: ${dateValue.runtimeType}');
        return null;
      }
    } catch (e) {
      print('DEBUG: Failed to parse date value: $dateValue, error: $e');
      return null;
    }
  }

  /// Helper method to convert string to PaymentStatus enum
  PaymentStatus? _paymentStatusFromString(String? status) {
    if (status == null) return null;
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return null;
    }
  }

  /// Login an existing user
  @override
  Future<Either<Failure, User>> login({
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    try {
      print(
          'DEBUG: AuthRepositoryImpl.login called - Email: ${email ?? 'null'}, Phone: ${phoneNumber ?? 'null'}');

      String loginEmail;

      if (email != null && email.isNotEmpty) {
        loginEmail = email.trim().toLowerCase();
        print('DEBUG: Using provided email for login: $loginEmail');
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        print(
            'DEBUG: Phone number provided. Looking up email for phone: $phoneNumber');
        final querySnapshot =
            await firebaseServices.getUserByPhoneNumber(phoneNumber);

        if (querySnapshot.docs.isEmpty) {
          print('DEBUG: No user found with phone number: $phoneNumber');
          return Left(
              AuthFailure(message: 'No account found with this phone number'));
        }

        final userDocData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        loginEmail = userDocData['email'] as String? ?? '';

        if (loginEmail.isEmpty) {
          print(
              'DEBUG: User has no email address for authentication with phone: $phoneNumber');
          return Left(AuthFailure(
              message: 'User account does not have an email address'));
        }
        print('DEBUG: Found email $loginEmail for phone $phoneNumber');
      } else {
        print('DEBUG: No email or phone provided for login');
        return Left(AuthFailure(
            message: 'Email or phone number is required for login'));
      }

      try {
        print(
            'DEBUG: Attempting to sign out before login to ensure clean state.');
        await firebaseServices.signOut();
        print('DEBUG: Sign out successful or ignored error.');

        print(
            'DEBUG: Calling firebaseServices.auth.signInWithEmailAndPassword with email: $loginEmail');
        final UserCredential credential =
            await firebaseServices.auth.signInWithEmailAndPassword(
          email: loginEmail,
          password: password,
        );
        print(
            'DEBUG: signInWithEmailAndPassword call successful. Credential received.');

        // Explicitly access credential.user and log
        final firebaseAuthUser = credential.user;
        print(
            'DEBUG: Accessed credential.user. Type: ${firebaseAuthUser?.runtimeType}');

        if (firebaseAuthUser == null) {
          print('DEBUG: Firebase Auth succeeded but credential.user is null.');
          return Left(AuthFailure(
              message:
                  'Authentication succeeded but user data (credential.user) is missing'));
        }

        final String userId = firebaseAuthUser.uid;
        print('DEBUG: Successfully accessed firebaseUser.uid: $userId');

        print('DEBUG: Fetching user document from Firestore for UID: $userId');
        final userDoc = await firebaseServices.getUserDoc(userId);

        if (!userDoc.exists) {
          print(
              'DEBUG: User authenticated with UID: $userId but no Firestore data found.');
          return Left(AuthFailure(message: 'User data not found in Firestore'));
        }
        print('DEBUG: Firestore document found for UID: $userId');

        final firestoreUserData = userDoc.data() as Map<String, dynamic>;
        firestoreUserData['id'] = userId;

        print('DEBUG: Updating lastLoginAt for UID: $userId');
        await firebaseServices.updateUserDoc(
          userId,
          {'lastLoginAt': FieldValue.serverTimestamp()},
        );
        print('DEBUG: lastLoginAt updated for UID: $userId');

        print(
            'DEBUG: Converting Firestore data to User entity for UID: $userId');
        final userEntity =
            await _getUserFromFirestore(userData: firestoreUserData);
        print(
            'DEBUG: Successfully converted Firestore data to User entity for UID: $userId. Email: ${userEntity.email}');

        // Cache authentication data
        await _cacheAuthenticationData(user: userEntity);

        // Check if player has pending payment
        if (userEntity.userType == 'player' &&
            userEntity.paymentStatus == false) {
          logger.w('⚠️ Player login successful but payment is pending');
          // Still return success, but the UI will handle redirecting to payment
        }

        return Right(userEntity);
      } on FirebaseAuthException catch (e) {
        print(
            'DEBUG: FirebaseAuthException caught: Code: ${e.code}, Message: ${e.message}');
        // Handle specific Firebase Auth errors based on e.code
        switch (e.code) {
          case 'user-not-found':
            return Left(AuthFailure(
                message: 'No account found with these credentials.'));
          case 'wrong-password':
            return Left(
                AuthFailure(message: 'The password you entered is incorrect.'));
          // Add other specific cases as needed
          default:
            return Left(AuthFailure(
                message: 'Firebase Auth Error: ${e.message ?? e.code}'));
        }
      } catch (e, s) {
        // This is where the PigeonUserDetails error is likely being caught if it's not a FirebaseAuthException
        print(
            'DEBUG: Inner catch block in AuthRepositoryImpl.login: Error: ${e.toString()}, Stacktrace: $s');
        return Left(ServerFailure(
            message:
                'Login failed due to an unexpected error: ${e.toString()}'));
      }
    } catch (e, s) {
      print(
          'DEBUG: Outer catch block in AuthRepositoryImpl.login: Error: ${e.toString()}, Stacktrace: $s');
      return Left(ServerFailure(
          message:
              'An unexpected error occurred during the login process: ${e.toString()}'));
    }
  }

  /// Logout the current user
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUserCache();

      // If online, also tell the server to invalidate the token
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }

      return const Right(null);
    } on ServerException {
      // Still consider logout successful if local cache was cleared
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get the current user if available
  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // First check if token is valid
      final isValidToken = await localDataSource.isAuthTokenValid();
      if (!isValidToken) {
        return const Right(null);
      }

      // If online, get fresh user data
      if (await networkInfo.isConnected) {
        try {
          final userModel = await remoteDataSource.getCurrentUser();
          if (userModel != null) {
            await localDataSource.cacheUser(userModel);
            return Right(userModel.toEntity());
          }
        } catch (_) {
          // Fall back to local data if remote fails
        }
      }

      // If offline or remote failed, try to get from local cache
      final cachedUser = await localDataSource.getLastUser();
      return Right(cachedUser?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Send a password reset email
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPasswordResetEmail(email: email);
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Verify a password reset code
  @override
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyPasswordResetCode(
          email: email,
          code: code,
        );
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Reset password with a verification code
  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
        );
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Upgrade a fan to a player with payment
  @override
  Future<Either<Failure, User>> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.upgradeToPlayer(
          userId: userId,
          communityId: communityId,
          paymentId: paymentId,
        );

        // Update local cache with upgraded user
        await localDataSource.cacheUser(userModel);

        return Right(userModel.toEntity());
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Update user profile information
  @override
  Future<Either<Failure, User>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.updateUserProfile(
          userId: userId,
          fullName: fullName,
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

        // Update local cache
        await localDataSource.cacheUser(userModel);

        return Right(userModel.toEntity());
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Verify email with a verification code
  @override
  Future<Either<Failure, void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyEmail(
          email: email,
          code: code,
        );

        // Update local cache to reflect email verification
        final cachedUser = await localDataSource.getLastUser();
        if (cachedUser != null && cachedUser.email == email) {
          final updatedUser = cachedUser.copyWith(isEmailVerified: true);
          await localDataSource.cacheUser(updatedUser);
        }

        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Send email verification code
  @override
  Future<Either<Failure, void>> sendEmailVerification({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendEmailVerification(email: email);
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Get user by ID
  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      // Get user from Firestore
      final userDoc = await firebaseServices.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Left(AuthFailure(message: 'User not found'));
      }

      final userData = userDoc.data()!;
      userData['id'] = userId;

      final user = await _getUserFromFirestore(userData: userData);

      logger.i('👤 User retrieved: ${user.email}');

      return Right(user);
    } catch (e) {
      logger.e('🔥 Error getting user by ID: $e');
      return Left(
          ServerFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }

  /// Get user by phone number and perform login
  Future<Either<Failure, User>> getUserByPhoneAndLogin({
    required String phoneNumber,
  }) async {
    try {
      logger.i('Getting user by phone: $phoneNumber');

      final querySnapshot = await firebaseServices.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        logger.w('No user found with phone: $phoneNumber');
        return Left(
            ServerFailure(message: 'No user found with this phone number'));
      }

      final userData = querySnapshot.docs.first.data();
      // Add document ID to user data
      userData['id'] = querySnapshot.docs.first.id;

      final email = userData['email'];

      logger.i('Found user with email: $email');

      if (email == null || email.toString().isEmpty) {
        return Left(
            ServerFailure(message: 'No email associated with this account'));
      }

      try {
        // Extract user data
        final User user = await _getUserFromFirestore(userData: userData);

        // Cache user data for faster retrieval
        await _cacheUserData(user: user);

        logger.i('Successfully retrieved user data for phone: $phoneNumber');
        return Right(user);
      } catch (e) {
        logger.e('Error processing user data: ${e.toString()}');
        return Left(ServerFailure(
            message: 'Error processing user data: ${e.toString()}'));
      }
    } catch (e) {
      logger.e('Error getting user by phone: ${e.toString()}');
      return Left(
          ServerFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }

  /// Delete user account
  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteUser(userId);

        // If deleted user is the current user, clear local cache
        final cachedUser = await localDataSource.getLastUser();
        if (cachedUser != null && cachedUser.id == userId) {
          await localDataSource.clearUserCache();
        }

        return const Right(null);
      } on AuthException {
        // Still consider deletion successful if remote succeeded
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Get authentication token
  @override
  Future<Either<Failure, String?>> getAuthToken() async {
    try {
      // Try to get from local cache first
      final cachedToken = await localDataSource.getAuthToken();
      if (cachedToken != null) {
        final isValid = await localDataSource.isAuthTokenValid();
        if (isValid) {
          return Right(cachedToken);
        }
      }

      // If not in cache or expired, and we're online, try to refresh
      if (await networkInfo.isConnected) {
        final refreshToken = await remoteDataSource.getRefreshToken();
        if (refreshToken != null) {
          // In a real implementation, you'd use the refresh token to get a new auth token
          // For the MVP, we'll just return null to trigger a re-login
          return const Right(null);
        }
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Check if token is valid and not expired
  @override
  Future<Either<Failure, bool>> isTokenValid() async {
    try {
      final isValid = await localDataSource.isAuthTokenValid();
      return Right(isValid);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Create a pending registration with SMS verification (20-minute cooldown)
  @override
  Future<Either<Failure, bool>> createPendingUserRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String userType,
    String? communityId,
    String? paymentId,
  }) async {
    try {
      logger.i('🚀 Starting pending registration for: $email');

      // Step 1: Clean up any orphaned pending registrations for this phone/email
      await _cleanupOrphanedRegistrations(phoneNumber, email);

      // Step 2: Check for existing users in users collection (not pending)
      final emailExists = await _checkEmailInUsersCollection(email);
      if (emailExists.isRight() && emailExists.getOrElse(() => false)) {
        return Left(
            AuthFailure(message: 'Email address is already registered'));
      }

      final phoneExists = await _checkPhoneInUsersCollection(phoneNumber);
      if (phoneExists.isRight() && phoneExists.getOrElse(() => false)) {
        return Left(AuthFailure(message: 'Phone number is already registered'));
      }

      // Step 3: Simple cooldown check - look for recent registrations by phone
      final cooldownCheck = await _checkSimpleRegistrationCooldown(phoneNumber);
      if (cooldownCheck.isLeft()) {
        return cooldownCheck;
      }

      // Step 4: Generate verification code
      final verificationCode = smsService.generateVerificationCode();
      final pendingId = firebaseServices.firestore
          .collection('pendingRegistrations')
          .doc()
          .id;

      // Step 5: Store pending registration in Firestore
      final now = DateTime.now();
      await firebaseServices.firestore
          .collection('pendingRegistrations')
          .doc(pendingId)
          .set({
        'id': pendingId,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'passwordHash': password, // TODO: Hash this properly
        'userType': userType,
        'communityId': communityId,
        'paymentId': paymentId,
        'verificationCode': verificationCode,
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
        'attempts': 0,
        'maxAttempts': 3,
        'lastSmsRequestAt': FieldValue.serverTimestamp(),
      });

      // Step 6: Send SMS verification code
      final smsResult = await smsService.sendVerificationCode(
        phoneNumber: phoneNumber,
        fullName: fullName,
        verificationCode: verificationCode,
        userType: userType,
      );

      if (!smsResult) {
        // Clean up pending registration if SMS failed
        await firebaseServices.firestore
            .collection('pendingRegistrations')
            .doc(pendingId)
            .delete();
        return Left(ServerFailure(
            message: 'Failed to send verification code. Please try again.'));
      }

      // Step 7: Store in local storage for offline access
      await localDataSource.cacheUser(UserModel(
        id: pendingId, // Use pending ID as temporary ID
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        userType: userType,
        createdAt: DateTime.now(),
        registeredAt: DateTime.now(),
        isEmailVerified: false,
        lastLoginAt: DateTime.now(),
        isActive: true,
        communityId: communityId,
        playerSince: DateTime.now(),
        playerPaymentStatus: PaymentStatus.pending,
        playerPaymentId: paymentId,
        profileImageUrl: '',
      ));

      logger.i('✅ Pending registration created with SMS verification');
      return const Right(true);
    } catch (e) {
      logger.e('❌ Error creating pending registration: $e');
      return Left(
          ServerFailure(message: 'Registration failed: ${e.toString()}'));
    }
  }

  /// Verify SMS code and complete registration
  @override
  Future<Either<Failure, User>> verifySmsAndCompleteRegistration({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      logger.i('🔍 Verifying SMS code for: $phoneNumber');

      // Step 1: Find pending registration by phone
      final pendingQuery = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('verified', isEqualTo: false)
          .limit(1)
          .get();

      if (pendingQuery.docs.isEmpty) {
        return Left(ValidationFailure(
            message: 'No pending registration found for this phone number'));
      }

      final pendingDoc = pendingQuery.docs.first;
      final pendingData = pendingDoc.data();

      // Step 2: Check expiry (10 minutes)
      final expiresAt = DateTime.parse(pendingData['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        await pendingDoc.reference.delete();
        return Left(ValidationFailure(
            message: 'Verification code has expired. Please register again.'));
      }

      // Step 3: Check attempts
      final attempts = pendingData['attempts'] as int;
      if (attempts >= 3) {
        await pendingDoc.reference.delete();
        return Left(ValidationFailure(
            message: 'Too many failed attempts. Please register again.'));
      }

      // Step 4: Verify code
      final storedCode = pendingData['verificationCode'] as String;
      if (verificationCode != storedCode) {
        // Increment attempts
        await pendingDoc.reference.update({'attempts': attempts + 1});
        final remaining = 3 - (attempts + 1);
        return Left(ValidationFailure(
            message:
                'Invalid verification code. $remaining attempts remaining.'));
      }

      // Step 5: Code is valid - Create Firebase Auth account
      final email = pendingData['email'] as String;
      final password = pendingData['passwordHash'] as String;

      final userCredential =
          await firebaseServices.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(ServerFailure(message: 'Failed to create user account'));
      }

      // Step 6: Create user record in users collection
      final userType = pendingData['userType'] as String;
      final userId = userCredential.user!.uid;
      final now = DateTime.now();

      final userData = {
        'uid': userId,
        'fullName': pendingData['fullName'],
        'email': email,
        'phoneNumber': phoneNumber,
        'userType': userType,
        'isEmailVerified': true, // SMS verified counts as verified
        'isPhoneVerified': true,
        'verified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'registeredAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileComplete': true,
        'accountStatus': 'active',
      };

      // Add player-specific fields
      if (userType == 'player') {
        userData.addAll({
          'communityId': pendingData['communityId'],
          'paymentStatus': false, // Payment not completed yet
          'playerPaymentStatus': 'pending',
          'playerPaymentId': pendingData['paymentId'],
          'membershipActive': false,
          'playerSince': FieldValue.serverTimestamp(),
        });
      }

      await firebaseServices.firestore
          .collection('users')
          .doc(userId)
          .set(userData);

      // Step 7: Clean up pending registration
      await pendingDoc.reference.delete();

      // Step 8: Create User entity
      final user = User(
        id: userId,
        fullName: pendingData['fullName'],
        email: email,
        phoneNumber: phoneNumber,
        userType: userType,
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: now,
        registeredAt: now,
        lastLoginAt: now,
        isActive: true,
        communityId: userType == 'player' ? pendingData['communityId'] : null,
        paymentStatus: userType == 'player' ? false : null,
        playerPaymentStatus:
            userType == 'player' ? PaymentStatus.pending : null,
        playerPaymentId: userType == 'player' ? pendingData['paymentId'] : null,
        playerSince: userType == 'player' ? now : null,
      );

      // Step 9: Cache user data locally
      await _cacheAuthenticationData(user: user);

      logger.i('✅ User registration completed successfully');
      return Right(user);
    } catch (e) {
      logger.e('❌ Error verifying SMS and completing registration: $e');
      return Left(
          ServerFailure(message: 'Verification failed: ${e.toString()}'));
    }
  }

  /// Simple cooldown check without composite index requirements
  Future<Either<Failure, bool>> _checkSimpleRegistrationCooldown(
      String phoneNumber) async {
    try {
      // Look for any pending registration for this phone in the last 20 minutes
      final twentyMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 20));

      final recentRegistrations = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      for (final doc in recentRegistrations.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (createdAt != null && createdAt.isAfter(twentyMinutesAgo)) {
          final waitMinutes =
              20 - DateTime.now().difference(createdAt).inMinutes;
          return Left(AuthFailure(
              message:
                  'Please wait $waitMinutes more minutes before requesting another verification code.'));
        }
      }

      return const Right(false);
    } catch (e) {
      logger.e('❌ Error checking registration cooldown: $e');
      // Don't fail the entire flow for cooldown check issues
      logger.w('⚠️ Continuing without cooldown check due to error');
      return const Right(false);
    }
  }

  /// Clean up orphaned pending registrations
  Future<void> _cleanupOrphanedRegistrations(
      String phoneNumber, String email) async {
    try {
      logger.i('🧹 Cleaning up orphaned registrations');

      // Delete old pending registrations for this phone/email
      final phoneQuery = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      final emailQuery = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .get();

      // Delete phone-based orphaned registrations
      for (final doc in phoneQuery.docs) {
        await doc.reference.delete();
        logger.i('🗑️ Deleted orphaned registration for phone: $phoneNumber');
      }

      // Delete email-based orphaned registrations
      for (final doc in emailQuery.docs) {
        await doc.reference.delete();
        logger.i('🗑️ Deleted orphaned registration for email: $email');
      }

      // Also clean up expired registrations (older than 24 hours)
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
      final expiredQuery = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .get();

      for (final doc in expiredQuery.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (createdAt != null && createdAt.isBefore(oneDayAgo)) {
          await doc.reference.delete();
          logger.i('🗑️ Deleted expired registration: ${data['email']}');
        }
      }
    } catch (e) {
      logger.w('⚠️ Error cleaning up orphaned registrations: $e');
      // Don't fail the flow for cleanup issues
    }
  }

  /// Check if email exists in users collection
  Future<Either<Failure, bool>> _checkEmailInUsersCollection(
      String email) async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return Right(querySnapshot.docs.isNotEmpty);
    } catch (e) {
      logger.e('Error checking if email exists in users collection: $e');
      return Left(ServerFailure(message: 'Failed to check email existence'));
    }
  }

  /// Check if phone exists in users collection
  Future<Either<Failure, bool>> _checkPhoneInUsersCollection(
      String phoneNumber) async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return Right(querySnapshot.docs.isNotEmpty);
    } catch (e) {
      logger.e('Error checking if phone exists in users collection: $e');
      return Left(
          ServerFailure(message: 'Failed to check phone number existence'));
    }
  }

  /// Check 20-minute cooldown for SMS abuse prevention (DEPRECATED - using simple check now)
  Future<Either<Failure, DateTime?>> _checkRegistrationCooldown(
      String phoneNumber) async {
    try {
      // Use the simpler cooldown check to avoid index requirements
      final cooldownResult =
          await _checkSimpleRegistrationCooldown(phoneNumber);
      return cooldownResult.fold(
        (failure) => Left(failure),
        (hasCooldown) => const Right(null),
      );
    } catch (e) {
      logger.e('❌ Error checking registration cooldown: $e');
      return Left(ServerFailure(message: 'Cooldown check failed'));
    }
  }

  /// Verify custom email verification code
  @override
  Future<Either<Failure, User>> verifyCustomEmailCode({
    required String email,
    required String verificationCode,
  }) async {
    try {
      logger.i('✅ Verifying custom email code for: $email');

      // Get verification info from temporary collection
      final verificationDoc = await firebaseServices.firestore
          .collection('emailVerifications')
          .doc(email)
          .get();

      if (!verificationDoc.exists) {
        return Left(
            AuthFailure(message: 'Verification code not found or expired'));
      }

      final verificationData = verificationDoc.data()!;
      final storedCode = verificationData['verificationCode'] as String;
      final userId = verificationData['userId'] as String;
      final expiresAt = DateTime.parse(verificationData['expiresAt'] as String);

      // Check if code matches and hasn't expired
      if (storedCode != verificationCode) {
        return Left(AuthFailure(message: 'Invalid verification code'));
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return Left(AuthFailure(message: 'Verification code has expired'));
      }

      // Mark user as verified in Firestore
      await firebaseServices.firestore.collection('users').doc(userId).update({
        'isEmailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      });

      // Clean up verification doc
      await firebaseServices.firestore
          .collection('emailVerifications')
          .doc(email)
          .delete();

      // Get user data
      final userDoc = await firebaseServices.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Left(ServerFailure(message: 'User data not found'));
      }

      final userData = userDoc.data()!;
      userData['id'] = userId;
      userData['isEmailVerified'] = true;

      final user = await _getUserFromFirestore(userData: userData);
      await _cacheAuthenticationData(user: user);

      logger.i('✅ Custom email verification completed');
      return Right(user);
    } catch (e) {
      logger.e('🔥 Failed to verify custom email code: $e');
      return Left(
          ServerFailure(message: 'Verification failed: ${e.toString()}'));
    }
  }

  // Legacy Methods (Backward Compatibility)

  @override
  Future<Either<Failure, bool>> createPendingRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String verificationCode,
    String? userType,
  }) async {
    // Redirect to new method
    return await createPendingUserRegistration(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      userType: userType ?? 'fan',
    );
  }

  @override
  Future<Either<Failure, bool>> verifyPendingRegistration({
    required String email,
    required String verificationCode,
  }) async {
    // Use new method but return boolean for compatibility
    final result = await verifyEmailAndCompleteRegistration(
      email: email,
      verificationCode: verificationCode,
    );

    return result.fold(
      (failure) => Left(failure),
      (user) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistration({
    required String email,
  }) async {
    // Redirect to new method
    return await getPendingRegistrationStatus(email: email);
  }

  @override
  Future<Either<Failure, bool>> deletePendingRegistration({
    required String email,
  }) async {
    try {
      await firebaseServices.firestore
          .collection('pendingRegistrations')
          .doc(email)
          .delete();

      logger.i('🗑️ Deleted pending registration for: $email');
      return const Right(true);
    } catch (e) {
      logger.e('Error deleting pending registration: $e');
      return Left(
          ServerFailure(message: 'Failed to delete pending registration'));
    }
  }

  // Missing method implementations

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    // Use the new method that checks users collection
    return await _checkEmailInUsersCollection(email);
  }

  @override
  Future<Either<Failure, bool>> checkPhoneExists(String phoneNumber) async {
    // Use the new method that checks users collection
    return await _checkPhoneInUsersCollection(phoneNumber);
  }

  @override
  Future<Either<Failure, bool>> cleanupOrphanedAccount({
    required String email,
    required String password,
  }) async {
    try {
      // Try to sign in to check if Firebase Auth account exists
      final credential = await firebaseServices.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Check if Firestore document exists
        final userDoc = await firebaseServices.firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Delete orphaned Firebase Auth account
          await credential.user!.delete();
          logger.i('🗑️ Cleaned up orphaned Firebase Auth account for: $email');
          return const Right(true);
        }
      }

      return const Right(false);
    } catch (e) {
      logger.e('Error cleaning up orphaned account: $e');
      return Left(ServerFailure(message: 'Failed to cleanup orphaned account'));
    }
  }

  @override
  Future<Either<Failure, User>> completeEmailVerification({
    required String uid,
  }) async {
    try {
      // Get user data from Firestore
      final userDoc =
          await firebaseServices.firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return Left(ServerFailure(message: 'User not found'));
      }

      final userData = userDoc.data()!;
      userData['id'] = uid;
      userData['isEmailVerified'] = true;

      // Update verification status in Firestore
      await firebaseServices.firestore.collection('users').doc(uid).update({
        'isEmailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      });

      final user = await _getUserFromFirestore(userData: userData);
      await _cacheAuthenticationData(user: user);

      logger.i('✅ Email verification completed for: ${user.email}');
      return Right(user);
    } catch (e) {
      logger.e('Error completing email verification: $e');
      return Left(
          ServerFailure(message: 'Failed to complete email verification'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunities() async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('communities')
          .orderBy('name')
          .get();

      final communities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Community(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          memberCount: data['memberCount'] ?? 0,
          isActive: data['isActive'] ?? true,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      return Right(communities);
    } catch (e) {
      logger.e('Error getting communities: $e');
      return Left(ServerFailure(message: 'Failed to get communities'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistrationStatus({
    required String email,
  }) async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }

      final data = querySnapshot.docs.first.data();
      return Right(data);
    } catch (e) {
      logger.e('Error getting pending registration status: $e');
      return Left(
          ServerFailure(message: 'Failed to get pending registration status'));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified(String email) async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(false);
      }

      final userData = querySnapshot.docs.first.data();
      final isVerified = userData['isEmailVerified'] as bool? ?? false;
      return Right(isVerified);
    } catch (e) {
      logger.e('Error checking email verification status: $e');
      return Left(
          ServerFailure(message: 'Failed to check email verification status'));
    }
  }

  @override
  Future<Either<Failure, bool>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      // Find pending registration
      final querySnapshot = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left(
            ValidationFailure(message: 'No pending registration found'));
      }

      final pendingData = querySnapshot.docs.first.data();
      final verificationCode = emailService.generateVerificationCode();

      // Send email
      final emailSent = await emailService.sendVerificationEmail(
        email: email,
        fullName: pendingData['fullName'],
        verificationCode: verificationCode,
        userType: pendingData['userType'] ?? 'fan',
      );

      if (!emailSent) {
        return Left(
            ServerFailure(message: 'Failed to send verification email'));
      }

      // Update verification code in pending registration
      await querySnapshot.docs.first.reference.update({
        'verificationCode': verificationCode,
        'lastEmailSentAt': FieldValue.serverTimestamp(),
      });

      return const Right(true);
    } catch (e) {
      logger.e('Error resending verification email: $e');
      return Left(
          ServerFailure(message: 'Failed to resend verification email'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePendingRegistration({
    required String email,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final querySnapshot = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left(
            ValidationFailure(message: 'No pending registration found'));
      }

      await querySnapshot.docs.first.reference.update(updates);
      return const Right(true);
    } catch (e) {
      logger.e('Error updating pending registration: $e');
      return Left(
          ServerFailure(message: 'Failed to update pending registration'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyEmailAndCompleteRegistration({
    required String email,
    required String verificationCode,
  }) async {
    try {
      logger.i('🔍 Verifying email and completing registration for: $email');

      // Find pending registration
      final querySnapshot = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .where('verified', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left(
            ValidationFailure(message: 'No pending registration found'));
      }

      final pendingDoc = querySnapshot.docs.first;
      final pendingData = pendingDoc.data();

      // Verify code
      final storedCode = pendingData['verificationCode'] as String;
      if (verificationCode != storedCode) {
        return Left(ValidationFailure(message: 'Invalid verification code'));
      }

      // Check expiry (24 hours)
      final createdAt = (pendingData['createdAt'] as Timestamp).toDate();
      if (DateTime.now().difference(createdAt).inHours > 24) {
        await pendingDoc.reference.delete();
        return Left(
            ValidationFailure(message: 'Verification code has expired'));
      }

      // Create Firebase Auth account
      final password = pendingData['passwordHash'] as String;
      final userCredential =
          await firebaseServices.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(ServerFailure(message: 'Failed to create user account'));
      }

      // Create user record in Firestore
      final userType = pendingData['userType'] as String;
      final userId = userCredential.user!.uid;

      final userData = {
        'uid': userId,
        'fullName': pendingData['fullName'],
        'email': email,
        'phoneNumber': pendingData['phoneNumber'],
        'userType': userType,
        'isEmailVerified': true,
        'verified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'accountStatus': 'active',
      };

      // Add player-specific fields
      if (userType == 'player') {
        userData.addAll({
          'communityId': pendingData['communityId'],
          'paymentStatus': 'pending',
          'paymentId': pendingData['paymentId'],
          'membershipActive': false,
        });
      }

      await firebaseServices.firestore
          .collection('users')
          .doc(userId)
          .set(userData);

      // Clean up pending registration
      await pendingDoc.reference.delete();

      // Create User entity
      final user = User(
        id: userId,
        fullName: pendingData['fullName'],
        email: email,
        phoneNumber: pendingData['phoneNumber'],
        userType: userType,
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: DateTime.now(),
        registeredAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        communityId: userType == 'player' ? pendingData['communityId'] : null,
        paymentStatus: userType == 'player' ? false : null,
        playerPaymentStatus:
            userType == 'player' ? PaymentStatus.pending : null,
        playerPaymentId: userType == 'player' ? pendingData['paymentId'] : null,
        playerSince: userType == 'player' ? DateTime.now() : null,
      );

      await _cacheAuthenticationData(user: user);

      logger.i('✅ Email verification and registration completed');
      return Right(user);
    } catch (e) {
      logger.e('Error verifying email and completing registration: $e');
      return Left(
          ServerFailure(message: 'Email verification failed: ${e.toString()}'));
    }
  }

  /// Resend SMS verification code (with cooldown check)
  @override
  Future<Either<Failure, bool>> resendSmsVerificationCode({
    required String phoneNumber,
  }) async {
    try {
      // Check 2-minute cooldown for resend
      final pendingQuery = await firebaseServices.firestore
          .collection('pendingRegistrations')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('verified', isEqualTo: false)
          .limit(1)
          .get();

      if (pendingQuery.docs.isEmpty) {
        return Left(
            ValidationFailure(message: 'No pending registration found'));
      }

      final pendingDoc = pendingQuery.docs.first;
      final pendingData = pendingDoc.data();

      final lastSmsAt = (pendingData['lastSmsRequestAt'] as Timestamp).toDate();
      if (DateTime.now().difference(lastSmsAt).inMinutes < 2) {
        return Left(ValidationFailure(
            message: 'Please wait 2 minutes before requesting another code'));
      }

      // Generate new code and send SMS
      final newCode = smsService.generateVerificationCode();

      final smsResult = await smsService.sendVerificationCode(
        phoneNumber: phoneNumber,
        fullName: pendingData['fullName'],
        verificationCode: newCode,
        userType: pendingData['userType'] ?? 'fan',
      );

      if (!smsResult) {
        return Left(ServerFailure(message: 'Failed to send verification code'));
      }

      // Update pending registration
      await pendingDoc.reference.update({
        'verificationCode': newCode,
        'lastSmsRequestAt': FieldValue.serverTimestamp(),
        'attempts': 0, // Reset attempts on resend
      });

      return const Right(true);
    } catch (e) {
      logger.e('❌ Error resending SMS: $e');
      return Left(ServerFailure(message: 'Failed to resend verification code'));
    }
  }
}
