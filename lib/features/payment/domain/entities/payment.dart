import 'package:equatable/equatable.dart';

/// Enum representing the different types of payments in the app
enum PaymentType {
  registration, // Player registration payment
  tournament, // Tournament entry fee
  merchandise // Shop purchase
}

/// Enum representing the status of a payment
enum PaymentStatus {
  initial, // Payment not yet initiated
  pending, // Payment initiated, waiting for user action
  processing, // Payment being processed
  success, // Payment completed successfully
  failed, // Payment failed
  cancelled, // Payment cancelled by user
  timeout // Payment timed out
}

/// Entity representing a payment transaction
class Payment extends Equatable {
  final String id;
  final String userId;
  final PaymentType type;
  final String typeId; // communityId for registration, tournamentId, or orderId
  final double amount;
  final String phoneNumber;
  final PaymentStatus status;
  final String? mpesaReceiptNumber;
  final String? checkoutRequestId;
  final String? transactionId; // Unique transaction identifier
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata; // Additional type-specific data
  final String? errorMessage;

  const Payment({
    required this.id,
    required this.userId,
    required this.type,
    required this.typeId,
    required this.amount,
    required this.phoneNumber,
    required this.status,
    this.mpesaReceiptNumber,
    this.checkoutRequestId,
    this.transactionId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.errorMessage,
  });

  /// Create a copy of this payment with updated fields
  Payment copyWith({
    String? id,
    String? userId,
    PaymentType? type,
    String? typeId,
    double? amount,
    String? phoneNumber,
    PaymentStatus? status,
    String? mpesaReceiptNumber,
    String? checkoutRequestId,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      amount: amount ?? this.amount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get a human-readable description of the payment type
  String get typeDescription {
    switch (type) {
      case PaymentType.registration:
        return 'Player Registration';
      case PaymentType.tournament:
        return 'Tournament Entry';
      case PaymentType.merchandise:
        return 'Shop Purchase';
    }
  }

  /// Check if the payment is in a final state
  bool get isFinalState {
    return status == PaymentStatus.success ||
        status == PaymentStatus.failed ||
        status == PaymentStatus.cancelled ||
        status == PaymentStatus.timeout;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        typeId,
        amount,
        phoneNumber,
        status,
        mpesaReceiptNumber,
        checkoutRequestId,
        transactionId,
        createdAt,
        updatedAt,
        metadata,
        errorMessage,
      ];
}
