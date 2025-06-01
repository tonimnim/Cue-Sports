import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../community_repository.dart';

/// Use case for registering for an event
class RegisterForEventUseCase implements UseCase<bool, RegisterForEventParams> {
  final CommunityRepository repository;

  RegisterForEventUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(RegisterForEventParams params) async {
    return await repository.registerForEvent(
      params.eventId,
      params.userId,
    );
  }
}

/// Parameters for registering for an event
class RegisterForEventParams extends Equatable {
  final String eventId;
  final String userId;

  const RegisterForEventParams({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
} 