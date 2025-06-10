import 'package:flutter/material.dart';
import '../domain/entities/payment.dart';

/// Helper class to assist with migrating from old payment implementations
/// to the new unified payment system
class PaymentMigrationHelper {
  /// Convert old payment type strings to new PaymentType enum
  static PaymentType? convertPaymentType(String oldType) {
    switch (oldType.toLowerCase()) {
      case 'registration':
      case 'player_registration':
        return PaymentType.registration;
      case 'tournament':
      case 'tournament_registration':
      case 'tournament_entry':
        return PaymentType.tournament;
      case 'shop':
      case 'merchandise':
      case 'product':
        return PaymentType.merchandise;
      default:
        return null;
    }
  }

  /// Navigate to unified payment screen with proper arguments
  static void navigateToUnifiedPayment(
    BuildContext context, {
    required PaymentType paymentType,
    required String typeId,
    required String userId,
    required double amount,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
  }) {
    Navigator.of(context).pushNamed(
      '/unified-payment',
      arguments: {
        'paymentType': paymentType,
        'typeId': typeId,
        'userId': userId,
        'amount': amount,
        'prefillPhoneNumber': phoneNumber,
        'metadata': metadata,
        'onSuccess': onSuccess,
        'onFailure': onFailure,
      },
    );
  }

  /// Show payment success dialog
  static void showPaymentSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show payment failure dialog
  static void showPaymentFailure(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Get payment type description for UI
  static String getPaymentTypeDescription(PaymentType type) {
    switch (type) {
      case PaymentType.registration:
        return 'Player Registration';
      case PaymentType.tournament:
        return 'Tournament Entry';
      case PaymentType.merchandise:
        return 'Shop Purchase';
    }
  }

  /// Format amount for display
  static String formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(0)}';
  }
}
