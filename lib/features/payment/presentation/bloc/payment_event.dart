import 'package:equatable/equatable.dart';

/// Base class for payment events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

/// Event to initiate a payment
class InitiatePaymentEvent extends PaymentEvent {
  final String userId;
  final String paymentType;
  final String typeId;
  final String phoneNumber;
  final double amount;

  const InitiatePaymentEvent({
    required this.userId,
    required this.paymentType,
    required this.typeId,
    required this.phoneNumber,
    required this.amount,
  });

  @override
  List<Object> get props => [userId, paymentType, typeId, phoneNumber, amount];
}

/// Event to check payment status
class CheckPaymentStatusEvent extends PaymentEvent {
  final String paymentId;

  const CheckPaymentStatusEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// Event to reset payment state
class ResetPaymentEvent extends PaymentEvent {} 