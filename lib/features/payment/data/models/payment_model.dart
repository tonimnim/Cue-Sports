import '../../domain/entities/payment.dart';

/// Model class for Payment entity with JSON serialization
class PaymentModel extends Payment {
  const PaymentModel({
    required String id,
    required String userId,
    required PaymentType type,
    required String typeId,
    required double amount,
    required String phoneNumber,
    required PaymentStatus status,
    String? mpesaReceiptNumber,
    String? checkoutRequestId,
    String? transactionId,
    required DateTime createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) : super(
          id: id,
          userId: userId,
          type: type,
          typeId: typeId,
          amount: amount,
          phoneNumber: phoneNumber,
          status: status,
          mpesaReceiptNumber: mpesaReceiptNumber,
          checkoutRequestId: checkoutRequestId,
          transactionId: transactionId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          metadata: metadata,
          errorMessage: errorMessage,
        );

  /// Create PaymentModel from JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: _parsePaymentType(json['type'] as String),
      typeId: json['typeId'] as String,
      amount: (json['amount'] as num).toDouble(),
      phoneNumber: json['phoneNumber'] as String,
      status: _parsePaymentStatus(json['status'] as String),
      mpesaReceiptNumber: json['mpesaReceiptNumber'] as String?,
      checkoutRequestId: json['checkoutRequestId'] as String?,
      transactionId: json['transactionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert PaymentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'typeId': typeId,
      'amount': amount,
      'phoneNumber': phoneNumber,
      'status': status.name,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'checkoutRequestId': checkoutRequestId,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'errorMessage': errorMessage,
    };
  }

  /// Parse payment type from string
  static PaymentType _parsePaymentType(String type) {
    switch (type) {
      case 'registration':
        return PaymentType.registration;
      case 'tournament':
        return PaymentType.tournament;
      case 'merchandise':
        return PaymentType.merchandise;
      default:
        throw ArgumentError('Unknown payment type: $type');
    }
  }

  /// Parse payment status from string
  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'initial':
        return PaymentStatus.initial;
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'timeout':
        return PaymentStatus.timeout;
      default:
        throw ArgumentError('Unknown payment status: $status');
    }
  }
}
