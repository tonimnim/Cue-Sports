import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_repository.dart';

/// Parameters for sending email verification
class SendEmailVerificationParams {
  final String email;

  const SendEmailVerificationParams({required this.email});
}

/// Parameters for verifying email with code
class VerifyEmailParams {
  final String email;
  final String code;

  const VerifyEmailParams({
    required this.email,
    required this.code,
  });
}

/// Use case for sending email verification
///
/// Takes user email and sends a verification code/link
/// to verify the user's email address.
class SendEmailVerificationUseCase implements UseCase<void, SendEmailVerificationParams> {
  final AuthRepository repository;

  const SendEmailVerificationUseCase(this.repository);

  /// Execute the send email verification operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if sending fails, or
  /// - void (null) if the verification email was sent successfully
  @override
  Future<Either<Failure, void>> call(SendEmailVerificationParams params) async {
    return await repository.sendEmailVerification(email: params.email);
  }
}

/// Use case for verifying email with code
///
/// Takes user email and verification code to verify
/// the user's email address.
class VerifyEmailUseCase implements UseCase<void, VerifyEmailParams> {
  final AuthRepository repository;

  const VerifyEmailUseCase(this.repository);

  /// Execute the email verification operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if verification fails, or
  /// - void (null) if the email was verified successfully
  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(
      email: params.email,
      code: params.code,
    );
  }
}
