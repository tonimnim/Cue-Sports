import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for searching communities by name
///
/// This is used when players want to find specific communities by search query
class SearchCommunitiesUseCase implements UseCase<List<Community>, SearchParams> {
  final CommunityRepository repository;

  SearchCommunitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(SearchParams params) async {
    return await repository.searchCommunities(params.query);
  }
}

/// Parameters for searching communities
class SearchParams extends Equatable {
  final String query;

  const SearchParams({required this.query});

  @override
  List<Object> get props => [query];
}