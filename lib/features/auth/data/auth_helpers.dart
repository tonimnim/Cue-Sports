import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/logger_service.dart';
import '../../../firebase/firebase_services.dart';
import '../domain/entities/user.dart';
import 'auth_local_data_source.dart';
import 'models/user_model.dart';

/// Helper class for authentication related operations
class AuthHelpers {
  final LoggerService _logger;
  final FirebaseServices _firebaseServices;
  final AuthLocalDataSource _localDataSource;

  AuthHelpers({
    required LoggerService logger,
    required FirebaseServices firebaseServices,
    required AuthLocalDataSource localDataSource,
  })  : _logger = logger,
        _firebaseServices = firebaseServices,
        _localDataSource = localDataSource;

  /// Process and cache user data after successful login
  Future<void> processCachedUserData(
      UserModel userModel, Map<String, dynamic> loginResult) async {
    try {
      final token = loginResult['token'] as String? ?? 'firebase-token';
      final refreshToken = loginResult['refreshToken'] as String?;
      final expiryTime = loginResult['expiryTime'] as DateTime? ??
          DateTime.now().add(const Duration(days: 30));

      // Cache user data and tokens
      await _localDataSource.cacheUser(userModel);
      await _localDataSource.cacheAuthToken(token, expiryTime);
      if (refreshToken != null) {
        await _localDataSource.cacheRefreshToken(refreshToken);
      }

      _logger.i('🔐 Cached user data and tokens for ${userModel.email}');
    } catch (e) {
      _logger.e('❌ Error caching user data: $e');
      // Continue even if caching fails - this is not fatal
    }
  }

  /// Fetch user details from Firestore using uid
  Future<User?> getUserFromFirestore(String uid) async {
    try {
      _logger.i('🔍 Fetching user data from Firestore for uid: $uid');
      final userDoc =
          await _firebaseServices.firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        _logger.w('⚠️ No user document found in Firestore for uid: $uid');
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        _logger.w('⚠️ User document exists but has no data for uid: $uid');
        return null;
      }

      // Add uid to the user data
      userData['id'] = uid;

      try {
        // Try to convert to UserModel
        final userModel = UserModel.fromJson(userData);
        _logger.i(
            '✅ Successfully loaded user data from Firestore: ${userModel.email}');
        return userModel.toEntity();
      } catch (e) {
        _logger.e('❌ Error converting Firestore data to UserModel: $e');

        // Create minimal User entity as fallback
        final email = userData['email'] as String?;
        if (email != null && email.isNotEmpty) {
          final now = DateTime.now();
          return User(
            id: uid,
            fullName: (userData['fullName'] as String?) ?? 'Unknown User',
            email: email,
            phoneNumber: (userData['phoneNumber'] as String?) ?? '',
            userType: (userData['userType'] as String?) ?? 'fan',
            createdAt: (userData['createdAt'] is Timestamp)
                ? (userData['createdAt'] as Timestamp).toDate()
                : now,
            registeredAt: (userData['registeredAt'] is Timestamp)
                ? (userData['registeredAt'] as Timestamp).toDate()
                : now,
            isEmailVerified: (userData['isEmailVerified'] as bool?) ?? false,
            lastLoginAt: (userData['lastLoginAt'] is Timestamp)
                ? (userData['lastLoginAt'] as Timestamp).toDate()
                : now,
          );
        }
      }

      return null;
    } catch (e) {
      _logger.e('❌ Error fetching user from Firestore: $e');
      return null;
    }
  }

  /// Process Firebase login result to handle different response formats
  Future<User?> processLoginResult(Map<String, dynamic> loginResult) async {
    try {
      final userModel = loginResult['user'];
      if (userModel == null) {
        _logger.e('❌ User model is null in login result');
        return null;
      }

      if (userModel is UserModel) {
        await processCachedUserData(userModel, loginResult);
        return userModel.toEntity();
      }

      // Try to handle the data even if it's not the expected type
      if (userModel is Map<String, dynamic>) {
        _logger.i('🔄 Attempting to convert Map to UserModel');
        final convertedUserModel = UserModel.fromJson(userModel);
        await processCachedUserData(convertedUserModel, loginResult);
        return convertedUserModel.toEntity();
      }

      // Check if we have a Firebase Auth user even if result processing failed
      final currentUser = _firebaseServices.auth.currentUser;
      if (currentUser != null) {
        _logger.i('🔄 Using Firebase currentUser as fallback');
        return await getUserFromFirestore(currentUser.uid);
      }

      return null;
    } catch (e) {
      _logger.e('❌ Error processing login result: $e');
      return null;
    }
  }
}
