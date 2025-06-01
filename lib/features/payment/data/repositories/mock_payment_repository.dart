import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

/// Mock repository for testing payment functionality
class MockPaymentRepository implements PaymentRepository {
  final Map<String, PaymentModel> _payments = {};
  final Map<String, Timer> _paymentTimers = {};
  @override
  Future<Either<Failure, Payment>> initiatePayment({
    required String userId,
    required String paymentType,
    required String typeId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      // Generate a unique payment ID
      final paymentId = 'PAY${DateTime.now().millisecondsSinceEpoch}';

      // Create a new payment
      final payment = PaymentModel(
        id: paymentId,
        userId: userId,
        paymentType: paymentType,
        typeId: typeId,
        phoneNumber: phoneNumber,
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Store the payment
      _payments[paymentId] = payment;

      // Simulate payment completion after random time (5-15 seconds)
      final randomDuration = Duration(seconds: 5 + (DateTime.now().millisecond % 10));
      _paymentTimers[paymentId] = Timer(randomDuration, () {
        // 80% chance of success
        final isSuccess = DateTime.now().millisecond % 10 < 8;
        
        if (isSuccess) {
          _payments[paymentId] = payment.copyWith(
            status: 'completed',
            mpesaReceiptNumber: 'MP${DateTime.now().millisecondsSinceEpoch}',
            completedAt: DateTime.now(),
          );
        } else {
          _payments[paymentId] = payment.copyWith(
            status: 'failed',
            completedAt: DateTime.now(),
          );
        }
      });

      return Right(payment);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> checkPaymentStatus({
    required String paymentId,
  }) async {
    try {
      final payment = _payments[paymentId];
      if (payment == null) {
        return Left(ServerFailure(message: 'Payment not found'));
      }
      return Right(payment);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById({
    required String paymentId,
  }) async {
    try {
      final payment = _payments[paymentId];
      if (payment == null) {
        return Left(ServerFailure(message: 'Payment not found'));
      }
      return Right(payment);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByUserId({
    required String userId,
  }) async {
    try {
      final userPayments = _payments.values
          .where((payment) => payment.userId == userId)
          .toList();
      return Right(userPayments);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Clean up timers
  void dispose() {
    for (var timer in _paymentTimers.values) {
      timer.cancel();
    }
    _paymentTimers.clear();
  }
} 