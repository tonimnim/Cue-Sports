import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

/// Service for securely storing sensitive data locally
class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  final LoggerService _logger;
  
  SecureStorageService({required LoggerService logger}) : _logger = logger;

  // Storage Keys
  static const String _registrationDraftKey = 'registration_draft';
  static const String _authTokensKey = 'auth_tokens';
  static const String _cachedUserKey = 'cached_user';

  /// Save registration draft
  Future<void> saveRegistrationDraft(RegistrationDraft draft) async {
    try {
      final jsonString = jsonEncode(draft.toJson());
      await _secureStorage.write(key: _registrationDraftKey, value: jsonString);
      _logger.i('📝 Registration draft saved: ${draft.email}');
    } catch (e) {
      _logger.e('🔥 Failed to save registration draft: $e');
      throw Exception('Failed to save registration draft');
    }
  }

  /// Get registration draft
  Future<RegistrationDraft?> getRegistrationDraft() async {
    try {
      final jsonString = await _secureStorage.read(key: _registrationDraftKey);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final draft = RegistrationDraft.fromJson(json);
      
      // Check if draft is expired (7 days)
      final now = DateTime.now();
      if (now.difference(draft.timestamp).inDays > 7) {
        _logger.w('⏰ Registration draft expired, cleaning up');
        await clearRegistrationDraft();
        return null;
      }
      
      return draft;
    } catch (e) {
      _logger.e('🔥 Failed to get registration draft: $e');
      return null;
    }
  }

  /// Clear registration draft
  Future<void> clearRegistrationDraft() async {
    try {
      await _secureStorage.delete(key: _registrationDraftKey);
      _logger.i('🗑️ Registration draft cleared');
    } catch (e) {
      _logger.e('🔥 Failed to clear registration draft: $e');
    }
  }

  /// Save authentication tokens
  Future<void> saveAuthTokens(AuthTokens tokens) async {
    try {
      final jsonString = jsonEncode(tokens.toJson());
      await _secureStorage.write(key: _authTokensKey, value: jsonString);
      _logger.i('🔐 Auth tokens saved');
    } catch (e) {
      _logger.e('🔥 Failed to save auth tokens: $e');
      throw Exception('Failed to save authentication tokens');
    }
  }

  /// Get authentication tokens
  Future<AuthTokens?> getAuthTokens() async {
    try {
      final jsonString = await _secureStorage.read(key: _authTokensKey);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(json);
      
      // Check if tokens are expired (5 months)
      final now = DateTime.now();
      if (now.isAfter(tokens.expiresAt)) {
        _logger.w('⏰ Auth tokens expired, cleaning up');
        await clearAuthTokens();
        return null;
      }
      
      return tokens;
    } catch (e) {
      _logger.e('🔥 Failed to get auth tokens: $e');
      return null;
    }
  }

  /// Clear authentication tokens
  Future<void> clearAuthTokens() async {
    try {
      await _secureStorage.delete(key: _authTokensKey);
      _logger.i('🗑️ Auth tokens cleared');
    } catch (e) {
      _logger.e('🔥 Failed to clear auth tokens: $e');
    }
  }

  /// Save cached user data
  Future<void> saveCachedUser(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await _secureStorage.write(key: _cachedUserKey, value: jsonString);
      _logger.i('👤 User data cached');
    } catch (e) {
      _logger.e('🔥 Failed to cache user data: $e');
    }
  }

  /// Get cached user data
  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final jsonString = await _secureStorage.read(key: _cachedUserKey);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('🔥 Failed to get cached user: $e');
      return null;
    }
  }

  /// Clear cached user data
  Future<void> clearCachedUser() async {
    try {
      await _secureStorage.delete(key: _cachedUserKey);
      _logger.i('🗑️ Cached user data cleared');
    } catch (e) {
      _logger.e('🔥 Failed to clear cached user: $e');
    }
  }

  /// Clear all stored data (logout/reset)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      _logger.i('🧹 All secure storage cleared');
    } catch (e) {
      _logger.e('🔥 Failed to clear all storage: $e');
    }
  }

  /// Check if user is potentially logged in
  Future<bool> hasValidSession() async {
    final tokens = await getAuthTokens();
    return tokens != null;
  }
}

/// Model for registration draft
class RegistrationDraft {
  final String draftType; // 'fan' or 'player'
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String? communityId; // Only for players
  final String? paymentId; // Only for players
  final String? uid; // Firebase Auth UID
  final String step; // Current step in registration
  final DateTime timestamp;

  const RegistrationDraft({
    required this.draftType,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.communityId,
    this.paymentId,
    this.uid,
    required this.step,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'draftType': draftType,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'password': password,
    'communityId': communityId,
    'paymentId': paymentId,
    'uid': uid,
    'step': step,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) => RegistrationDraft(
    draftType: json['draftType'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    phoneNumber: json['phoneNumber'] as String,
    password: json['password'] as String,
    communityId: json['communityId'] as String?,
    paymentId: json['paymentId'] as String?,
    uid: json['uid'] as String?,
    step: json['step'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  RegistrationDraft copyWith({
    String? draftType,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? communityId,
    String? paymentId,
    String? uid,
    String? step,
    DateTime? timestamp,
  }) => RegistrationDraft(
    draftType: draftType ?? this.draftType,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    password: password ?? this.password,
    communityId: communityId ?? this.communityId,
    paymentId: paymentId ?? this.paymentId,
    uid: uid ?? this.uid,
    step: step ?? this.step,
    timestamp: timestamp ?? this.timestamp,
  );
}

/// Model for authentication tokens
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String uid;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.uid,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'uid': uid,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    uid: json['uid'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  /// Check if tokens expire within the next hour
  bool get isExpiringSoon {
    final oneHourFromNow = DateTime.now().add(const Duration(hours: 1));
    return expiresAt.isBefore(oneHourFromNow);
  }

  /// Check if tokens are expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }
} 