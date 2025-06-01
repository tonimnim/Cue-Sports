import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'entities/user.dart';
import 'auth_repository.dart';

/// Parameters for fan user registration
class RegisterFanParams {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const RegisterFanParams({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });
}

/// Parameters for player user registration
class RegisterPlayerParams {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String communityId;
  final String paymentId;

  const RegisterPlayerParams({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.communityId,
    required this.paymentId,
  });
}

/// Use case for registering a new fan user
///
/// Takes registration details (name, email, phone, password) and attempts
/// to register a new fan user account without payment.
class RegisterFanUseCase implements UseCase<User, RegisterFanParams> {
  final AuthRepository repository;

  const RegisterFanUseCase(this.repository);

  /// Execute the fan registration with the provided details
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if registration fails, or
  /// - a [User] if registration succeeds
  @override
  Future<Either<Failure, User>> call(RegisterFanParams params) async {
    return await repository.registerFan(
      fullName: params.fullName,
      email: params.email,
      phoneNumber: params.phoneNumber,
      password: params.password,
    );
  }
}

/// Use case for registering a new player user with payment
///
/// Takes registration details including payment information and community
/// membership, and attempts to register a new player account with the
/// required KSh 500 payment.
class RegisterPlayerUseCase implements UseCase<User, RegisterPlayerParams> {
  final AuthRepository repository;

  const RegisterPlayerUseCase(this.repository);

  /// Execute the player registration with the provided details
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if registration fails, or
  /// - a [User] if registration succeeds
  @override
  Future<Either<Failure, User>> call(RegisterPlayerParams params) async {
    return await repository.registerPlayer(
      fullName: params.fullName,
      email: params.email,
      phoneNumber: params.phoneNumber,
      password: params.password,
      communityId: params.communityId,
      paymentId: params.paymentId,
    );
  }
}
