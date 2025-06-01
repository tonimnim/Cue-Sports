import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

/// Parameters for checking payment status
class CheckPaymentStatusParams extends Equatable {
  final String paymentId;

  const CheckPaymentStatusParams({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// Use case for checking payment status
class CheckPaymentStatus implements UseCase<Payment, CheckPaymentStatusParams> {
  final PaymentRepository repository;

  const CheckPaymentStatus(this.repository);

  @override
  Future<Either<Failure, Payment>> call(CheckPaymentStatusParams params) async {
    return await repository.checkPaymentStatus(paymentId: params.paymentId);
  }
} 