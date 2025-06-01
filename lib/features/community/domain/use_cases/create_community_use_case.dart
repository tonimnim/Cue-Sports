import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../community_repository.dart';

/// Use case for creating a new community
///
/// This is primarily for testing and admin integration as community creation
/// will mainly be handled by the admin web interface
class CreateCommunityUseCase implements UseCase<Community, CreateCommunityParams> {
  final CommunityRepository repository;

  CreateCommunityUseCase(this.repository);

  @override
  Future<Either<Failure, Community>> call(CreateCommunityParams params) async {
    return await repository.createCommunity(
      name: params.name,
      leaderId: params.adminId,
      location: params.location ?? 'Unknown',
      description: params.description,
    );
  }
}

/// Parameters for creating a community
class CreateCommunityParams extends Equatable {
  final String name;
  final String adminId;
  final String? description;
  final String? location;

  const CreateCommunityParams({
    required this.name,
    required this.adminId,
    this.description,
    this.location,
  });

  @override
  List<Object?> get props => [name, adminId, description, location];
}