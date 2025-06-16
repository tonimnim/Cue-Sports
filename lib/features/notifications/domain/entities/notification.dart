import 'package:equatable/equatable.dart';

/// Notification priority levels
enum NotificationPriority {
  low,
  medium,
  high,
}

/// Notification categories
enum NotificationCategory {
  all,
  community,
  tournament,
  payment,
  shop,
  admin,
  match,
  system,
}

/// Notification actions that can be triggered
enum NotificationAction {
  openCommunity,
  openTournament,
  registerTournament,
  viewMatchDetails,
  viewOrder,
  openPaymentHistory,
  upgradeToPlayer,
  viewCommunityMembers,
  viewTournament,
  viewMatch,
  viewCommunity,
  none,
  custom,
}

/// Notification entity representing a user notification
class NotificationEntity extends Equatable {
  final String id;
  final String recipientId;
  final String recipientType; // 'player', 'fan', 'user'
  final String type; // e.g., 'COMMUNITY_UPDATE', 'PAYMENT_SUCCESS'
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final NotificationPriority priority;
  final NotificationCategory category;
  final Map<String, dynamic> data;
  final NotificationAction? action;

  const NotificationEntity({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.priority,
    required this.category,
    required this.data,
    this.action,
  });

  /// Create a copy of this notification with some fields updated
  NotificationEntity copyWith({
    String? id,
    String? recipientId,
    String? recipientType,
    String? type,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    NotificationPriority? priority,
    NotificationCategory? category,
    Map<String, dynamic>? data,
    NotificationAction? action,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      data: data ?? this.data,
      action: action ?? this.action,
    );
  }

  /// Mark notification as read
  NotificationEntity markAsRead() {
    return copyWith(read: true);
  }

  /// Mark notification as unread
  NotificationEntity markAsUnread() {
    return copyWith(read: false);
  }

  /// Check if notification is high priority
  bool get isHighPriority => priority == NotificationPriority.high;

  /// Check if notification is related to community
  bool get isCommunityNotification =>
      category == NotificationCategory.community;

  /// Check if notification is related to tournament
  bool get isTournamentNotification =>
      category == NotificationCategory.tournament;

  /// Check if notification is related to payment
  bool get isPaymentNotification => category == NotificationCategory.payment;

  /// Get time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Convert notification type string to NotificationAction
  static NotificationAction? actionFromString(String? actionString) {
    if (actionString == null) return null;

    switch (actionString) {
      case 'open_community':
        return NotificationAction.openCommunity;
      case 'open_tournament':
        return NotificationAction.openTournament;
      case 'register_tournament':
        return NotificationAction.registerTournament;
      case 'view_match_details':
        return NotificationAction.viewMatchDetails;
      case 'view_order':
        return NotificationAction.viewOrder;
      case 'open_payment_history':
        return NotificationAction.openPaymentHistory;
      case 'upgrade_to_player':
        return NotificationAction.upgradeToPlayer;
      case 'view_community_members':
        return NotificationAction.viewCommunityMembers;
      default:
        return NotificationAction.custom;
    }
  }

  /// Convert priority string to NotificationPriority
  static NotificationPriority priorityFromString(String priorityString) {
    switch (priorityString.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'medium':
        return NotificationPriority.medium;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.medium;
    }
  }

  /// Convert category string to NotificationCategory
  static NotificationCategory categoryFromString(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'community':
        return NotificationCategory.community;
      case 'tournament':
        return NotificationCategory.tournament;
      case 'payment':
        return NotificationCategory.payment;
      case 'shop':
        return NotificationCategory.shop;
      case 'admin':
        return NotificationCategory.admin;
      case 'match':
        return NotificationCategory.match;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.system;
    }
  }

  @override
  List<Object?> get props => [
        id,
        recipientId,
        recipientType,
        type,
        title,
        message,
        read,
        createdAt,
        priority,
        category,
        data,
        action,
      ];

  @override
  String toString() {
    return 'NotificationEntity{id: $id, type: $type, title: $title, read: $read, priority: $priority}';
  }
}
