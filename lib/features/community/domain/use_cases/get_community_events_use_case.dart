import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community_event.dart';
import '../community_repository.dart';

/// Use case for getting community events
class GetCommunityEventsUseCase implements UseCase<List<CommunityEvent>, GetCommunityEventsParams> {
  final CommunityRepository repository;

  GetCommunityEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CommunityEvent>>> call(GetCommunityEventsParams params) async {
    return await repository.getCommunityEvents(
      params.communityId,
      includeEnded: params.includeEnded,
    );
  }
}

/// Parameters for getting community events
class GetCommunityEventsParams extends Equatable {
  final String communityId;
  final bool includeEnded;

  const GetCommunityEventsParams({
    required this.communityId,
    this.includeEnded = false,
  });

  @override
  List<Object> get props => [communityId, includeEnded];
} 