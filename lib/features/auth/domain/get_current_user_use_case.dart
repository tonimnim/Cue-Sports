import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'entities/user.dart';
import 'auth_repository.dart';

/// Use case for retrieving the current authenticated user
///
/// This use case doesn't require any parameters since we're simply
/// retrieving the currently authenticated user from the repository.
/// It returns either a Failure or the User entity if found.
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  /// Execute the get current user operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the operation fails, or
  /// - a [User] if a user is currently authenticated, or null if no user
  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
