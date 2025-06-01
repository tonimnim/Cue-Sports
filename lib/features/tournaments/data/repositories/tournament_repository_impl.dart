import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';
import '../models/tournament_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDataSource remoteDataSource;

  TournamentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Tournament>>> getTournaments() async {
    try {
      final tournamentModels = await remoteDataSource.getTournaments();
      final tournaments = tournamentModels.map((model) => model.toEntity()).toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getFeaturedTournaments() async {
    try {
      final tournamentModels = await remoteDataSource.getFeaturedTournaments();
      final tournaments = tournamentModels.map((model) => model.toEntity()).toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getUpcomingTournaments() async {
    try {
      final tournamentModels = await remoteDataSource.getUpcomingTournaments();
      final tournaments = tournamentModels.map((model) => model.toEntity()).toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getTournamentsByStatus(TournamentStatus status) async {
    try {
      final tournamentModels = await remoteDataSource.getTournamentsByStatus(status);
      final tournaments = tournamentModels.map((model) => model.toEntity()).toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Tournament?>> getTournamentById(String id) async {
    try {
      final tournamentModel = await remoteDataSource.getTournamentById(id);
      final tournament = tournamentModel?.toEntity();
      return Right(tournament);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createTournament(Tournament tournament) async {
    try {
      final tournamentModel = TournamentModel.fromEntity(tournament);
      final tournamentId = await remoteDataSource.createTournament(tournamentModel);
      return Right(tournamentId);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTournament(Tournament tournament) async {
    try {
      final tournamentModel = TournamentModel.fromEntity(tournament);
      await remoteDataSource.updateTournament(tournamentModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTournament(String tournamentId) async {
    try {
      await remoteDataSource.deleteTournament(tournamentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // Placeholder implementations for registration methods
  // TODO: Implement these when needed
  @override
  Future<Either<Failure, List<TournamentRegistration>>> getTournamentRegistrations(String tournamentId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TournamentRegistration>>> getUserRegistrations(String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, TournamentRegistration?>> getRegistration(String tournamentId, String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> registerForTournament(TournamentRegistration registration) async {
    return const Right('');
  }

  @override
  Future<Either<Failure, void>> updateRegistration(TournamentRegistration registration) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> cancelRegistration(String registrationId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Tournament>>> getVisibleTournaments(String userId, List<String> communityIds) async {
    try {
      final tournamentModels = await remoteDataSource.getTournaments();
      final tournaments = tournamentModels
          .map((model) => model.toEntity())
          .where((tournament) => tournament.isVisibleToUser(userId, communityIds))
          .toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
} 