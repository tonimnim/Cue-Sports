import '../../domain/entities/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for users
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required bool isEmailVerified,
    required String fullName,
    required String phoneNumber,
    required String userType,
    String? communityId,
    String? profileImageUrl,
    required DateTime createdAt,
    required DateTime registeredAt,
    DateTime? playerSince,
    bool isPhoneVerified = false,
    PaymentStatus? playerPaymentStatus,
    bool? paymentStatus,
    String? playerPaymentId,
    required DateTime lastLoginAt,
    bool isActive = true,
  }) : super(
          id: id,
          email: email,
          isEmailVerified: isEmailVerified,
          fullName: fullName,
          phoneNumber: phoneNumber,
          userType: userType,
          communityId: communityId,
          profileImageUrl: profileImageUrl,
          createdAt: createdAt,
          registeredAt: registeredAt,
          playerSince: playerSince,
          isPhoneVerified: isPhoneVerified,
          playerPaymentStatus: playerPaymentStatus,
          paymentStatus: paymentStatus,
          playerPaymentId: playerPaymentId,
          lastLoginAt: lastLoginAt,
          isActive: isActive,
        );

  /// Create a UserModel from a map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      fullName: json['fullName'] as String? ?? 'Unknown User',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      userType: json['userType'] as String? ?? 'fan',
      communityId: json['communityId'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? _parseDateTime(json['registeredAt']) ?? now,
      registeredAt: _parseDateTime(json['registeredAt']) ?? now,
      playerSince: _parseDateTime(json['playerSince']),
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      playerPaymentStatus: _paymentStatusFromString(json['playerPaymentStatus']),
      paymentStatus: json['paymentStatus'] as bool?,
      playerPaymentId: json['playerPaymentId'] as String?,
      lastLoginAt: _parseDateTime(json['lastLoginAt']) ?? now,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        print('DEBUG: Unexpected date type in UserModel: ${dateValue.runtimeType}');
        return null;
      }
    } catch (e) {
      print('DEBUG: Failed to parse date value in UserModel: $dateValue, error: $e');
      return null;
    }
  }

  /// Helper method to convert string to PaymentStatus enum
  static PaymentStatus? _paymentStatusFromString(String? status) {
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

  /// Convert to JSON map for Firebase storage
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'communityId': communityId,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'registeredAt': registeredAt.toIso8601String(),
      'playerSince': playerSince?.toIso8601String(),
      'isPhoneVerified': isPhoneVerified,
      'playerPaymentStatus': playerPaymentStatus?.toString().split('.').last,
      'paymentStatus': paymentStatus,
      'playerPaymentId': playerPaymentId,
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy of this model with some fields updated
  @override
  UserModel copyWith({
    String? id,
    String? email,
    bool? isEmailVerified,
    String? fullName,
    String? phoneNumber,
    String? userType,
    String? communityId,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? registeredAt,
    DateTime? playerSince,
    bool? isPhoneVerified,
    PaymentStatus? playerPaymentStatus,
    bool? paymentStatus,
    String? playerPaymentId,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      communityId: communityId ?? this.communityId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      registeredAt: registeredAt ?? this.registeredAt,
      playerSince: playerSince ?? this.playerSince,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      playerPaymentStatus: playerPaymentStatus ?? this.playerPaymentStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      playerPaymentId: playerPaymentId ?? this.playerPaymentId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert this model to an entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      isEmailVerified: isEmailVerified,
      fullName: fullName,
      phoneNumber: phoneNumber,
      userType: userType,
      communityId: communityId,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      registeredAt: registeredAt,
      playerSince: playerSince,
      isPhoneVerified: isPhoneVerified,
      playerPaymentStatus: playerPaymentStatus,
      paymentStatus: paymentStatus,
      playerPaymentId: playerPaymentId,
      lastLoginAt: lastLoginAt,
      isActive: isActive,
    );
  }

  /// Create a new fan user
  factory UserModel.newFanUser({
    required String id,
    required String fullName,
    required String email,
    required String phoneNumber,
    bool isEmailVerified = false,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      userType: 'fan',
      createdAt: now,
      registeredAt: now,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: false,
      isActive: true,
      lastLoginAt: now,
    );
  }

  /// Create a new player user
  factory UserModel.newPlayerUser({
    required String id,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String communityId,
    required String paymentId,
    bool isEmailVerified = false,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      userType: 'player',
      createdAt: now,
      registeredAt: now,
      playerSince: now,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: false,
      isActive: true,
      lastLoginAt: now,
      communityId: communityId,
      playerPaymentStatus: PaymentStatus.pending,
      paymentStatus: false,
      playerPaymentId: paymentId,
    );
  }
} 