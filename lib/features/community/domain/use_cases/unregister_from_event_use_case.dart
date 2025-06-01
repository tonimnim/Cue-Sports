import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';

/// Use case for unregistering from an event
class UnregisterFromEventUseCase implements UseCase<bool, UnregisterFromEventParams> {
  final CommunityRepository repository;

  UnregisterFromEventUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UnregisterFromEventParams params) async {
    return await repository.unregisterFromEvent(
      params.eventId,
      params.userId,
    );
  }
}

/// Parameters for unregistering from an event
class UnregisterFromEventParams extends Equatable {
  final String eventId;
  final String userId;

  const UnregisterFromEventParams({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
} 