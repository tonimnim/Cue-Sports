import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for getting communities by location
///
/// This is used when players want to find communities in a specific area
class GetCommunitiesByLocationUseCase implements UseCase<List<Community>, LocationParams> {
  final CommunityRepository repository;

  GetCommunitiesByLocationUseCase(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(LocationParams params) async {
    return await repository.getCommunityByLocation(params.location);
  }
}

/// Parameters for filtering communities by location
class LocationParams extends Equatable {
  final String location;

  const LocationParams({required this.location});

  @override
  List<Object> get props => [location];
}