import 'package:equatable/equatable.dart';
import 'package:pool_billiard_app/core/error/exceptions.dart';

/// Enum for user types
enum UserType {
  fan,
  player,
  communityadmin,
}

/// Enum for payment statuses
enum PaymentStatus {
  initial,
  pending,
  processing,
  completed,
  success, // Alias for completed
  failed,
}

/// Entity representing a user
class User extends Equatable {
  final String id;
  final String email;
  final bool isEmailVerified;
  final String fullName;
  final String phoneNumber;
  final String userType;  // Keeping as String for compatibility
  final String? communityId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime registeredAt;
  final DateTime? playerSince;
  final bool isPhoneVerified;
  final PaymentStatus? playerPaymentStatus;
  final bool? paymentStatus;
  final String? playerPaymentId;
  final DateTime lastLoginAt;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.fullName,
    required this.phoneNumber,
    required this.userType,
    this.communityId,
    this.profileImageUrl,
    required this.createdAt,
    required this.registeredAt,
    this.playerSince,
    this.isPhoneVerified = false,
    this.playerPaymentStatus,
    this.paymentStatus,
    this.playerPaymentId,
    required this.lastLoginAt,
    this.isActive = true,
  });

  /// Check if user is a player
  bool get isPlayer => userType == 'player';

  /// Check if user is a fan
  bool get isFan => userType == 'fan';

  /// Check if user is a community admin
  bool get isCommunityAdmin => userType == 'communityadmin';

  /// Check if player has completed payment (use new boolean field if available)
  bool get hasCompletedPayment {
    if (paymentStatus != null) {
      return paymentStatus!;
    }
    // Fallback to old enum for backward compatibility
    return playerPaymentStatus == PaymentStatus.completed || 
           playerPaymentStatus == PaymentStatus.success;
  }

  /// Create a copy of this user with some fields updated
  User copyWith({
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
    return User(
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

  @override
  List<Object?> get props => [
        id,
        email,
        isEmailVerified,
        fullName,
        phoneNumber,
        userType,
        communityId,
        profileImageUrl,
        createdAt,
        registeredAt,
        playerSince,
        isPhoneVerified,
        playerPaymentStatus,
        paymentStatus,
        playerPaymentId,
        lastLoginAt,
        isActive,
      ];
      
  /// Create a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      final paymentStatusStr = json['playerPaymentStatus'] as String?;
      PaymentStatus? paymentStatus;
      
      if (paymentStatusStr != null) {
        paymentStatus = PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == paymentStatusStr,
          orElse: () => PaymentStatus.pending,
        );
      }
      
      return User(
        id: json['id'] as String,
        email: json['email'] as String,
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        userType: json['userType'] as String,
        communityId: json['communityId'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        registeredAt: json['registeredAt'] != null
            ? DateTime.parse(json['registeredAt'] as String)
            : DateTime.now(),
        playerSince: json['playerSince'] != null
            ? DateTime.parse(json['playerSince'] as String)
            : null,
        isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
        playerPaymentStatus: paymentStatus,
        paymentStatus: json['paymentStatus'] as bool?,
        playerPaymentId: json['playerPaymentId'] as String?,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.parse(json['lastLoginAt'] as String)
            : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );
    } catch (e) {
      throw ServerException('Failed to parse user data: $e');
    }
  }
  
  /// Convert user to JSON
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
}
