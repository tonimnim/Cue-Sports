import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pool_billiard_app/core/services/logger_service.dart';

/// Service for managing authentication tokens securely
class TokenService {
  final FlutterSecureStorage _storage;
  final LoggerService _logger;
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const Duration _tokenLifetime = Duration(days: 150); // 5 months

  TokenService({
    required FlutterSecureStorage storage,
    required LoggerService logger,
  })  : _storage = storage,
        _logger = logger;

  /// Save authentication token with expiry
  Future<void> saveToken(String token) async {
    try {
      // Validate token by decoding it
      JwtDecoder.decode(token);
      
      // Set expiry date to 5 months from now
      final expiryDate = DateTime.now().add(_tokenLifetime);
      
      // Save token and expiry
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryDate.toIso8601String(),
      );

      _logger.i('✅ Token saved successfully, expires: $expiryDate');
    } catch (e) {
      _logger.e('🔥 Failed to save token', e);
      throw Exception('Failed to save authentication token: $e');
    }
  }

  /// Get stored token if valid
  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        _logger.i('ℹ️ No token found');
        return null;
      }

      // Check if token is expired
      if (await isTokenExpired()) {
        _logger.w('⚠️ Token expired, clearing storage');
        await clearToken();
        return null;
      }

      return token;
    } catch (e) {
      _logger.e('🔥 Failed to get token', e);
      return null;
    }
  }

  /// Check if stored token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) return true;

      final expiry = DateTime.parse(expiryString);
      final isExpired = DateTime.now().isAfter(expiry);

      if (isExpired) {
        _logger.w('⚠️ Token expired on: $expiry');
      }

      return isExpired;
    } catch (e) {
      _logger.e('🔥 Failed to check token expiry', e);
      return true;
    }
  }

  /// Clear stored token and expiry
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      _logger.i('✅ Token cleared successfully');
    } catch (e) {
      _logger.e('🔥 Failed to clear token', e);
      throw Exception('Failed to clear authentication token: $e');
    }
  }

  /// Get token payload if valid
  Future<Map<String, dynamic>?> getTokenPayload() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      return JwtDecoder.decode(token);
    } catch (e) {
      _logger.e('🔥 Failed to decode token payload', e);
      return null;
    }
  }

  /// Get user ID from token if available
  Future<String?> getUserIdFromToken() async {
    try {
      final payload = await getTokenPayload();
      return payload?['sub'] as String?;
    } catch (e) {
      _logger.e('🔥 Failed to get user ID from token', e);
      return null;
    }
  }

  /// Check if user is authenticated with valid token
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && !(await isTokenExpired());
    } catch (e) {
      _logger.e('🔥 Failed to check authentication status', e);
      return false;
    }
  }
} 