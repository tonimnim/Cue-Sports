import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for getting top ranked communities
///
/// This is used for displaying leaderboards and showcasing the most successful communities
class GetTopRankedCommunitiesUseCase implements UseCase<List<Community>, RankingParams> {
  final CommunityRepository repository;

  GetTopRankedCommunitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(RankingParams params) async {
    return await repository.getTopRankedCommunities(limit: params.limit);
  }
}

/// Parameters for fetching top ranked communities
class RankingParams extends Equatable {
  final int limit;

  const RankingParams({this.limit = 10});

  @override
  List<Object> get props => [limit];
}