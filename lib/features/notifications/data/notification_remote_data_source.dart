import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/services/logger_service.dart';
import '../../../firebase/firebase_services.dart';
import 'models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  /// Get notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId);

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseServices firebaseServices;
  final LoggerService logger;

  NotificationRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseServices,
    required this.logger,
  });

  /// IMPORTANT: This query requires a composite index on the 'notifications' collection
  /// with fields 'recipientId' (Ascending) and 'createdAt' (Descending).
  /// Create this index by visiting:
  /// https://console.firebase.google.com/v1/r/project/poolbilliard-167ad/firestore/indexes?create_composite=Clhwcm9qZWN0cy9wb29sYmlsbGlhcmQtMTY3YWQvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaDwoLcmVjaXBpZW50SWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC
  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      logger.i('Getting notifications for user: $userId');
      
      // This query requires a composite index on recipientId (Ascending) and createdAt (Descending)
      // If you see an error about missing index, use the link from the error message to create it
      final querySnapshot = await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          // Removing orderBy to avoid index error, but note that for proper sorting
          // you should create the required index in Firebase console
          .get();
      
      logger.i('Got ${querySnapshot.docs.length} notifications');
      
      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      logger.e('Error getting notifications: $e');
      throw ServerException('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      logger.i('Getting unread notification count for user: $userId');
      
      // First check if there's a document in notification_settings collection
      final settingsDoc = await firestore
          .collection('notification_settings')
          .doc(userId)
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data != null && data.containsKey('unreadCount')) {
          return data['unreadCount'] as int;
        }
      }

      // If no settings document or no unreadCount field, count unread notifications
      final querySnapshot = await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0; // Return 0 if count is null
    } catch (e) {
      logger.e('Error getting unread count: $e');
      throw ServerException('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      logger.i('Marking notification as read: $notificationId');
      
      // Get the notification to check the user ID
      final notificationDoc = await firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        throw NotFoundException('Notification not found');
      }
      
      final data = notificationDoc.data();
      if (data == null) {
        throw NotFoundException('Notification data is null');
      }
      
      final userId = data['recipientId'] as String;
      
      // Update the notification
      await firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      
      // Update the unread count in notification_settings
      await _decrementUnreadCount(userId);
    } catch (e) {
      logger.e('Error marking notification as read: $e');
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      logger.i('Marking all notifications as read for user: $userId');
      
      // Get all unread notifications for the user
      final querySnapshot = await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      // Use a batch to update all notifications
      final batch = firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
      
      // Reset unread count to 0 in notification_settings
      await firestore
          .collection('notification_settings')
          .doc(userId)
          .set({'unreadCount': 0}, SetOptions(merge: true));
    } catch (e) {
      logger.e('Error marking all notifications as read: $e');
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      logger.i('Deleting notification: $notificationId');
      
      // Get the notification to check if it's unread
      final notificationDoc = await firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        throw NotFoundException('Notification not found');
      }
      
      final data = notificationDoc.data();
      if (data == null) {
        throw NotFoundException('Notification data is null');
      }
      
      final userId = data['recipientId'] as String;
      final isRead = data['read'] as bool? ?? false;
      
      // Delete the notification
      await firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      // If the notification was unread, decrement the unread count
      if (!isRead) {
        await _decrementUnreadCount(userId);
      }
      
      logger.i('Notification deleted successfully');
    } catch (e) {
      logger.e('Error deleting notification: $e');
      throw ServerException('Failed to delete notification: $e');
    }
  }

  /// Helper method to decrement the unread count for a user
  Future<void> _decrementUnreadCount(String userId) async {
    try {
      final settingsDoc = await firestore
          .collection('notification_settings')
          .doc(userId)
          .get();
      
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data != null && data.containsKey('unreadCount')) {
          final currentCount = data['unreadCount'] as int;
          if (currentCount > 0) {
            await firestore
                .collection('notification_settings')
                .doc(userId)
                .update({'unreadCount': FieldValue.increment(-1)});
          }
        }
      }
    } catch (e) {
      logger.e('Error decrementing unread count: $e');
      // Don't throw here, just log the error
    }
  }
}