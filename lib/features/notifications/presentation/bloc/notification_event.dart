import 'package:equatable/equatable.dart';

/// Base class for notification events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notifications for a user
class LoadNotificationsEvent extends NotificationEvent {
  final String userId;

  const LoadNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh notifications for a user
class RefreshNotificationsEvent extends NotificationEvent {
  final String userId;

  const RefreshNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to mark a notification as read
class MarkNotificationReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Event to mark all notifications as read
class MarkAllNotificationsReadEvent extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsReadEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to delete a notification
class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Event to load unread notifications count
class LoadUnreadCountEvent extends NotificationEvent {
  final String userId;

  const LoadUnreadCountEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}