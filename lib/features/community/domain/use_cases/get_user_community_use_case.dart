import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for retrieving the community that a user belongs to
///
/// This is used when players want to view their own community
class GetUserCommunityUseCase implements UseCase<Community?, UserCommunityParams> {
  final CommunityRepository repository;

  GetUserCommunityUseCase(this.repository);

  @override
  Future<Either<Failure, Community?>> call(UserCommunityParams params) async {
    return await repository.getUserCommunity(params.userId);
  }
}

/// Parameters for retrieving a user's community
class UserCommunityParams extends Equatable {
  final String userId;

  const UserCommunityParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
