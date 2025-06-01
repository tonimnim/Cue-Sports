import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for retrieving all communities
///
/// This is used when players need to browse or select a community
class GetCommunitiesUseCase implements UseCase<List<Community>, NoParams> {
  final CommunityRepository repository;

  GetCommunitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(NoParams params) async {
    return await repository.getCommunities();
  }
}