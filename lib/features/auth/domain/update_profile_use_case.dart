import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'entities/user.dart';
import 'auth_repository.dart';

/// Parameters for updating user profile
class UpdateProfileParams {
  final String userId;
  final String? fullName;
  final String? phoneNumber;
  final String? profileImageUrl;

  const UpdateProfileParams({
    required this.userId,
    this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
  });

  /// Check if any updates are included
  bool get hasUpdates => fullName != null || phoneNumber != null || profileImageUrl != null;
}

/// Use case for updating a user's profile information
///
/// Takes user ID and optional updated profile details (name, phone, profile image)
/// and updates the user's profile in the system.
class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  const UpdateProfileUseCase(this.repository);

  /// Execute the profile update operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the update fails, or
  /// - the updated [User] if successful
  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    // If no updates are included, throw an error
    if (!params.hasUpdates) {
      return Left(const ValidationFailure(message: 'No profile updates provided'));
    }
    
    return await repository.updateUserProfile(
      userId: params.userId,
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      profileImageUrl: params.profileImageUrl,
    );
  }
}
