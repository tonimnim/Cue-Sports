import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';

/// Base class for payment events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initiate a payment
class InitiatePaymentEvent extends PaymentEvent {
  final PaymentType paymentType;
  final String typeId;
  final String userId;
  final double amount;
  final String phoneNumber;
  final Map<String, dynamic>? metadata;

  const InitiatePaymentEvent({
    required this.paymentType,
    required this.typeId,
    required this.userId,
    required this.amount,
    required this.phoneNumber,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        paymentType,
        typeId,
        userId,
        amount,
        phoneNumber,
        metadata,
      ];
}

/// Event to check payment status
class CheckPaymentStatusEvent extends PaymentEvent {
  final String transactionId;

  const CheckPaymentStatusEvent({required this.transactionId});

  @override
  List<Object> get props => [transactionId];
}

/// Event when payment status is updated
class PaymentStatusUpdatedEvent extends PaymentEvent {
  final Payment payment;

  const PaymentStatusUpdatedEvent({required this.payment});

  @override
  List<Object> get props => [payment];
}

/// Event to retry a failed payment
class RetryPaymentEvent extends PaymentEvent {
  final Payment payment;

  const RetryPaymentEvent({required this.payment});

  @override
  List<Object> get props => [payment];
}

/// Event to cancel ongoing payment
class CancelPaymentEvent extends PaymentEvent {
  const CancelPaymentEvent();
}

/// Event to load payment history
class LoadPaymentHistoryEvent extends PaymentEvent {
  final String userId;
  final PaymentType? filterByType;

  const LoadPaymentHistoryEvent({
    required this.userId,
    this.filterByType,
  });

  @override
  List<Object?> get props => [userId, filterByType];
}

/// Event to reset payment state
class ResetPaymentStateEvent extends PaymentEvent {
  const ResetPaymentStateEvent();
}
