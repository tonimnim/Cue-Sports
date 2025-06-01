import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tournament.dart';
import '../entities/tournament_registration.dart';

abstract class TournamentRepository {
  // Tournament methods
  Future<Either<Failure, List<Tournament>>> getTournaments();
  Future<Either<Failure, List<Tournament>>> getFeaturedTournaments();
  Future<Either<Failure, List<Tournament>>> getUpcomingTournaments();
  Future<Either<Failure, List<Tournament>>> getTournamentsByStatus(TournamentStatus status);
  Future<Either<Failure, Tournament?>> getTournamentById(String id);
  Future<Either<Failure, String>> createTournament(Tournament tournament);
  Future<Either<Failure, void>> updateTournament(Tournament tournament);
  Future<Either<Failure, void>> deleteTournament(String tournamentId);

  // Registration methods
  Future<Either<Failure, List<TournamentRegistration>>> getTournamentRegistrations(String tournamentId);
  Future<Either<Failure, List<TournamentRegistration>>> getUserRegistrations(String userId);
  Future<Either<Failure, TournamentRegistration?>> getRegistration(String tournamentId, String userId);
  Future<Either<Failure, String>> registerForTournament(TournamentRegistration registration);
  Future<Either<Failure, void>> updateRegistration(TournamentRegistration registration);
  Future<Either<Failure, void>> cancelRegistration(String registrationId);

  // User visibility methods
  Future<Either<Failure, List<Tournament>>> getVisibleTournaments(String userId, List<String> communityIds);
} 