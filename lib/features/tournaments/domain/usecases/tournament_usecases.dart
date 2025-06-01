import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class GetTournamentsUseCase implements UseCase<List<Tournament>, NoParams> {
  final TournamentRepository repository;

  GetTournamentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Tournament>>> call(NoParams params) async {
    return await repository.getTournaments();
  }
}

class GetFeaturedTournamentsUseCase implements UseCase<List<Tournament>, NoParams> {
  final TournamentRepository repository;

  GetFeaturedTournamentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Tournament>>> call(NoParams params) async {
    return await repository.getFeaturedTournaments();
  }
}

class GetUpcomingTournamentsUseCase implements UseCase<List<Tournament>, NoParams> {
  final TournamentRepository repository;

  GetUpcomingTournamentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Tournament>>> call(NoParams params) async {
    return await repository.getUpcomingTournaments();
  }
}

class GetTournamentsByStatusUseCase implements UseCase<List<Tournament>, TournamentStatus> {
  final TournamentRepository repository;

  GetTournamentsByStatusUseCase(this.repository);

  @override
  Future<Either<Failure, List<Tournament>>> call(TournamentStatus status) async {
    return await repository.getTournamentsByStatus(status);
  }
}

class GetTournamentByIdUseCase implements UseCase<Tournament?, String> {
  final TournamentRepository repository;

  GetTournamentByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Tournament?>> call(String tournamentId) async {
    return await repository.getTournamentById(tournamentId);
  }
} 