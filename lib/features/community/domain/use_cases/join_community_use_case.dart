import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';

/// Use case for joining a community
class JoinCommunityUseCase implements UseCase<void, JoinCommunityParams> {
  final CommunityRepository repository;

  JoinCommunityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinCommunityParams params) async {
    return await repository.joinCommunity(
      userId: params.userId,
      communityId: params.communityId,
    );
  }
}

/// Parameters for joining a community
class JoinCommunityParams extends Equatable {
  final String userId;
  final String communityId;

  const JoinCommunityParams({
    required this.userId,
    required this.communityId,
  });

  @override
  List<Object> get props => [userId, communityId];
} 