import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tournament.dart';
import '../entities/match.dart';
import '../entities/player_tournament_stats.dart';

/// Repository interface for tournament operations
abstract class TournamentRepository {
  // Tournament operations
  Future<Either<Failure, List<Tournament>>> getTournaments({
    TournamentStatus? status,
    TournamentType? type,
    bool? isFeatured,
    int? limit,
  });

  Future<Either<Failure, Tournament>> getTournamentById(String tournamentId);

  Future<Either<Failure, List<Tournament>>> getFeaturedTournaments();

  Future<Either<Failure, List<Tournament>>> getActiveTournaments();

  Future<Either<Failure, bool>> registerForTournament({
    required String tournamentId,
    required String userId,
    required String communityId,
  });

  Future<Either<Failure, bool>> isUserRegistered({
    required String tournamentId,
    required String userId,
  });

  // Match operations
  Future<Either<Failure, List<Match>>> getPlayerMatches({
    required String playerId,
    MatchStatus? status,
    int? limit,
  });

  Future<Either<Failure, List<Match>>> getTournamentMatches({
    required String tournamentId,
    MatchStatus? status,
    int? limit,
  });

  Future<Either<Failure, Match>> getMatchById(String matchId);

  Future<Either<Failure, List<Match>>> getUpcomingMatches({
    String? playerId,
    int? limit,
  });

  Future<Either<Failure, List<Match>>> getLiveMatches();

  // Player statistics
  Future<Either<Failure, PlayerTournamentStats?>> getPlayerStats({
    required String userId,
    required String tournamentId,
  });

  Future<Either<Failure, List<PlayerTournamentStats>>>
      getTournamentLeaderboard({
    required String tournamentId,
    String? communityId,
    int? limit,
  });

  Future<Either<Failure, List<PlayerTournamentStats>>> getCommunityLeaderboard({
    required String tournamentId,
    required String communityId,
    int? limit,
  });

  // Search and filtering
  Future<Either<Failure, List<Tournament>>> searchTournaments({
    required String query,
    TournamentType? type,
    TournamentStatus? status,
  });

  Future<Either<Failure, List<Match>>> searchMatches({
    required String query,
    String? tournamentId,
    MatchStatus? status,
  });
}
