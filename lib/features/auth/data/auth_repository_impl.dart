import 'dart:async';

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

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
    required this.firebaseServices,
    required this.tokenService,
    required this.emailService,
  }) {
    // Print debug information when this class is instantiated
    print('DEBUG: AuthRepositoryImpl constructor called');
    print('DEBUG: Logger is ${logger == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: FirebaseServices is ${firebaseServices == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: RemoteDataSource is ${remoteDataSource == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: LocalDataSource is ${localDataSource == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: NetworkInfo is ${networkInfo == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: TokenService is ${tokenService == null ? 'NULL' : 'NOT NULL'}');
    print('DEBUG: EmailService is ${emailService == null ? 'NULL' : 'NOT NULL'}');
    
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
          logger.w('⚠️ Firebase token is null or empty, skipping token caching');
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
      print('DEBUG: User found by phone: ${user.fullName} (Email: ${user.email})');
      return Right(user);
    } catch (e) {
      print('DEBUG: Error in getUserByPhone: ${e.toString()}');
      return Left(ServerFailure(message: 'Failed to get user by phone number: ${e.toString()}'));
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
        
        // 1. Store user details in local storage first
        final draft = {
          'userType': 'fan',
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Cache draft in secure storage
        await localDataSource.cacheUser(UserModel(
          id: '', // Temporary ID until Firebase account is created
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'fan',
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false,
          lastLoginAt: DateTime.now(),
          isActive: true,
        ));
        
        logger.i('📝 User details stored in local storage');
        
        // 2. Try to create Firebase Auth account
        firebase_auth.User? firebaseUser;
        
        try {
          final credential = await firebaseServices.auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = credential.user;
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            logger.i('🔄 Email already has Firebase Auth account, attempting to sign in...');
            
            // Try to sign in with the existing account
            try {
              final signInCredential = await firebaseServices.auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              firebaseUser = signInCredential.user;
              logger.i('✅ Successfully signed into existing Firebase Auth account');
            } on firebase_auth.FirebaseAuthException catch (signInError) {
              if (signInError.code == 'wrong-password') {
                return Left(AuthFailure(message: 
                  'This email is already registered. Please check your password or try logging in instead.'));
              }
              return Left(AuthFailure(message: 'Failed to authenticate: ${signInError.message}'));
            }
          } else {
            // Other Firebase Auth errors
            return Left(AuthFailure(message: e.message ?? 'Registration failed'));
          }
        }
        
        if (firebaseUser == null) {
          return Left(AuthFailure(message: 'Failed to create or access Firebase account'));
        }
        
        logger.i('🔐 Firebase Auth account ready: ${firebaseUser.uid}');
        
        // 3. Send email verification link
        await firebaseUser.sendEmailVerification();
        logger.i('📧 Email verification link sent to: $email');
        
        // 4. Create temporary user model with unverified status
        final userModel = UserModel(
          id: firebaseUser.uid,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'fan',
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false, // Will be true after email verification
          lastLoginAt: DateTime.now(),
          isActive: true,
        );
        
        // 5. Store or update in Firestore
        await firebaseServices.firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userModel.toJson(), SetOptions(merge: true)); // Use merge to update if exists
            
        // Note: Tokens will be stored after email verification is complete
        logger.i('✅ Fan registration initiated. Awaiting email verification.');
        
        return Right(userModel.toEntity());
      } catch (e) {
        logger.e('🔥 Fan registration error: $e');
        return Left(ServerFailure(message: 'Registration failed: ${e.toString()}'));
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
        
        // 1. Store all details including community in local storage
        final draft = {
          'userType': 'player',
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'communityId': communityId,
          'paymentId': paymentId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Cache draft in secure storage
        await localDataSource.cacheUser(UserModel(
          id: '', // Temporary ID until Firebase account is created
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'player',
          communityId: communityId,
          playerPaymentId: paymentId,
          playerPaymentStatus: PaymentStatus.pending,
          paymentStatus: false, // Boolean: false = not paid
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false,
          lastLoginAt: DateTime.now(),
          isActive: true,
        ));
        
        logger.i('📝 Player details and community stored in local storage');
        
        // 2. Try to create Firebase Auth account
        firebase_auth.User? firebaseUser;
        
        try {
          final credential = await firebaseServices.auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = credential.user;
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            logger.i('🔄 Email already has Firebase Auth account, attempting to sign in...');
            
            // Try to sign in with the existing account
            try {
              final signInCredential = await firebaseServices.auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              firebaseUser = signInCredential.user;
              logger.i('✅ Successfully signed into existing Firebase Auth account');
            } on firebase_auth.FirebaseAuthException catch (signInError) {
              if (signInError.code == 'wrong-password') {
                return Left(AuthFailure(message: 
                  'This email is already registered. Please check your password or try logging in instead.'));
              }
              return Left(AuthFailure(message: 'Failed to authenticate: ${signInError.message}'));
            }
          } else {
            // Other Firebase Auth errors
            return Left(AuthFailure(message: e.message ?? 'Registration failed'));
          }
        }
        
        if (firebaseUser == null) {
          return Left(AuthFailure(message: 'Failed to create or access Firebase account'));
        }
        
        logger.i('🔐 Firebase Auth account ready: ${firebaseUser.uid}');
        
        // 3. Send email verification link
        await firebaseUser.sendEmailVerification();
        logger.i('📧 Email verification link sent to: $email');
        
        // 4. Create player user model with pending payment status
        final userModel = UserModel(
          id: firebaseUser.uid,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          userType: 'player',
          communityId: communityId,
          playerPaymentId: paymentId,
          playerPaymentStatus: PaymentStatus.pending,
          paymentStatus: false, // Payment not completed
          createdAt: DateTime.now(),
          registeredAt: DateTime.now(),
          isEmailVerified: false, // Will be true after email verification
          lastLoginAt: DateTime.now(),
          isActive: true,
        );
        
        // 5. Store or update in Firestore
        await firebaseServices.firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userModel.toJson(), SetOptions(merge: true)); // Use merge to update if exists
            
        // Note: Tokens will be stored after email verification
        // User cannot access home until payment is completed
        logger.i('✅ Player registration initiated. Awaiting email verification and payment.');
        
        return Right(userModel.toEntity());
      } catch (e) {
        logger.e('🔥 Player registration error: $e');
        return Left(ServerFailure(message: 'Registration failed: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Helper method to retrieve user data from Firestore map
  Future<User> _getUserFromFirestore({required Map<String, dynamic> userData}) async {
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
        playerPaymentStatus: _paymentStatusFromString(userData['playerPaymentStatus']),
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
      print('DEBUG: AuthRepositoryImpl.login called - Email: ${email ?? 'null'}, Phone: ${phoneNumber ?? 'null'}');
      
      String loginEmail;
      
      if (email != null && email.isNotEmpty) {
        loginEmail = email.trim().toLowerCase();
        print('DEBUG: Using provided email for login: $loginEmail');
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        print('DEBUG: Phone number provided. Looking up email for phone: $phoneNumber');
        final querySnapshot = await firebaseServices.getUserByPhoneNumber(phoneNumber);
        
        if (querySnapshot.docs.isEmpty) {
          print('DEBUG: No user found with phone number: $phoneNumber');
          return Left(AuthFailure(message: 'No account found with this phone number'));
        }
        
        final userDocData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        loginEmail = userDocData['email'] as String? ?? '';
        
        if (loginEmail.isEmpty) {
          print('DEBUG: User has no email address for authentication with phone: $phoneNumber');
          return Left(AuthFailure(message: 'User account does not have an email address'));
        }
        print('DEBUG: Found email $loginEmail for phone $phoneNumber');
      } else {
        print('DEBUG: No email or phone provided for login');
        return Left(AuthFailure(message: 'Email or phone number is required for login'));
      }
      
      try {
        print('DEBUG: Attempting to sign out before login to ensure clean state.');
        await firebaseServices.signOut();
        print('DEBUG: Sign out successful or ignored error.');
        
        print('DEBUG: Calling firebaseServices.auth.signInWithEmailAndPassword with email: $loginEmail');
        final UserCredential credential = await firebaseServices.auth.signInWithEmailAndPassword(
          email: loginEmail,
          password: password,
        );
        print('DEBUG: signInWithEmailAndPassword call successful. Credential received.');
        
        // Explicitly access credential.user and log
        final firebaseAuthUser = credential.user;
        print('DEBUG: Accessed credential.user. Type: ${firebaseAuthUser?.runtimeType}');
        
        if (firebaseAuthUser == null) {
          print('DEBUG: Firebase Auth succeeded but credential.user is null.');
          return Left(AuthFailure(message: 'Authentication succeeded but user data (credential.user) is missing'));
        }
        
        final String userId = firebaseAuthUser.uid;
        print('DEBUG: Successfully accessed firebaseUser.uid: $userId');
        
        print('DEBUG: Fetching user document from Firestore for UID: $userId');
        final userDoc = await firebaseServices.getUserDoc(userId);
        
        if (!userDoc.exists) {
          print('DEBUG: User authenticated with UID: $userId but no Firestore data found.');
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
        
        print('DEBUG: Converting Firestore data to User entity for UID: $userId');
        final userEntity = await _getUserFromFirestore(userData: firestoreUserData);
        print('DEBUG: Successfully converted Firestore data to User entity for UID: $userId. Email: ${userEntity.email}');
        
        // Cache authentication data
        await _cacheAuthenticationData(user: userEntity);
        
        // Check if player has pending payment
        if (userEntity.userType == 'player' && userEntity.paymentStatus == false) {
          logger.w('⚠️ Player login successful but payment is pending');
          // Still return success, but the UI will handle redirecting to payment
        }

        return Right(userEntity);
        
      } on FirebaseAuthException catch (e) {
        print('DEBUG: FirebaseAuthException caught: Code: ${e.code}, Message: ${e.message}');
        // Handle specific Firebase Auth errors based on e.code
        switch (e.code) {
          case 'user-not-found':
            return Left(AuthFailure(message: 'No account found with these credentials.'));
          case 'wrong-password':
            return Left(AuthFailure(message: 'The password you entered is incorrect.'));
          // Add other specific cases as needed
          default:
            return Left(AuthFailure(message: 'Firebase Auth Error: ${e.message ?? e.code}'));
        }
      } catch (e, s) {
        // This is where the PigeonUserDetails error is likely being caught if it's not a FirebaseAuthException
        print('DEBUG: Inner catch block in AuthRepositoryImpl.login: Error: ${e.toString()}, Stacktrace: $s');
        return Left(ServerFailure(message: 'Login failed due to an unexpected error: ${e.toString()}'));
      }
    } catch (e, s) {
      print('DEBUG: Outer catch block in AuthRepositoryImpl.login: Error: ${e.toString()}, Stacktrace: $s');
      return Left(ServerFailure(message: 'An unexpected error occurred during the login process: ${e.toString()}'));
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
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getUserById(userId);
        return Right(userModel.toEntity());
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      // Try to get from local cache if user ID matches current user
      try {
        final cachedUser = await localDataSource.getLastUser();
        if (cachedUser != null && cachedUser.id == userId) {
          return Right(cachedUser.toEntity());
        }
        return const Left(CacheFailure(message: 'User not available offline'));
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
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
        return Left(ServerFailure(message: 'No user found with this phone number'));
      }

      final userData = querySnapshot.docs.first.data();
      // Add document ID to user data
      userData['id'] = querySnapshot.docs.first.id;
      
      final email = userData['email'];

      logger.i('Found user with email: $email');

      if (email == null || email.toString().isEmpty) {
        return Left(ServerFailure(message: 'No email associated with this account'));
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
        return Left(ServerFailure(message: 'Error processing user data: ${e.toString()}'));
      }
    } catch (e) {
      logger.e('Error getting user by phone: ${e.toString()}');
      return Left(ServerFailure(message: 'Failed to get user: ${e.toString()}'));
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

  /// Get available communities
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
    if (await networkInfo.isConnected) {
      try {
        logger.i('🔄 Starting pending registration creation for: $email');
        
        // Prioritize Firestore write - this is critical
        final firestoreStartTime = DateTime.now();
        await firebaseServices.firestore
            .collection(_pendingRegistrationsCollection)
            .doc(email)
            .set({
              'fullName': fullName,
              'email': email,
              'phoneNumber': phoneNumber,
              'password': password, // Note: In production, consider hashing this
              'userType': userType ?? 'fan',
              'verificationCode': verificationCode,
              'emailVerified': false,
              'verified': false,
              'expires': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
              'timestamp': DateTime.now().toIso8601String(),
            }).timeout(
              const Duration(seconds: 10), // Reduced timeout for Firestore
              onTimeout: () => throw Exception('Firestore write timed out'),
            );
        
        final firestoreEndTime = DateTime.now();
        final firestoreDuration = firestoreEndTime.difference(firestoreStartTime);
        logger.i('⏱️ Firestore write completed in ${firestoreDuration.inMilliseconds}ms');
        
        // Make email sending completely non-blocking by using unawaited
        // This runs in the background and doesn't block the registration process
        (() async {
          try {
            final emailStartTime = DateTime.now();
            final emailSent = await emailService.sendVerificationEmail(
              email: email,
              fullName: fullName,
              verificationCode: verificationCode,
              userType: userType,
            ).timeout(
              const Duration(seconds: 15), // Separate timeout for email
              onTimeout: () {
                logger.w('⚠️ Email sending timed out for $email');
                return false;
              },
            );
            
            final emailEndTime = DateTime.now();
            final emailDuration = emailEndTime.difference(emailStartTime);
            logger.i('📧 Email sending ${emailSent ? 'completed' : 'failed'} in ${emailDuration.inMilliseconds}ms for $email');
            
            if (!emailSent) {
              logger.w('⚠️ Failed to send verification email to $email, but registration continues');
            }
          } catch (e) {
            logger.w('⚠️ Email sending failed but registration continues: $e');
          }
        })();
        
        logger.i('✅ Pending registration created successfully for $email (email sending in background)');
        
        return const Right(true);
      } catch (e) {
        logger.e('🔥 Failed to create pending registration: $e');
        return Left(ServerFailure(message: 'Failed to create pending registration: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  /// Verify an email for pending registration
  @override
  Future<Either<Failure, bool>> verifyPendingRegistration({
    required String email,
    required String verificationCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get the pending registration
        final pendingDoc = await firebaseServices.firestore
            .collection(_pendingRegistrationsCollection)
            .doc(email)
            .get();
        
        if (!pendingDoc.exists) {
          return const Left(AuthFailure(message: 'Verification failed: No pending registration found'));
        }
        
        final pendingData = pendingDoc.data()!;
        
        // Check if verification code matches
        if (pendingData['verificationCode'] != verificationCode) {
          return const Left(AuthFailure(message: 'Verification failed: Invalid verification code'));
        }
        
        // Check if verification has expired
        final expiryDate = DateTime.parse(pendingData['expires']);
        if (DateTime.now().isAfter(expiryDate)) {
          return const Left(AuthFailure(message: 'Verification failed: Verification link has expired'));
        }
        
        // FIXED: Mark email as verified, but keep verified=false until payment is completed
        await firebaseServices.firestore
            .collection(_pendingRegistrationsCollection)
            .doc(email)
            .update({
              'emailVerified': true,
              'emailVerifiedAt': DateTime.now().toIso8601String(),
              // 'verified' stays false until payment is completed
            });
        
        return const Right(true);
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to verify registration: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  /// Get pending registration data
  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistration({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get the pending registration
        final pendingDoc = await firebaseServices.firestore
            .collection(_pendingRegistrationsCollection)
            .doc(email)
            .get();
        
        if (!pendingDoc.exists) {
          return const Right(null);
        }
        
        return Right(pendingDoc.data()!);
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to get pending registration: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  /// Delete a pending registration
  @override
  Future<Either<Failure, bool>> deletePendingRegistration({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Delete the pending registration
        await firebaseServices.firestore
            .collection(_pendingRegistrationsCollection)
            .doc(email)
            .delete();
        
        return const Right(true);
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to delete pending registration: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, List<Community>>> getCommunities() async {
    if (await networkInfo.isConnected) {
      try {
        final communitiesData = await firebaseServices.firestore
            .collection('communities')
            .get();
            
        final List<Community> communityEntities = [];

        // Process the data from Firebase into dynamic entities
        for (var doc in communitiesData.docs) {
          if (doc.exists) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Add document ID to data
              
              // Create a Community object and add to the list
              final community = Community(
                id: data['id'] as String? ?? '',
                name: data['name'] as String? ?? 'Unknown',
                description: data['description'] as String? ?? 'No description',
                location: data['location'] as String? ?? '',
                imageUrl: data['imageUrl'] as String? ?? '',
                isActive: data['isActive'] as bool? ?? true,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
              communityEntities.add(community);
            } catch (e) {
              // Skip entities that can't be converted
              logger.e('Error processing community data: ${e.toString()}');
            }
          }
        }
        
        return Right(communityEntities);
      } catch (e) {
        logger.e('Error getting communities: ${e.toString()}');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  Future<Either<Failure, Community>> getCommunityDetails(String communityId) async {
    if (await networkInfo.isConnected) {
      try {
        final communityDoc = await firebaseServices.firestore
            .collection('communities')
            .doc(communityId)
            .get();
            
        if (!communityDoc.exists) {
          return Left(ServerFailure(message: 'Community not found'));
        }
        
        final data = communityDoc.data();
        if (data == null) {
          return Left(ServerFailure(message: 'Community data is null'));
        }
        
        // Add ID to the data
        data['id'] = communityId;
        
        // Create and return a Community object
        final community = Community(
          id: communityId,
          name: data['name'] as String? ?? 'Unknown',
          description: data['description'] as String? ?? 'No description',
          location: data['location'] as String? ?? '',
          imageUrl: data['imageUrl'] as String? ?? '',
          isActive: data['isActive'] as bool? ?? true,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
        return Right(community);
      } catch (e) {
        logger.e('Error getting community details: ${e.toString()}');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Check if a user exists with the given email (SMART CHECK)
  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      logger.i('🔍 Checking email existence for: $email');

      // STEP 1: Check for COMPLETE user registration (users collection)
      final userQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        final userData = userQuerySnapshot.docs.first.data();
        final isEmailVerified = userData['isEmailVerified'] as bool? ?? false;
        final userType = userData['userType'] as String? ?? 'fan';
        
        // For fans: if email verified, registration is complete
        if (userType == 'fan' && isEmailVerified) {
          logger.i('❌ Complete fan registration found for: $email');
          return const Right(true); // Email truly exists
        }
        
        // For players: check payment status too
        if (userType == 'player') {
          final paymentStatus = userData['paymentStatus'] as bool? ?? false;
          final playerPaymentStatus = userData['playerPaymentStatus'] as String? ?? '';
          
          // Check new boolean field first, then fallback to old enum
          final isPaymentComplete = paymentStatus || playerPaymentStatus == 'completed';
          
          if (isEmailVerified && isPaymentComplete) {
            logger.i('❌ Complete player registration found for: $email');
            return const Right(true); // Email truly exists
          } else {
            logger.i('⚠️ Incomplete player registration found for: $email (emailVerified: $isEmailVerified, paymentComplete: $isPaymentComplete)');
            // CLEANUP: Remove incomplete user record to allow retry
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userQuerySnapshot.docs.first.id)
                  .delete();
              logger.i('🗑️ Cleaned up incomplete user record for: $email');
            } catch (e) {
              logger.w('⚠️ Failed to cleanup incomplete user: $e');
            }
          }
        }
      }

      // STEP 2: Check for pending registration (pendingRegistrations collection)
      final pendingQuerySnapshot = await FirebaseFirestore.instance
          .collection('pendingRegistrations')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (pendingQuerySnapshot.docs.isNotEmpty) {
        final pendingData = pendingQuerySnapshot.docs.first.data();
        final expiryStr = pendingData['expiresAt'] as String?;
        final isExpired = expiryStr != null ? 
            DateTime.now().isAfter(DateTime.parse(expiryStr)) : true;

        if (isExpired) {
          logger.i('🗑️ Found expired pending registration for: $email, cleaning up');
          try {
            await FirebaseFirestore.instance
                .collection('pendingRegistrations')
                .doc(pendingQuerySnapshot.docs.first.id)
                .delete();
          } catch (e) {
            logger.w('⚠️ Failed to cleanup expired pending registration: $e');
          }
        } else {
          logger.i('⚠️ Found valid pending registration for: $email, allowing retry');
          // Allow the user to continue/retry their registration
        }
      }

      // STEP 3: Check Firebase Auth account (cleanup orphaned accounts)
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          logger.i('⚠️ Found Firebase Auth account without complete registration for: $email');
          
          // IMPORTANT: We found a Firebase Auth account but no complete Firestore data
          // This is an orphaned account from a previous incomplete registration attempt
          // We'll return false (email available) to allow the user to complete registration
          // The registration flow in firebase_auth_repository.dart will handle reusing
          // the existing Firebase Auth account if the password matches
          
          logger.i('✅ Allowing registration completion for orphaned account: $email');
          // Continue to return false below
        }
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found' && e.code != 'invalid-email') {
          logger.w('⚠️ Firebase Auth check failed for $email: ${e.message}');
        }
      }

      logger.i('✅ Email available for registration: $email');
      return const Right(false); // Email is available
      
    } catch (e) {
      logger.e('🔥 Error checking email existence: $e');
      return Left(ServerFailure(message: 'Failed to check email: ${e.toString()}'));
    }
  }

  /// Check if a user exists with the given phone number
  @override
  Future<Either<Failure, bool>> checkPhoneExists(String phoneNumber) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      logger.i('📱 Checking phone existence for: $phoneNumber');

      // Query for users with this phone number
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get(const GetOptions(source: Source.serverAndCache));

      if (querySnapshot.docs.isEmpty) {
        logger.i('✅ Phone number available: $phoneNumber');
        return const Right(false);
      }

      // Check if any of the found users have complete registrations
      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final isEmailVerified = userData['isEmailVerified'] as bool? ?? false;
        final userType = userData['userType'] as String? ?? 'fan';
        
        // For fans: if email verified, registration is complete
        if (userType == 'fan' && isEmailVerified) {
          logger.i('❌ Complete fan registration found for phone: $phoneNumber');
          return const Right(true); // Phone exists with complete registration
        }
        
        // For players: check payment status too
        if (userType == 'player') {
          final paymentStatus = userData['paymentStatus'] as bool? ?? false;
          final playerPaymentStatus = userData['playerPaymentStatus'] as String? ?? '';
          
          // Check new boolean field first, then fallback to old enum
          final isPaymentComplete = paymentStatus || playerPaymentStatus == 'completed';
          
          if (isEmailVerified && isPaymentComplete) {
            logger.i('❌ Complete player registration found for phone: $phoneNumber');
            return const Right(true); // Phone exists with complete registration
          }
        }
      }

      // If we get here, only incomplete registrations exist
      logger.i('⚠️ Only incomplete registrations found for phone: $phoneNumber, allowing new registration');
      return const Right(false); // Phone is available for new registration
      
    } catch (e) {
      logger.e('🔥 Error checking phone existence: $e');
      return Left(ServerFailure(message: 'Failed to check phone number: ${e.toString()}'));
    }
  }

  /// Check if a user's email is verified
  @override
  Future<Either<Failure, bool>> isEmailVerified(String email) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(false);
      }

      final userData = querySnapshot.docs.first.data();
      return Right(userData['isEmailVerified'] as bool? ?? false);
    } catch (e) {
      logger.e('Error checking email verification: $e');
      return Left(ServerFailure(message: 'Failed to check email verification: ${e.toString()}'));
    }
  }

  /// Update a pending registration
  @override
  Future<Either<Failure, bool>> updatePendingRegistration({
    required String email,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final docRef = firebaseServices.firestore
          .collection(_pendingRegistrationsCollection)
          .doc(email);
      
      await docRef.update(updates);
      
      return const Right(true);
    } catch (e) {
      logger.e('Error updating pending registration: $e');
      return Left(ServerFailure(message: 'Failed to update pending registration'));
    }
  }

  /// Check if email is verified (alias for isEmailVerified)
  Future<Either<Failure, bool>> checkEmailVerified(String email) async {
    return await isEmailVerified(email);
  }

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? fullName,
    String? email,
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

        // Cache the updated user data locally
        await _cacheUserData(user: userModel.toEntity());

        return Right(userModel.toEntity());
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

  /// Complete email verification and store tokens
  @override
  Future<Either<Failure, User>> completeEmailVerification({
    required String uid,
  }) async {
    try {
      logger.i('✅ Completing email verification for UID: $uid');
      
      // 1. Get current Firebase user
      final firebaseUser = firebaseServices.auth.currentUser;
      if (firebaseUser == null || firebaseUser.uid != uid) {
        return Left(AuthFailure(message: 'User session not found'));
      }
      
      // 2. Check if email is verified
      await firebaseUser.reload();
      if (!firebaseUser.emailVerified) {
        return Left(AuthFailure(message: 'Email not verified yet'));
      }
      
      // 3. Update Firestore user document
      await firebaseServices.firestore
          .collection('users')
          .doc(uid)
          .update({
        'isEmailVerified': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      // 4. Get updated user data
      final userDoc = await firebaseServices.firestore
          .collection('users')
          .doc(uid)
          .get();
          
      if (!userDoc.exists) {
        return Left(ServerFailure(message: 'User data not found'));
      }
      
      final userData = userDoc.data()!;
      userData['id'] = uid;
      
      // 5. Create user entity
      final user = await _getUserFromFirestore(userData: userData);
      
      // 6. Store authentication tokens
      await _cacheAuthenticationData(user: user);
      
      logger.i('✅ Email verification completed and tokens stored');
      
      return Right(user);
    } catch (e) {
      logger.e('🔥 Failed to complete email verification: $e');
      return Left(ServerFailure(message: 'Failed to complete verification: ${e.toString()}'));
    }
  }

  /// Clean up orphaned Firebase Auth account
  /// This is useful when a Firebase Auth account exists but no Firestore document
  Future<Either<Failure, bool>> cleanupOrphanedAccount({
    required String email,
    required String password,
  }) async {
    try {
      logger.i('🧹 Attempting to clean up orphaned account for: $email');
      
      // Try to sign in
      try {
        final credential = await firebaseServices.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        final user = credential.user;
        if (user != null) {
          // Check if Firestore document exists
          final userDoc = await firebaseServices.firestore
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (!userDoc.exists) {
            // Delete the orphaned Firebase Auth account
            await user.delete();
            logger.i('✅ Orphaned Firebase Auth account deleted for: $email');
            return const Right(true);
          } else {
            logger.i('⚠️ Account has Firestore data, not orphaned: $email');
            return Left(AuthFailure(message: 'Account is not orphaned, please login instead'));
          }
        }
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          logger.i('✅ No Firebase Auth account found for: $email');
          return const Right(false);
        } else if (e.code == 'wrong-password') {
          return Left(AuthFailure(message: 'Incorrect password'));
        } else {
          return Left(AuthFailure(message: e.message ?? 'Authentication failed'));
        }
      }
      
      return const Right(false);
    } catch (e) {
      logger.e('🔥 Failed to cleanup orphaned account: $e');
      return Left(ServerFailure(message: 'Cleanup failed: ${e.toString()}'));
    }
  }
}
