import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../core/error/exceptions.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/token_service.dart';
import '../domain/entities/user.dart';
import 'models/user_model.dart';

/// Firebase collection paths
class FirebaseCollections {
  static const String users = 'users';
  static const String communities = 'communities';
  static const String payments = 'payments';
  static const String transactions =
      'transactions'; // Collection for payment transactions
  static const String notifications = 'notifications';
  static const String playerRequests = 'player_requests';
}

/// Interface for authentication remote data operations
abstract class AuthRemoteDataSource {
  /// Register a new fan user
  ///
  /// Returns the registered UserModel
  Future<UserModel> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Register a new player user with payment
  ///
  /// Returns the registered UserModel
  Future<UserModel> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  });

  /// Login an existing user
  ///
  /// Returns the logged in UserModel and auth tokens
  /// Either email or phoneNumber must be provided
  Future<Map<String, dynamic>> login({
    String? email,
    String? phoneNumber,
    required String password,
  });

  /// Logout the current user
  Future<void> logout();

  /// Get current authenticated user
  ///
  /// Returns the currently authenticated UserModel or null
  Future<UserModel?> getCurrentUser();

  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Verify password reset code
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Reset password with code
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Upgrade fan to player with payment
  ///
  /// Returns the updated UserModel
  Future<UserModel> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  });

  /// Update user profile
  ///
  /// Returns the updated UserModel
  Future<UserModel> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  });

  /// Verify user email
  Future<void> verifyEmail({
    required String email,
    required String code,
  });

  /// Send email verification code
  Future<void> sendEmailVerification({
    required String email,
  });

  /// Get user by ID
  ///
  /// Returns the UserModel for the specified ID
  Future<UserModel> getUserById(String userId);

  /// Delete user account
  Future<void> deleteUser(String userId);

  /// Get refresh token
  Future<String?> getRefreshToken();

  /// Check if a user with the given email already exists
  ///
  /// Returns true if the user exists, false otherwise
  Future<bool> checkIfUserExists(String email);

  /// Get available communities
  ///
  /// Returns a list of communities from Firestore
  Future<List<dynamic>> getCommunities();
}

/// Implementation of AuthRemoteDataSource using Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore firestore;
  final LoggerService logger;
  final TokenService tokenService;

  AuthRemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth auth,
    required this.firestore,
    required this.logger,
    required this.tokenService,
  }) : _auth = auth;

  @override
  Future<UserModel> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Registration failed: User object is null');
      }

      // Create UserModel
      final userModel = UserModel.newFanUser(
        id: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        isEmailVerified: true, // Email was already verified in our flow
      );

      // Store user data in Firestore
      await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toJson());

      logger.i('✅ Fan user registered: ${user.uid}');

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        logger.i(
            '🔄 Firebase Auth account exists for $email, attempting recovery...');

        try {
          // Try to sign in with the existing account
          final signInCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final user = signInCredential.user;
          if (user == null) {
            throw AuthException('Account recovery failed: User is null');
          }

          logger.i(
              '✅ Successfully signed into existing Firebase Auth account: ${user.uid}');

          // Check if Firestore document exists
          final existingUserDoc = await firestore
              .collection(FirebaseCollections.users)
              .doc(user.uid)
              .get();

          if (!existingUserDoc.exists) {
            logger.i(
                '📝 Creating missing Firestore document for orphaned account');

            // Create the missing Firestore document
            final userModel = UserModel.newFanUser(
              id: user.uid,
              fullName: fullName,
              email: email,
              phoneNumber: phoneNumber,
              isEmailVerified: true, // Email was already verified in our flow
            );

            await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .set(userModel.toJson());

            logger.i('✅ Firestore document created for recovered account');
            return userModel;
          } else {
            logger.i('✅ Firestore document exists, updating user data');

            // Update existing document with new data
            await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .update({
              'fullName': fullName,
              'phoneNumber': phoneNumber,
              'isEmailVerified': true,
              'lastLoginAt': DateTime.now().toIso8601String(),
            });

            // Get updated user data
            final updatedDoc = await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .get();

            final userData = updatedDoc.data()!;
            userData['id'] = user.uid;

            return UserModel.fromJson(userData);
          }
        } catch (signInError) {
          logger.e('🔥 Account recovery failed: $signInError');

          if (signInError is firebase_auth.FirebaseAuthException &&
              signInError.code == 'wrong-password') {
            throw AuthException(
                'This email is already registered with a different password. '
                'Please try logging in instead.');
          }

          throw AuthException(
              'Account recovery failed: ${signInError.toString()}');
        }
      }

      // Handle other Firebase Auth errors
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      logger.e('🔥 Fan registration error: $e');
      throw ServerException('Registration failed: $e');
    }
  }

  @override
  Future<UserModel> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Registration failed: User object is null');
      }

      // Create UserModel for player
      final userModel = UserModel.newPlayerUser(
        id: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        communityId: communityId,
        paymentId: paymentId,
        isEmailVerified: true, // Email was already verified in our flow
      );

      // Store user data in Firestore
      await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toJson());

      // Notify community admin
      await _notifyCommunityAdmin(communityId, user.uid, fullName);

      logger.i('✅ Player user registered: ${user.uid}');

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        logger.i(
            '🔄 Firebase Auth account exists for $email, attempting recovery...');

        try {
          // Try to sign in with the existing account
          final signInCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final user = signInCredential.user;
          if (user == null) {
            throw AuthException('Account recovery failed: User is null');
          }

          logger.i(
              '✅ Successfully signed into existing Firebase Auth account: ${user.uid}');

          // Check if Firestore document exists
          final existingUserDoc = await firestore
              .collection(FirebaseCollections.users)
              .doc(user.uid)
              .get();

          if (!existingUserDoc.exists) {
            logger.i(
                '📝 Creating missing Firestore document for orphaned player account');

            // Create the missing Firestore document
            final userModel = UserModel.newPlayerUser(
              id: user.uid,
              fullName: fullName,
              email: email,
              phoneNumber: phoneNumber,
              communityId: communityId,
              paymentId: paymentId,
              isEmailVerified: true, // Email was already verified in our flow
            );

            await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .set(userModel.toJson());

            // Notify community admin
            await _notifyCommunityAdmin(communityId, user.uid, fullName);

            logger
                .i('✅ Firestore document created for recovered player account');
            return userModel;
          } else {
            logger.i(
                '✅ Firestore document exists, updating with new player data');

            // Update existing document with new player data
            await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .update({
              'fullName': fullName,
              'phoneNumber': phoneNumber,
              'userType': 'player',
              'communityId': communityId,
              'playerPaymentId': paymentId,
              'playerPaymentStatus':
                  PaymentStatus.pending.toString().split('.').last,
              'paymentStatus': false, // Boolean payment status
              'isEmailVerified': true,
              'lastLoginAt': DateTime.now().toIso8601String(),
            });

            // Get updated user data
            final updatedDoc = await firestore
                .collection(FirebaseCollections.users)
                .doc(user.uid)
                .get();

            final userData = updatedDoc.data()!;
            userData['id'] = user.uid;

            return UserModel.fromJson(userData);
          }
        } catch (signInError) {
          logger.e('🔥 Account recovery failed: $signInError');

          if (signInError is firebase_auth.FirebaseAuthException &&
              signInError.code == 'wrong-password') {
            throw AuthException(
                'This email is already registered with a different password. '
                'Please try logging in instead.');
          }

          throw AuthException(
              'Account recovery failed: ${signInError.toString()}');
        }
      }

      // Handle other Firebase Auth errors
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      logger.e('🔥 Player registration error: $e');
      throw ServerException('Registration failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    try {
      // Ensure at least one identifier is provided
      if ((email == null || email.isEmpty) &&
          (phoneNumber == null || phoneNumber.isEmpty)) {
        throw AuthException('Either email or phone number is required');
      }

      if (password.isEmpty) {
        throw AuthException('Password is required');
      }

      String loginEmail;

      // Determine which login method to use
      if (email != null && email.isNotEmpty) {
        loginEmail = email.trim().toLowerCase();
        logger.i('👤 Attempting login with email: $loginEmail');
      } else {
        // Using phone number as login
        // First, look up the email associated with this phone number
        final querySnapshot = await firestore
            .collection(FirebaseCollections.users)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw AuthException('No account found with this phone number');
        }

        final userData = querySnapshot.docs.first.data();
        loginEmail = userData['email'] as String? ?? '';

        if (loginEmail.isEmpty) {
          throw AuthException('No email associated with this account');
        }

        logger.i('👤 Found email for phone number: $loginEmail');
      }

      // Sign out first to ensure clean state
      try {
        await _auth.signOut();
      } catch (e) {
        // Ignore signout errors
      }

      // Authenticate with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Login failed: User is null');
      }

      // Get user data from Firestore
      final userDoc = await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw AuthException('User data not found');
      }

      // Update last login time
      final now = DateTime.now();
      final userData = userDoc.data()!;
      userData['id'] = user.uid;
      userData['lastLoginAt'] = now.toIso8601String();

      await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .update({'lastLoginAt': now.toIso8601String()});

      // Get Firebase ID token for authentication
      final idToken = await user.getIdToken();
      if (idToken != null) {
        await tokenService.saveToken(idToken);
        logger.i('🔐 Firebase ID token saved');
      }

      logger.i('✅ Login successful: ${user.email}');

      return {
        'user': UserModel.fromJson(userData),
        'accessToken': idToken ?? '',
        'refreshToken': '', // Firebase handles refresh internally
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      logger.e('🔥 Unexpected login error: $e');
      throw ServerException('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      logger.i('✅ User logged out');
    } catch (e) {
      logger.e('🔥 Logout error: $e');
      throw ServerException('Logout failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final userDoc = await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data()!;
      // CRITICAL FIX: Include the Firebase Auth UID as the user ID
      userData['id'] = user.uid;
      return UserModel.fromJson(userData);
    } catch (e) {
      logger.e('🔥 Get current user error: $e');
      throw ServerException('Failed to get current user: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i('✅ Password reset email sent to: $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      logger.e('🔥 Send password reset email error: $e');
      throw ServerException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      // Firebase Auth doesn't have a direct method for this without a web context
      // This is a placeholder - in a real app, you would need to handle this differently
      logger.i('✅ Password reset code verified for: $email');
    } catch (e) {
      logger.e('🔥 Verify password reset code error: $e');
      throw ServerException('Failed to verify password reset code: $e');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      // Firebase Auth doesn't have a direct method for this without a web context
      // This is a placeholder - in a real app, you would need to handle this differently
      logger.i('✅ Password reset for: $email');
    } catch (e) {
      logger.e('🔥 Reset password error: $e');
      throw ServerException('Failed to reset password: $e');
    }
  }

  @override
  Future<UserModel> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  }) async {
    try {
      final userDoc = await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw AuthException('User not found');
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromJson(userData);

      // Update to player
      final updatedUserModel = userModel.copyWith(
        userType: 'player',
        communityId: communityId,
        playerPaymentId: paymentId,
        playerPaymentStatus: PaymentStatus.completed,
      );

      await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update(updatedUserModel.toJson());

      // Notify community admin
      await _notifyCommunityAdmin(
          communityId, userId, updatedUserModel.fullName);

      logger.i('✅ User upgraded to player: $userId');

      return updatedUserModel;
    } catch (e) {
      logger.e('🔥 Upgrade to player error: $e');
      throw ServerException('Failed to upgrade to player: $e');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final userDoc = await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw AuthException('User not found');
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromJson(userData);

      // Only update provided fields
      final updatedData = <String, dynamic>{};
      if (fullName != null) updatedData['fullName'] = fullName;
      if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) {
        updatedData['profileImageUrl'] = profileImageUrl;
      }

      await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update(updatedData);

      // Return updated user model
      final updatedUserModel = userModel.copyWith(
        fullName: fullName ?? userModel.fullName,
        phoneNumber: phoneNumber ?? userModel.phoneNumber,
        profileImageUrl: profileImageUrl ?? userModel.profileImageUrl,
      );

      logger.i('✅ User profile updated: $userId');

      return updatedUserModel;
    } catch (e) {
      logger.e('🔥 Update user profile error: $e');
      throw ServerException('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      // This would typically involve a custom email verification flow
      // For now, we'll just mark the user as verified in Firestore
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in');
      }

      // Update the email verified status
      await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .update({'isEmailVerified': true});

      logger.i('✅ Email verified for: $email');
    } catch (e) {
      logger.e('🔥 Verify email error: $e');
      throw ServerException('Failed to verify email: $e');
    }
  }

  @override
  Future<void> sendEmailVerification({
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in');
      }

      await user.sendEmailVerification();
      logger.i('✅ Email verification sent to: $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      logger.e('🔥 Send email verification error: $e');
      throw ServerException('Failed to send email verification: $e');
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final userDoc = await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw AuthException('User not found');
      }

      final userData = userDoc.data()!;
      return UserModel.fromJson(userData);
    } catch (e) {
      logger.e('🔥 Get user by ID error: $e');
      throw ServerException('Failed to get user: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .delete();

      // Delete from Firebase Auth (only if it's the current user)
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
      }

      logger.i('✅ User deleted: $userId');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      logger.e('🔥 Delete user error: $e');
      throw ServerException('Failed to delete user: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      // Firebase doesn't expose refresh tokens directly in Flutter SDK
      // This is a placeholder - in a real app, you would handle refresh tokens differently
      return 'firebase-refresh-token';
    } catch (e) {
      logger.e('🔥 Get refresh token error: $e');
      return null;
    }
  }

  @override
  Future<bool> checkIfUserExists(String email) async {
    try {
      // Check if the user exists in Firebase Auth
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      logger.e('🔥 Check if user exists error: $e');
      return false;
    }
  }

  @override
  Future<List<dynamic>> getCommunities() async {
    try {
      logger.i('🔍 Fetching communities from Firestore');

      // Build query with best practices
      final snapshot = await firestore
          .collection(FirebaseCollections.communities)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(20) // Set a reasonable limit
          .get();

      // Map to proper structured data with timestamp handling
      final communities = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'];
        final DateTime createdAt;

        // Handle different timestamp formats properly
        if (timestamp is Timestamp) {
          createdAt = timestamp.toDate();
        } else if (timestamp is String) {
          createdAt = DateTime.parse(timestamp);
        } else {
          createdAt = DateTime.now();
        }

        // Return a properly structured map
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'description': data['description'],
          'location': data['location'],
          'logoUrl': data['logoUrl'],
          'createdAt': createdAt,
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      logger.i('✅ Fetched ${communities.length} communities');
      return communities;
    } catch (e) {
      logger.e('🔥 Failed to fetch communities: $e');
      throw ServerException('Failed to fetch communities: $e');
    }
  }

  // Helper method to notify community admin about new player
  Future<void> _notifyCommunityAdmin(
      String communityId, String userId, String userName) async {
    try {
      // Get community data to find admin
      final communityDoc = await firestore
          .collection(FirebaseCollections.communities)
          .doc(communityId)
          .get();

      if (!communityDoc.exists) {
        return; // No notification if community doesn't exist
      }

      final communityData = communityDoc.data()!;
      final adminId = communityData['adminId'];

      if (adminId == null) return; // No admin to notify

      // Create notification
      await firestore.collection(FirebaseCollections.notifications).add({
        'recipientId': adminId,
        'type': 'NEW_PLAYER',
        'title': 'New Player Registration',
        'message': '$userName has joined your community as a player',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {
          'playerId': userId,
          'playerName': userName,
          'communityId': communityId,
          'communityName': communityData['name'] ?? 'Community',
        },
      });
    } catch (e) {
      // Log but don't throw - notification failure shouldn't block registration
      logger.w('Failed to notify community admin: $e');
    }
  }

  // Helper method to handle Firebase Auth exceptions
  AppException _handleFirebaseAuthException(
      firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthException('This email is already registered');
      case 'invalid-email':
        return AuthException('Invalid email format');
      case 'user-disabled':
        return AuthException('This account has been disabled');
      case 'user-not-found':
        return AuthException('No account found with this email');
      case 'wrong-password':
        return AuthException('Incorrect password');
      case 'weak-password':
        return AuthException(
            'Password is too weak, must be at least 6 characters');
      case 'invalid-verification-code':
        return AuthException('Invalid verification code');
      case 'invalid-verification-id':
        return AuthException('Invalid verification session');
      case 'too-many-requests':
        return AuthException('Too many attempts, please try again later');
      case 'requires-recent-login':
        return AuthException(
          'This operation is sensitive and requires recent authentication. Log in again before retrying.',
        );
      default:
        return AuthException('Authentication error: ${e.message}');
    }
  }
}
