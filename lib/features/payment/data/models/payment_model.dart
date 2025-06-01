import '../../domain/entities/payment.dart';

/// Model class for Payment entity with JSON serialization
class PaymentModel extends Payment {
  const PaymentModel({
    required String id,
    required String userId,
    required String paymentType,
    required String typeId,
    required String phoneNumber,
    required double amount,
    required String status,
    String? mpesaReceiptNumber,
    required DateTime createdAt,
    DateTime? completedAt,
  }) : super(
          id: id,
          userId: userId,
          paymentType: paymentType,
          typeId: typeId,
          phoneNumber: phoneNumber,
          amount: amount,
          status: status,
          mpesaReceiptNumber: mpesaReceiptNumber,
          createdAt: createdAt,
          completedAt: completedAt,
        );

  /// Create PaymentModel from JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      paymentType: json['paymentType'] as String,
      typeId: json['typeId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      mpesaReceiptNumber: json['mpesaReceiptNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Convert PaymentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'paymentType': paymentType,
      'typeId': typeId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'status': status,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy of PaymentModel with some fields updated
  PaymentModel copyWith({
    String? id,
    String? userId,
    String? paymentType,
    String? typeId,
    String? phoneNumber,
    double? amount,
    String? status,
    String? mpesaReceiptNumber,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paymentType: paymentType ?? this.paymentType,
      typeId: typeId ?? this.typeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
} 