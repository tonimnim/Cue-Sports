import 'package:equatable/equatable.dart';

/// Payment entity representing a payment transaction
class Payment extends Equatable {
  final String id;
  final String userId;
  final String paymentType;
  final String typeId;
  final String phoneNumber;
  final double amount;
  final String status;
  final String? mpesaReceiptNumber;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.paymentType,
    required this.typeId,
    required this.phoneNumber,
    required this.amount,
    required this.status,
    this.mpesaReceiptNumber,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        paymentType,
        typeId,
        phoneNumber,
        amount,
        status,
        mpesaReceiptNumber,
        createdAt,
        completedAt,
      ];
} 