import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';

/// Base class for payment states
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Initial payment state
class PaymentInitial extends PaymentState {}

/// Loading state during payment operations
class PaymentLoading extends PaymentState {}

/// State when payment is initiated successfully
class PaymentInitiated extends PaymentState {
  final Payment payment;

  const PaymentInitiated(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment is pending confirmation
class PaymentPending extends PaymentState {
  final Payment payment;

  const PaymentPending(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment is completed successfully
class PaymentSuccess extends PaymentState {
  final Payment payment;

  const PaymentSuccess(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment fails
class PaymentFailure extends PaymentState {
  final String message;

  const PaymentFailure(this.message);

  @override
  List<Object> get props => [message];
} 