import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_repository.dart';

/// Parameters for sending password reset email
class SendPasswordResetParams {
  final String email;

  const SendPasswordResetParams({required this.email});
}

/// Parameters for verifying password reset code
class VerifyPasswordResetParams {
  final String email;
  final String code;

  const VerifyPasswordResetParams({
    required this.email,
    required this.code,
  });
}

/// Parameters for completing password reset
class ResetPasswordParams {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

/// Use case for sending password reset email
///
/// Takes user email and initiates the password reset process
/// by sending a verification code/link to the user's email.
class SendPasswordResetUseCase implements UseCase<void, SendPasswordResetParams> {
  final AuthRepository repository;

  const SendPasswordResetUseCase(this.repository);

  /// Execute the send password reset email operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the operation fails, or
  /// - void (null) if the email was sent successfully
  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) async {
    return await repository.sendPasswordResetEmail(email: params.email);
  }
}

/// Use case for verifying password reset code
///
/// Takes user email and reset code to verify the code's validity
/// before allowing password reset.
class VerifyPasswordResetUseCase implements UseCase<void, VerifyPasswordResetParams> {
  final AuthRepository repository;

  const VerifyPasswordResetUseCase(this.repository);

  /// Execute the verify password reset code operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the code is invalid, or
  /// - void (null) if the code is valid
  @override
  Future<Either<Failure, void>> call(VerifyPasswordResetParams params) async {
    return await repository.verifyPasswordResetCode(
      email: params.email,
      code: params.code,
    );
  }
}

/// Use case for completing password reset with new password
///
/// Takes user email, verification code, and new password to
/// complete the password reset process.
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  const ResetPasswordUseCase(this.repository);

  /// Execute the password reset operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the reset fails, or
  /// - void (null) if the password was reset successfully
  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      email: params.email,
      code: params.code,
      newPassword: params.newPassword,
    );
  }
}
