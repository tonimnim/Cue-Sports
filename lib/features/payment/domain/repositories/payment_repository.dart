import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment.dart';

/// Abstract repository for handling payment operations
abstract class PaymentRepository {
  /// Initiate a payment transaction
  Future<Either<Failure, Payment>> initiatePayment({
    required String userId,
    required String paymentType,
    required String typeId,
    required String phoneNumber,
    required double amount,
  });

  /// Check payment status
  Future<Either<Failure, Payment>> checkPaymentStatus({
    required String paymentId,
  });

  /// Get payment by ID
  Future<Either<Failure, Payment>> getPaymentById({
    required String paymentId,
  });

  /// Get payments by user ID
  Future<Either<Failure, List<Payment>>> getPaymentsByUserId({
    required String userId,
  });
} 