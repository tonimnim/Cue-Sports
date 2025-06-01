import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

/// Parameters for initiating a payment
class InitiatePaymentParams extends Equatable {
  final String userId;
  final String paymentType;
  final String typeId;
  final String phoneNumber;
  final double amount;

  const InitiatePaymentParams({
    required this.userId,
    required this.paymentType,
    required this.typeId,
    required this.phoneNumber,
    required this.amount,
  });

  @override
  List<Object> get props => [userId, paymentType, typeId, phoneNumber, amount];
}

/// Use case for initiating a payment transaction
class InitiatePayment implements UseCase<Payment, InitiatePaymentParams> {
  final PaymentRepository repository;

  const InitiatePayment(this.repository);

  @override
  Future<Either<Failure, Payment>> call(InitiatePaymentParams params) async {
    return await repository.initiatePayment(
      userId: params.userId,
      paymentType: params.paymentType,
      typeId: params.typeId,
      phoneNumber: params.phoneNumber,
      amount: params.amount,
    );
  }
} 