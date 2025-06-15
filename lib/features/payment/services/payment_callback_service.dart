import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/payment.dart';
import '../../shop/presentation/bloc/shop_bloc.dart';
import '../../shop/presentation/bloc/shop_event.dart';
import '../../tournaments/direct_implementation/tournament_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/di/injection_container.dart' as di;

/// Abstract interface for handling payment callbacks
abstract class PaymentCallbackService {
  /// Called when a payment is successful
  Future<void> onPaymentSuccess(Payment payment);

  /// Called when a payment fails
  Future<void> onPaymentFailed(Payment payment);

  /// Called when a payment is cancelled
  Future<void> onPaymentCancelled(Payment payment);
}

/// Handles callbacks for player registration payments
class RegistrationPaymentCallback implements PaymentCallbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = di.sl<LoggerService>();

  @override
  Future<void> onPaymentSuccess(Payment payment) async {
    try {
      _logger.i(
          'Processing successful registration payment for user: ${payment.userId}');

      // Update user's payment status in Firestore
      await _firestore.collection('users').doc(payment.userId).update({
        'isPaid': true,
        'paymentReceiptNumber': payment.mpesaReceiptNumber,
        'paymentTimestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Log payment record
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'registration',
        'typeId': payment.typeId, // Community ID
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'success',
        'mpesaReceiptNumber': payment.mpesaReceiptNumber,
        'checkoutRequestId': payment.checkoutRequestId,
        'transactionId': payment.transactionId,
        'createdAt': payment.createdAt,
        'completedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Registration payment processed successfully');
    } catch (e) {
      _logger.e('Error processing registration payment success: $e');
      rethrow;
    }
  }

  @override
  Future<void> onPaymentFailed(Payment payment) async {
    try {
      _logger.w('Registration payment failed for user: ${payment.userId}');

      // Log failed payment attempt
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'registration',
        'typeId': payment.typeId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'failed',
        'errorMessage': payment.errorMessage,
        'createdAt': payment.createdAt,
        'failedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error logging failed registration payment: $e');
    }
  }

  @override
  Future<void> onPaymentCancelled(Payment payment) async {
    _logger.i('Registration payment cancelled by user: ${payment.userId}');
  }
}

/// Handles callbacks for tournament registration payments
class TournamentPaymentCallback implements PaymentCallbackService {
  final TournamentService _tournamentService = TournamentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = di.sl<LoggerService>();

  @override
  Future<void> onPaymentSuccess(Payment payment) async {
    try {
      _logger.i(
          'Processing successful tournament payment for user: ${payment.userId}');

      // Register user for the tournament
      final success = await _tournamentService.registerUserForTournament(
        payment.typeId, // Tournament ID
        payment.userId,
      );

      if (success) {
        _logger.i(
            'User successfully registered for tournament: ${payment.typeId}');
      } else {
        _logger.e('Failed to register user for tournament after payment');
      }

      // Log payment record
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'tournament',
        'typeId': payment.typeId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'success',
        'mpesaReceiptNumber': payment.mpesaReceiptNumber,
        'checkoutRequestId': payment.checkoutRequestId,
        'transactionId': payment.transactionId,
        'createdAt': payment.createdAt,
        'completedAt': FieldValue.serverTimestamp(),
        'tournamentRegistered': success,
      });
    } catch (e) {
      _logger.e('Error processing tournament payment success: $e');
      rethrow;
    }
  }

  @override
  Future<void> onPaymentFailed(Payment payment) async {
    try {
      _logger.w('Tournament payment failed for user: ${payment.userId}');

      // Log failed payment attempt
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'tournament',
        'typeId': payment.typeId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'failed',
        'errorMessage': payment.errorMessage,
        'createdAt': payment.createdAt,
        'failedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error logging failed tournament payment: $e');
    }
  }

  @override
  Future<void> onPaymentCancelled(Payment payment) async {
    _logger.i('Tournament payment cancelled by user: ${payment.userId}');
  }
}

/// Handles callbacks for merchandise/shop payments
class MerchandisePaymentCallback implements PaymentCallbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = di.sl<LoggerService>();
  final ShopBloc? shopBloc; // Optional, can be passed in constructor

  MerchandisePaymentCallback({this.shopBloc});

  @override
  Future<void> onPaymentSuccess(Payment payment) async {
    try {
      _logger.i(
          'Processing successful merchandise payment for user: ${payment.userId}');

      // Get cart items from metadata or typeId (which is cartId)
      final cartId = payment.typeId;
      List<Map<String, dynamic>> cartItems = [];

      // Retrieve cart items from Firestore - FIXED: Items are in a subcollection, not in the cart document
      try {
        final cartItemsSnapshot = await _firestore
            .collection('carts')
            .doc(payment.userId) // Use userId instead of cartId
            .collection('items')
            .get();

        _logger.i('Retrieved ${cartItemsSnapshot.docs.length} cart items for order creation');
        
        for (final doc in cartItemsSnapshot.docs) {
          final itemData = doc.data();
          itemData['id'] = doc.id; // Ensure the item ID is included
          cartItems.add(itemData);
          _logger.d('Added cart item: ${doc.id}, Product: ${itemData['productId']}, Quantity: ${itemData['quantity']}');
        }
      } catch (e) {
        _logger.e('Error retrieving cart items for order creation: $e');
      }

      // Create order
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      _logger.i('Creating order $orderId with ${cartItems.length} items');
      
      await _firestore.collection('orders').doc(orderId).set({
        'userId': payment.userId,
        'orderNumber': orderId,
        'items': cartItems,
        'total': payment.amount,
        'status': 'pending',
        'paymentMethod': 'mpesa',
        'mpesaReceiptNumber': payment.mpesaReceiptNumber,
        'phoneNumber': payment.phoneNumber,
        'transactionId': payment.transactionId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cart if ShopBloc is available
      if (shopBloc != null) {
        shopBloc!.add(ClearCartEvent(payment.userId));
      } else {
        // If ShopBloc is not available, clear the cart directly from Firestore
        try {
          // Get all cart items
          final cartItems = await _firestore
              .collection('carts')
              .doc(payment.userId)
              .collection('items')
              .get();

          // Create a batch to delete all items
          final batch = _firestore.batch();
          for (final doc in cartItems.docs) {
            batch.delete(doc.reference);
          }

          // Commit the batch
          await batch.commit();
          _logger.i('Cart cleared after successful payment for user: ${payment.userId}');
        } catch (e) {
          _logger.e('Error clearing cart after payment: $e');
        }
      }

      // Log payment record
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'merchandise',
        'typeId': cartId,
        'orderId': orderId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'success',
        'mpesaReceiptNumber': payment.mpesaReceiptNumber,
        'checkoutRequestId': payment.checkoutRequestId,
        'transactionId': payment.transactionId,
        'createdAt': payment.createdAt,
        'completedAt': FieldValue.serverTimestamp(),
      });

      _logger
          .i('Merchandise payment and order creation completed successfully');
    } catch (e) {
      _logger.e('Error processing merchandise payment success: $e');
      rethrow;
    }
  }

  @override
  Future<void> onPaymentFailed(Payment payment) async {
    try {
      _logger.w('Merchandise payment failed for user: ${payment.userId}');

      // Log failed payment attempt
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': 'merchandise',
        'typeId': payment.typeId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': 'failed',
        'errorMessage': payment.errorMessage,
        'createdAt': payment.createdAt,
        'failedAt': FieldValue.serverTimestamp(),
      });

      // No longer creating orders for TinyPesa API errors
      // We only want orders to be created when payment is successful
      _logger.i('Payment failed. No order will be created for failed payment: ${payment.id}');
      
      if (payment.errorMessage?.contains('TinyPesa API') ?? false) {
        _logger.w('TinyPesa API error detected: ${payment.errorMessage}. No order will be created.');
      }
    } catch (e) {
      _logger.e('Error handling failed merchandise payment: $e');
    }
  }

  @override
  Future<void> onPaymentCancelled(Payment payment) async {
    _logger.i('Merchandise payment cancelled by user: ${payment.userId}');
  }
}

/// Factory to create appropriate callback service based on payment type
class PaymentCallbackFactory {
  static PaymentCallbackService create(PaymentType type, {ShopBloc? shopBloc}) {
    switch (type) {
      case PaymentType.registration:
        return RegistrationPaymentCallback();
      case PaymentType.tournament:
        return TournamentPaymentCallback();
      case PaymentType.merchandise:
        return MerchandisePaymentCallback(shopBloc: shopBloc);
    }
  }
}
