import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Remote data source for notifications
abstract class NotificationRemoteDataSource {
  /// Get all notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Get unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId);

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);
}

/// Firebase implementation of NotificationRemoteDataSource
class FirebaseNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseNotificationRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('notification_settings')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        return 0;
      }

      final data = docSnapshot.data();
      return data?['unreadCount'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread notifications count: $e');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Get all unread notifications for the user
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      // Create a batch to update all notifications
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Reset unread count in notification settings
      batch.update(_firestore.collection('notification_settings').doc(userId),
          {'unreadCount': 0});

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}