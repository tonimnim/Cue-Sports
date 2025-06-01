import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for retrieving details of a specific community
///
/// This is used when players want to view details of a community
class GetCommunityDetailsUseCase implements UseCase<Community, CommunityDetailsParams> {
  final CommunityRepository repository;

  GetCommunityDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, Community>> call(CommunityDetailsParams params) async {
    return await repository.getCommunityById(params.communityId);
  }
}

/// Parameters for retrieving community details
class CommunityDetailsParams extends Equatable {
  final String communityId;

  const CommunityDetailsParams({required this.communityId});

  @override
  List<Object> get props => [communityId];
}