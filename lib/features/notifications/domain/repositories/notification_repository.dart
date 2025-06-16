import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

/// Repository interface for notifications
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);

  /// Get unread notifications count for a user
  Future<Either<Failure, int>> getUnreadNotificationsCount(String userId);

  /// Mark a notification as read
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId);

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);
}