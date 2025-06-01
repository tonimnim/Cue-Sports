import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import 'entities/user.dart';
import 'auth_repository.dart';

/// Parameters for upgrading a fan user to a player
class UpgradeToPlayerParams {
  final String userId;
  final String communityId;
  final String paymentId;

  const UpgradeToPlayerParams({
    required this.userId,
    required this.communityId,
    required this.paymentId,
  });
}

/// Use case for upgrading a fan user to a player with payment
///
/// Takes a fan user's ID, community ID, and M-Pesa payment ID
/// and upgrades them to a player account with the required KSh 500 payment.
class UpgradeToPlayerUseCase implements UseCase<User, UpgradeToPlayerParams> {
  final AuthRepository repository;

  const UpgradeToPlayerUseCase(this.repository);

  /// Execute the upgrade to player operation
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the upgrade fails, or
  /// - the upgraded [User] if successful
  @override
  Future<Either<Failure, User>> call(UpgradeToPlayerParams params) async {
    return await repository.upgradeToPlayer(
      userId: params.userId,
      communityId: params.communityId,
      paymentId: params.paymentId,
    );
  }
}
