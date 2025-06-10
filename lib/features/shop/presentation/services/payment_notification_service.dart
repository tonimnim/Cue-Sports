import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shop_order.dart';

/// Service to handle payment success notifications
/// Connects shop payment completion to the notification system
class PaymentNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification when order payment is completed
  Future<void> sendOrderCompletedNotification({
    required String userId,
    required ShopOrder order,
    required String paymentReceiptNumber,
  }) async {
    try {
      // Create notification document
      final notificationData = {
        'id': 'order_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'title': 'Order Payment Successful! 🎉',
        'body':
            'Your order #${order.orderNumber} payment has been completed successfully.',
        'type': 'PAYMENT_SUCCESS',
        'category': 'orders',
        'priority': 'high',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'orderId': order.id,
          'orderNumber': order.orderNumber,
          'amount': order.total,
          'receiptNumber': paymentReceiptNumber,
          'itemCount': order.items.length,
        },
        'actions': [
          {
            'type': 'view_order',
            'label': 'View Order',
            'route': '/orders',
          },
          {
            'type': 'continue_shopping',
            'label': 'Continue Shopping',
            'route': '/shop',
          },
        ],
      };

      // Add to notifications collection
      await _firestore.collection('notifications').add(notificationData);

      // Update notification settings to mark new notification
      await _updateUserNotificationCount(userId);

      print('✅ Order completion notification sent for user: $userId');
    } catch (e) {
      print('❌ Error sending order notification: $e');
    }
  }

  /// Send notification for order status updates
  Future<void> sendOrderStatusUpdateNotification({
    required String userId,
    required ShopOrder order,
    required String newStatus,
  }) async {
    try {
      String title = '';
      String body = '';
      String priority = 'medium';

      switch (newStatus.toLowerCase()) {
        case 'processing':
          title = 'Order Being Processed 📦';
          body = 'Your order #${order.orderNumber} is now being processed.';
          break;
        case 'shipped':
          title = 'Order Shipped! 🚚';
          body =
              'Your order #${order.orderNumber} has been shipped and is on its way.';
          priority = 'high';
          break;
        case 'delivered':
          title = 'Order Delivered! ✅';
          body =
              'Your order #${order.orderNumber} has been delivered successfully.';
          priority = 'high';
          break;
        case 'cancelled':
          title = 'Order Cancelled ❌';
          body = 'Your order #${order.orderNumber} has been cancelled.';
          priority = 'high';
          break;
        default:
          title = 'Order Update';
          body =
              'Your order #${order.orderNumber} status has been updated to $newStatus.';
      }

      final notificationData = {
        'id': 'status_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'ORDER_STATUS_UPDATE',
        'category': 'orders',
        'priority': priority,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'orderId': order.id,
          'orderNumber': order.orderNumber,
          'newStatus': newStatus,
          'amount': order.total,
        },
        'actions': [
          {
            'type': 'view_order',
            'label': 'View Order',
            'route': '/orders',
          },
        ],
      };

      await _firestore.collection('notifications').add(notificationData);
      await _updateUserNotificationCount(userId);

      print('✅ Order status notification sent for user: $userId');
    } catch (e) {
      print('❌ Error sending status notification: $e');
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
      print('❌ Error updating notification count: $e');
    }
  }

  /// Send promotional notifications for shop deals
  Future<void> sendShopPromoNotification({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? promoData,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final notificationData = {
          'id': 'promo_${DateTime.now().millisecondsSinceEpoch}_$userId',
          'userId': userId,
          'title': title,
          'body': body,
          'type': 'SHOP_PROMOTION',
          'category': 'promotions',
          'priority': 'medium',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          'data': {
            'imageUrl': imageUrl,
            'promoData': promoData,
          },
          'actions': [
            {
              'type': 'view_shop',
              'label': 'Shop Now',
              'route': '/shop',
            },
          ],
        };

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notificationData);
      }

      await batch.commit();
      print('✅ Promotional notifications sent to ${userIds.length} users');
    } catch (e) {
      print('❌ Error sending promotional notifications: $e');
    }
  }
}
