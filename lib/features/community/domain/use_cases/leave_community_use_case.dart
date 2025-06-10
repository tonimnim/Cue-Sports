import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';

/// Use case for leaving a community
class LeaveCommunityUseCase implements UseCase<void, LeaveCommunityParams> {
  final CommunityRepository repository;

  LeaveCommunityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveCommunityParams params) async {
    return await repository.leaveCommunity(
      userId: params.userId,
      communityId: params.communityId,
    );
  }
}

/// Parameters for leaving a community
class LeaveCommunityParams extends Equatable {
  final String communityId;
  final String userId;

  const LeaveCommunityParams({
    required this.communityId,
    required this.userId,
  });

  @override
  List<Object> get props => [communityId, userId];
} 
