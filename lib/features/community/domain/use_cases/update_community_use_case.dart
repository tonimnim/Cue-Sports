import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';
import '../entities/community.dart';

/// Use case for updating a community
///
/// This is used when community details need to be updated
class UpdateCommunityUseCase implements UseCase<Community, UpdateCommunityParams> {
  final CommunityRepository repository;

  UpdateCommunityUseCase(this.repository);

  @override
  Future<Either<Failure, Community>> call(UpdateCommunityParams params) async {
    return await repository.updateCommunity(params.community);
  }
}

/// Parameters for updating a community
class UpdateCommunityParams extends Equatable {
  final Community community;

  const UpdateCommunityParams({
    required this.community,
  });

  @override
  List<Object> get props => [community];
}