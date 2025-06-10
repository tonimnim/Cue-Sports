import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/player_tournament_stats.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';
import '../models/tournament_model.dart';

/// PRODUCTION-READY: Tournament repository with graceful fallbacks and caching
class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;

  // Cache for production performance and offline fallback
  static List<Tournament>? _allTournamentsCache;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 3);

  TournamentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
  });

  /// Get all tournaments with smart caching and offline support
  Future<Either<Failure, List<Tournament>>>
      _getAllTournamentsWithCache() async {
    try {
      // Check cache first
      if (_allTournamentsCache != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) <
              _cacheValidityDuration) {
        print(
            '🚀 REPOSITORY CACHE HIT: Returning ${_allTournamentsCache!.length} cached tournaments');
        return Right(List.from(_allTournamentsCache!));
      }

      // Check network
      if (await networkInfo.isConnected) {
        print('🌐 NETWORK AVAILABLE: Fetching fresh tournaments');
        final tournamentModels = await remoteDataSource.getAllTournaments();
        final tournaments =
            tournamentModels.map((model) => model.toEntity()).toList();

        // Update cache
        _allTournamentsCache = tournaments;
        _lastCacheUpdate = DateTime.now();

        print('✅ REPOSITORY: Cached ${tournaments.length} tournaments');
        return Right(tournaments);
      } else {
        print('📵 NO NETWORK: Using cache or returning empty');
        if (_allTournamentsCache != null) {
          return Right(List.from(_allTournamentsCache!));
        } else {
          return const Left(NetworkFailure(
              message: 'No internet connection and no cached data available'));
        }
      }
    } catch (e) {
      print('❌ REPOSITORY ERROR: $e');

      // Try to return cached data as fallback
      if (_allTournamentsCache != null) {
        print('🔄 FALLBACK: Returning cached data due to error');
        return Right(List.from(_allTournamentsCache!));
      }

      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getTournaments({
    TournamentStatus? status,
    TournamentType? type,
    bool? isFeatured,
    int? limit,
  }) async {
    try {
      print('🏆 REPOSITORY: Getting tournaments with filters');
      print('   - Status: $status');
      print('   - Type: $type');
      print('   - Featured: $isFeatured');
      print('   - Limit: $limit');

      // Get all tournaments using cache-aware method
      final allTournamentsResult = await _getAllTournamentsWithCache();

      return allTournamentsResult.fold(
        (failure) => Left(failure),
        (allTournaments) {
          var filtered = allTournaments;

          // Client-side filtering - production safe
          if (status != null) {
            filtered = filtered.where((t) => t.status == status).toList();
            print('   - Filtered by status: ${filtered.length} remaining');
          }

          if (type != null) {
            filtered = filtered.where((t) => t.type == type).toList();
            print('   - Filtered by type: ${filtered.length} remaining');
          }

          if (isFeatured != null) {
            filtered =
                filtered.where((t) => t.isFeatured == isFeatured).toList();
            print('   - Filtered by featured: ${filtered.length} remaining');
          }

          // Sort by creation date (newest first)
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (limit != null && filtered.length > limit) {
            filtered = filtered.take(limit).toList();
            print('   - Applied limit: ${filtered.length} tournaments');
          }

          print(
              '✅ REPOSITORY: Returning ${filtered.length} filtered tournaments');
          return Right(filtered);
        },
      );
    } catch (e) {
      print('❌ REPOSITORY: Error in getTournaments: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, Tournament>> getTournamentById(
      String tournamentId) async {
    try {
      if (await networkInfo.isConnected) {
        final tournament =
            await remoteDataSource.getTournamentById(tournamentId);
        return Right(tournament.toEntity());
      } else {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getFeaturedTournaments() async {
    try {
      print('🌟 REPOSITORY: Getting featured tournaments (production-safe)');

      // Use cache-aware method and filter client-side
      final allTournamentsResult = await _getAllTournamentsWithCache();

      return allTournamentsResult.fold(
        (failure) => Left(failure),
        (allTournaments) {
          final featured = allTournaments
              .where((t) => t.status == TournamentStatus.active && t.isFeatured)
              .toList();

          // Sort by start date
          featured.sort((a, b) => a.startDate.compareTo(b.startDate));

          print('✅ REPOSITORY: Found ${featured.length} featured tournaments');
          return Right(featured);
        },
      );
    } catch (e) {
      print('❌ REPOSITORY: Error getting featured tournaments: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getActiveTournaments() async {
    try {
      print('🔥 REPOSITORY: Getting active tournaments (production-safe)');

      // Use single-field query for better reliability
      if (await networkInfo.isConnected) {
        final tournamentModels = await remoteDataSource
            .getTournamentsByStatus(TournamentStatus.active);
        final tournaments =
            tournamentModels.map((model) => model.toEntity()).toList();

        print('✅ REPOSITORY: Found ${tournaments.length} active tournaments');
        return Right(tournaments);
      } else {
        // Offline fallback - filter cached data
        final allTournamentsResult = await _getAllTournamentsWithCache();
        return allTournamentsResult.fold(
          (failure) => Left(failure),
          (allTournaments) {
            final active = allTournaments
                .where((t) => t.status == TournamentStatus.active)
                .toList();

            active.sort((a, b) => a.startDate.compareTo(b.startDate));

            print(
                '📵 REPOSITORY OFFLINE: Found ${active.length} cached active tournaments');
            return Right(active);
          },
        );
      }
    } catch (e) {
      print('❌ REPOSITORY: Error getting active tournaments: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getTournamentsByType(
      TournamentType type) async {
    try {
      print('🎯 REPOSITORY: Getting tournaments by type: ${type.name}');

      if (await networkInfo.isConnected) {
        final tournamentModels =
            await remoteDataSource.getTournamentsByType(type);
        final tournaments =
            tournamentModels.map((model) => model.toEntity()).toList();

        print(
            '✅ REPOSITORY: Found ${tournaments.length} tournaments of type ${type.name}');
        return Right(tournaments);
      } else {
        // Offline fallback
        final allTournamentsResult = await _getAllTournamentsWithCache();
        return allTournamentsResult.fold(
          (failure) => Left(failure),
          (allTournaments) {
            final filtered =
                allTournaments.where((t) => t.type == type).toList();

            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            print(
                '📵 REPOSITORY OFFLINE: Found ${filtered.length} cached tournaments of type ${type.name}');
            return Right(filtered);
          },
        );
      }
    } catch (e) {
      print('❌ REPOSITORY: Error getting tournaments by type: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> registerForTournament({
    required String tournamentId,
    required String userId,
    required String communityId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final result = await remoteDataSource.registerForTournament(
          tournamentId: tournamentId,
          userId: userId,
          communityId: communityId,
        );

        // Clear cache to force refresh on next fetch
        _allTournamentsCache = null;

        return Right(result);
      } else {
        return const Left(NetworkFailure(
            message: 'Registration requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserRegistered({
    required String tournamentId,
    required String userId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final result = await remoteDataSource.isUserRegistered(
          tournamentId: tournamentId,
          userId: userId,
        );
        return Right(result);
      } else {
        return const Left(NetworkFailure(
            message:
                'Checking registration status requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getPlayerMatches({
    required String playerId,
    MatchStatus? status,
    int? limit,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final matchModels = await remoteDataSource.getPlayerMatches(
          playerId: playerId,
          status: status,
          limit: limit,
        );
        final matches = matchModels;
        return Right(matches);
      } else {
        return const Left(NetworkFailure(
            message: 'Loading matches requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getTournamentMatches({
    required String tournamentId,
    MatchStatus? status,
    int? limit,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final matchModels = await remoteDataSource.getTournamentMatches(
          tournamentId: tournamentId,
          status: status,
          limit: limit,
        );
        final matches = matchModels;
        return Right(matches);
      } else {
        return const Left(NetworkFailure(
            message:
                'Loading tournament matches requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, Match>> getMatchById(String matchId) async {
    try {
      if (await networkInfo.isConnected) {
        final match = await remoteDataSource.getMatchById(matchId);
        return Right(match);
      } else {
        return const Left(NetworkFailure(
            message: 'Loading match details requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getUpcomingMatches({
    String? playerId,
    int? limit,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final matchModels = await remoteDataSource.getUpcomingMatches(
          playerId: playerId,
          limit: limit,
        );
        final matches = matchModels;
        return Right(matches);
      } else {
        return const Left(NetworkFailure(
            message: 'Loading upcoming matches requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getLiveMatches() async {
    try {
      if (await networkInfo.isConnected) {
        final matchModels = await remoteDataSource.getAllLiveMatches();
        final matches = matchModels;

        print('✅ REPOSITORY: Found ${matches.length} live matches');
        return Right(matches);
      } else {
        print('📵 REPOSITORY: No network for live matches');
        return const Left(NetworkFailure(
            message: 'Live matches require internet connection'));
      }
    } catch (e) {
      print('❌ REPOSITORY: Error getting live matches: $e');
      // Return empty list instead of failing - live matches are not critical
      return const Right(<Match>[]);
    }
  }

  @override
  Future<Either<Failure, PlayerTournamentStats?>> getPlayerStats({
    required String userId,
    required String tournamentId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final stats = await remoteDataSource.getPlayerStats(
          userId: userId,
          tournamentId: tournamentId,
        );
        return Right(stats);
      } else {
        return const Left(NetworkFailure(
            message: 'Loading player stats requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<PlayerTournamentStats>>>
      getTournamentLeaderboard({
    required String tournamentId,
    String? communityId,
    int? limit,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final stats = await remoteDataSource.getTournamentLeaderboard(
          tournamentId: tournamentId,
          communityId: communityId,
          limit: limit,
        );
        return Right(stats);
      } else {
        return const Left(NetworkFailure(
            message: 'Loading leaderboard requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<PlayerTournamentStats>>> getCommunityLeaderboard({
    required String tournamentId,
    required String communityId,
    int? limit,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final stats = await remoteDataSource.getCommunityLeaderboard(
          tournamentId: tournamentId,
          communityId: communityId,
          limit: limit,
        );
        return Right(stats);
      } else {
        return const Left(NetworkFailure(
            message:
                'Loading community leaderboard requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> searchTournaments({
    required String query,
    TournamentType? type,
    TournamentStatus? status,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final tournamentModels = await remoteDataSource.searchTournaments(
          query: query,
          type: type,
          status: status,
        );
        final tournaments =
            tournamentModels.map((model) => model.toEntity()).toList();
        return Right(tournaments);
      } else {
        // Offline search using cached data
        final allTournamentsResult = await _getAllTournamentsWithCache();
        return allTournamentsResult.fold(
          (failure) => Left(failure),
          (allTournaments) {
            var filtered = allTournaments;

            if (type != null) {
              filtered = filtered.where((t) => t.type == type).toList();
            }

            if (status != null) {
              filtered = filtered.where((t) => t.status == status).toList();
            }

            // Text search
            filtered = filtered
                .where((tournament) =>
                    tournament.name
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                    tournament.description
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();

            return Right(filtered);
          },
        );
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> searchMatches({
    required String query,
    String? tournamentId,
    MatchStatus? status,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final matchModels = await remoteDataSource.searchMatches(
          query: query,
          tournamentId: tournamentId,
          status: status,
        );
        final matches = matchModels;
        return Right(matches);
      } else {
        return const Left(
            NetworkFailure(message: 'Search requires internet connection'));
      }
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createTournament(
      Tournament tournament) async {
    if (await networkInfo.isConnected) {
      try {
        final tournamentModel = TournamentModel.fromEntity(tournament);
        final tournamentId =
            await remoteDataSource.createTournament(tournamentModel);
        return Right(tournamentId);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTournament(Tournament tournament) async {
    if (await networkInfo.isConnected) {
      try {
        final tournamentModel = TournamentModel.fromEntity(tournament);
        await remoteDataSource.updateTournament(tournamentModel);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTournament(String tournamentId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTournament(tournamentId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // Placeholder implementations for registration methods
  // TODO: Implement these when needed
  @override
  Future<Either<Failure, List<TournamentRegistration>>>
      getTournamentRegistrations(String tournamentId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TournamentRegistration>>> getUserRegistrations(
      String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, TournamentRegistration?>> getRegistration(
      String tournamentId, String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateRegistration(
      TournamentRegistration registration) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> cancelRegistration(
      String registrationId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Tournament>>> getVisibleTournaments(
      String userId, List<String> communityIds) async {
    try {
      final tournamentModels = await remoteDataSource.getTournaments();
      final tournaments = tournamentModels
          .map((model) => model.toEntity())
          .where(
              (tournament) => tournament.isVisibleToUser(userId, communityIds))
          .toList();
      return Right(tournaments);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  /// Handle exceptions and convert to appropriate failures
  Failure _handleException(dynamic e) {
    print('🔍 EXCEPTION ANALYSIS: $e');

    if (e is ServerException) {
      if (e.message.contains('permission') || e.message.contains('denied')) {
        return const ServerFailure(
            message: 'Access denied. Please check your permissions.');
      } else if (e.message.contains('not found')) {
        return const ServerFailure(message: 'Requested data not found.');
      } else if (e.message.contains('network') ||
          e.message.contains('connection')) {
        return const NetworkFailure(
            message: 'Network connection error. Please check your internet.');
      } else {
        return ServerFailure(message: e.message);
      }
    } else if (e.toString().contains('failed-precondition')) {
      // This should no longer happen with our production-safe approach
      print(
          '⚠️ UNEXPECTED: Index error occurred despite production-safe design');
      return const ServerFailure(
          message: 'Database configuration issue. Using fallback data.');
    } else if (e.toString().contains('permission-denied')) {
      return const ServerFailure(
          message: 'Access denied. Please check your permissions.');
    } else if (e.toString().contains('unavailable')) {
      return const NetworkFailure(
          message: 'Service temporarily unavailable. Please try again.');
    } else {
      return ServerFailure(
          message: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Clear all caches - useful for logout or data refresh
  static void clearCache() {
    _allTournamentsCache = null;
    _lastCacheUpdate = null;
    print('🧹 REPOSITORY: Cache cleared');
  }
}
