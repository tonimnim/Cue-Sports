import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';

/// Use case for checking if a user is a member of a specific community
///
/// This is used to determine whether to show join buttons or member-only features
class CheckCommunityMembershipUseCase implements UseCase<bool, MembershipParams> {
  final CommunityRepository repository;

  CheckCommunityMembershipUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(MembershipParams params) async {
    return await repository.isUserCommunityMember(
      userId: params.userId,
      communityId: params.communityId,
    );
  }
}

/// Parameters for checking community membership
class MembershipParams extends Equatable {
  final String userId;
  final String communityId;

  const MembershipParams({
    required this.userId,
    required this.communityId,
  });

  @override
  List<Object> get props => [userId, communityId];
}