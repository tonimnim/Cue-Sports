import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_repository.dart';

/// Logout use case that handles user sign out
///
/// This use case doesn't require any parameters since we're simply
/// logging out the current authenticated user. It returns either a
/// Failure or void (null) if successful.
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  /// Execute the logout operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if logout fails, or
  /// - void (null) if logout succeeds
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logout();
  }
}
