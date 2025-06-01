import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community_post.dart';
import '../community_repository.dart';

/// Use case for getting community posts
class GetCommunityPostsUseCase implements UseCase<List<CommunityPost>, GetCommunityPostsParams> {
  final CommunityRepository repository;

  GetCommunityPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CommunityPost>>> call(GetCommunityPostsParams params) async {
    return await repository.getCommunityPosts(
      params.communityId,
      limit: params.limit,
      lastPostId: params.lastPostId,
    );
  }
}

/// Parameters for getting community posts
class GetCommunityPostsParams extends Equatable {
  final String communityId;
  final int limit;
  final String? lastPostId;

  const GetCommunityPostsParams({
    required this.communityId,
    this.limit = 20,
    this.lastPostId,
  });

  @override
  List<Object?> get props => [communityId, limit, lastPostId];
} 