import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/services/logger_service.dart';
import 'models/user_model.dart';

/// Keys for SharedPreferences storage
class _Keys {
  static const String user = 'USER';
  static const String authToken = 'AUTH_TOKEN';
  static const String refreshToken = 'REFRESH_TOKEN';
  static const String tokenExpiry = 'TOKEN_EXPIRY';
  static const String userType = 'USER_TYPE';
}

/// Abstract class defining the contract for local data source operations
abstract class AuthLocalDataSource {
  /// Cache user data locally
  Future<void> cacheUser(UserModel user);

  /// Get cached user data
  Future<UserModel?> getLastUser();

  /// Clear all cached user data
  Future<void> clearUserCache();

  /// Cache authentication token with expiry time
  Future<void> cacheAuthToken(String token, DateTime expiryTime);

  /// Get cached authentication token
  Future<String?> getAuthToken();

  /// Check if the cached token is still valid
  Future<bool> isAuthTokenValid();

  /// Clear the authentication token
  Future<void> clearAuthToken();

  /// Cache refresh token
  Future<void> cacheRefreshToken(String refreshToken);

  /// Get cached refresh token
  Future<String?> getRefreshToken();

  /// Cache user type
  Future<void> cacheUserType(String userType);

  /// Get cached user type
  Future<String?> getUserType();
}

/// Implementation of AuthLocalDataSource using SharedPreferences
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final LoggerService logger;

  AuthLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.logger,
  });

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = user.toJson();
      await sharedPreferences.setString(_Keys.user, jsonEncode(userJson));
      logger.i('User cached successfully');
    } catch (e) {
      logger.e('Error caching user: $e');
      throw CacheException('Failed to cache user data');
    }
  }

  @override
  Future<UserModel?> getLastUser() async {
    try {
      final userString = sharedPreferences.getString(_Keys.user);
      if (userString != null) {
        final userJson = jsonDecode(userString) as Map<String, dynamic>;
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      logger.e('Error getting cached user: $e');
      return null;
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      await Future.wait([
        sharedPreferences.remove(_Keys.user),
        sharedPreferences.remove(_Keys.authToken),
        sharedPreferences.remove(_Keys.refreshToken),
        sharedPreferences.remove(_Keys.tokenExpiry),
        sharedPreferences.remove(_Keys.userType),
      ]);
      logger.i('User cache cleared successfully');
    } catch (e) {
      logger.e('Error clearing user cache: $e');
      throw CacheException('Failed to clear user cache');
    }
  }

  @override
  Future<void> cacheAuthToken(String token, DateTime expiryTime) async {
    try {
      await Future.wait([
        sharedPreferences.setString(_Keys.authToken, token),
        sharedPreferences.setString(
            _Keys.tokenExpiry, expiryTime.toIso8601String()),
      ]);
      logger.i('Auth token cached successfully');
    } catch (e) {
      logger.e('Error caching auth token: $e');
      throw CacheException('Failed to cache auth token');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return sharedPreferences.getString(_Keys.authToken);
    } catch (e) {
      logger.e('Error getting auth token: $e');
      return null;
    }
  }

  @override
  Future<bool> isAuthTokenValid() async {
    try {
      final token = sharedPreferences.getString(_Keys.authToken);
      final expiryString = sharedPreferences.getString(_Keys.tokenExpiry);

      if (token == null || expiryString == null) {
        return false;
      }

      final expiryTime = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      logger.e('Error checking token validity: $e');
      return false;
    }
  }

  @override
  Future<void> clearAuthToken() async {
    try {
      await Future.wait([
        sharedPreferences.remove(_Keys.authToken),
        sharedPreferences.remove(_Keys.tokenExpiry),
      ]);
      logger.i('Auth token cleared successfully');
    } catch (e) {
      logger.e('Error clearing auth token: $e');
      throw CacheException('Failed to clear auth token');
    }
  }

  @override
  Future<void> cacheRefreshToken(String refreshToken) async {
    try {
      await sharedPreferences.setString(_Keys.refreshToken, refreshToken);
      logger.i('Refresh token cached successfully');
    } catch (e) {
      logger.e('Error caching refresh token: $e');
      throw CacheException('Failed to cache refresh token');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(_Keys.refreshToken);
    } catch (e) {
      logger.e('Error getting refresh token: $e');
      return null;
    }
  }

  @override
  Future<void> cacheUserType(String userType) async {
    try {
      await sharedPreferences.setString(_Keys.userType, userType);
      logger.i('User type cached successfully');
    } catch (e) {
      logger.e('Error caching user type: $e');
      throw CacheException('Failed to cache user type');
    }
  }

  @override
  Future<String?> getUserType() async {
    try {
      return sharedPreferences.getString(_Keys.userType);
    } catch (e) {
      logger.e('Error getting user type: $e');
      return null;
    }
  }
}
