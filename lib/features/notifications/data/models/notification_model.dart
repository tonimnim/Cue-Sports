import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification.dart';

/// Data model class for Notification with JSON serialization support
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required String id,
    required String recipientId,
    required String recipientType,
    required String type,
    required String title,
    required String message,
    required bool read,
    required DateTime createdAt,
    required NotificationPriority priority,
    required NotificationCategory category,
    required Map<String, dynamic> data,
    NotificationAction? action,
  }) : super(
          id: id,
          recipientId: recipientId,
          recipientType: recipientType,
          type: type,
          title: title,
          message: message,
          read: read,
          createdAt: createdAt,
          priority: priority,
          category: category,
          data: data,
          action: action,
        );

  /// Creates a NotificationModel from JSON data
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      recipientType: json['recipientType'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      priority: NotificationEntity.priorityFromString(
          json['priority'] as String? ?? 'medium'),
      category: NotificationEntity.categoryFromString(
          json['category'] as String? ?? 'system'),
      data: json['data'] as Map<String, dynamic>? ?? {},
      action: NotificationEntity.actionFromString(
          json['data']?['action'] as String?),
    );
  }

  /// Creates a NotificationModel from a Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Converts the NotificationModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
      'data': data,
    };
  }

  /// Converts the NotificationModel to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'recipientType': recipientType,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
      'data': data,
    };
  }

  /// Creates a copy of this NotificationModel with some fields updated
  NotificationModel copyWithModel({
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
    return NotificationModel(
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

  /// Create from entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      recipientId: entity.recipientId,
      recipientType: entity.recipientType,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      read: entity.read,
      createdAt: entity.createdAt,
      priority: entity.priority,
      category: entity.category,
      data: entity.data,
      action: entity.action,
    );
  }

  /// Convert to entity
  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      recipientId: recipientId,
      recipientType: recipientType,
      type: type,
      title: title,
      message: message,
      read: read,
      createdAt: createdAt,
      priority: priority,
      category: category,
      data: data,
      action: action,
    );
  }
}
