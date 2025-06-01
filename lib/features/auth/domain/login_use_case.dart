import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'entities/user.dart';
import 'auth_repository.dart';

/// Login parameters containing phone number and password
class LoginParams {
  final String? email;
  final String? phoneNumber;
  final String password;

  const LoginParams({
    this.email,
    this.phoneNumber,
    required this.password,
  }) : assert(email != null || phoneNumber != null, 'Either email or phoneNumber must be provided');
}

/// Login use case that handles user authentication
///
/// This use case takes email and password credentials and attempts
/// to authenticate the user. It returns either a Failure or the
/// authenticated User entity.
class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  /// Execute the login with the provided credentials
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if login fails, or
  /// - a [User] if login succeeds
  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(
      email: params.email,
      phoneNumber: params.phoneNumber,
      password: params.password,
    );
  }
}
