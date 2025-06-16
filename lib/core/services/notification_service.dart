import 'package:cloud_firestore/cloud_firestore.dart';
// Removed injectable import
import '../../features/shop/domain/entities/shop_order.dart';
import 'logger_service.dart';

/// Core notification service that handles sending notifications across the app
/// This service integrates with the notification system and provides a centralized
/// way to send notifications for different features
// Removed @lazySingleton annotation
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger;

  NotificationService(this._logger);

  /// Send notification when order payment is completed
  Future<void> sendOrderCompletedNotification({
    required String userId,
    required String orderId,
    required double orderAmount,
    required String paymentReceiptNumber,
    bool isTestOrder = false,
  }) async {
    try {
      _logger.i('Sending order completion notification for user: $userId, order: $orderId');
      
      // Create notification document
      final notificationData = {
        'recipientId': userId,
        'recipientType': 'user',
        'type': isTestOrder ? 'TEST_PAYMENT_SUCCESS' : 'PAYMENT_SUCCESS',
        'title': isTestOrder ? 'Test Order Created Successfully! 🧪' : 'Order Payment Successful! 🎉',
        'message': isTestOrder
            ? 'Your test order has been created successfully.'
            : 'Your order payment has been completed successfully.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
        'category': 'shop',
        'data': {
          'orderId': orderId,
          'amount': orderAmount,
          'receiptNumber': paymentReceiptNumber,
          'isTestOrder': isTestOrder,
        },
      };

      // Add to notifications collection
      await _firestore.collection('notifications').add(notificationData);

      // Update notification settings to mark new notification
      await _updateUserNotificationCount(userId);

      _logger.i('✅ Order completion notification sent for user: $userId');
    } catch (e) {
      _logger.e('❌ Error sending order notification: $e');
      // Rethrow to allow caller to handle
      rethrow;
    }
  }

  /// Send notification for order status updates
  Future<void> sendOrderStatusUpdateNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required double orderAmount,
    required String newStatus,
  }) async {
    try {
      String title = '';
      String message = '';
      String priority = 'medium';

      switch (newStatus.toLowerCase()) {
        case 'processing':
          title = 'Order Being Processed 📦';
          message = 'Your order #$orderNumber is now being processed.';
          break;
        case 'shipped':
          title = 'Order Shipped! 🚚';
          message = 'Your order #$orderNumber has been shipped and is on its way.';
          priority = 'high';
          break;
        case 'delivered':
          title = 'Order Delivered! ✅';
          message = 'Your order #$orderNumber has been delivered successfully.';
          priority = 'high';
          break;
        case 'cancelled':
          title = 'Order Cancelled ❌';
          message = 'Your order #$orderNumber has been cancelled.';
          priority = 'high';
          break;
        default:
          title = 'Order Update';
          message = 'Your order #$orderNumber status has been updated to $newStatus.';
      }

      final notificationData = {
        'recipientId': userId,
        'recipientType': 'user',
        'type': 'ORDER_STATUS_UPDATE',
        'title': title,
        'message': message,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': priority,
        'category': 'shop',
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'newStatus': newStatus,
          'amount': orderAmount,
        },
      };

      await _firestore.collection('notifications').add(notificationData);
      await _updateUserNotificationCount(userId);

      _logger.i('✅ Order status notification sent for user: $userId');
    } catch (e) {
      _logger.e('❌ Error sending status notification: $e');
      rethrow;
    }
  }

  /// Update user's unread notification count
  Future<void> _updateUserNotificationCount(String userId) async {
    try {
      final userNotificationSettings =
          _firestore.collection('notification_settings').doc(userId);

      await userNotificationSettings.set({
        'userId': userId,
        'unreadCount': FieldValue.increment(1),
        'lastNotificationAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _logger.e('❌ Error updating notification count: $e');
      rethrow;
    }
  }
}