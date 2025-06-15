import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/player_tournament_stats.dart';
import '../../../../core/error/exceptions.dart';

/// Remote data source for tournament operations using Firebase
abstract class TournamentRemoteDataSource {
  /// Get all tournaments with simple filtering (production-safe)
  Future<List<TournamentModel>> getAllTournaments();

  /// Get tournaments by status only (single field query - no index needed)
  Future<List<TournamentModel>> getTournamentsByStatus(TournamentStatus status);

  /// Get tournaments by type only (single field query - no index needed)
  Future<List<TournamentModel>> getTournamentsByType(TournamentType type);

  Future<TournamentModel> getTournamentById(String tournamentId);

  /// DEPRECATED - Use getAllTournaments + client filtering
  @Deprecated(
      'Use getAllTournaments() with client-side filtering for production reliability')
  Future<List<TournamentModel>> getTournaments({
    TournamentStatus? status,
    TournamentType? type,
    bool? isFeatured,
    int? limit,
  });

  /// DEPRECATED - Use getAllTournaments + client filtering
  @Deprecated(
      'Use getAllTournaments() with client-side filtering for production reliability')
  Future<List<TournamentModel>> getFeaturedTournaments();

  /// DEPRECATED - Use getTournamentsByStatus + client filtering
  @Deprecated(
      'Use getTournamentsByStatus() with client-side filtering for production reliability')
  Future<List<TournamentModel>> getActiveTournaments();

  Future<bool> registerForTournament({
    required String tournamentId,
    required String userId,
    required String communityId,
  });

  Future<bool> isUserRegistered({
    required String tournamentId,
    required String userId,
  });

  Future<List<MatchModel>> getPlayerMatches({
    required String playerId,
    MatchStatus? status,
    int? limit,
  });

  Future<List<MatchModel>> getTournamentMatches({
    required String tournamentId,
    MatchStatus? status,
    int? limit,
  });

  Future<MatchModel> getMatchById(String matchId);

  Future<List<MatchModel>> getUpcomingMatches({
    String? playerId,
    int? limit,
  });

  /// Simple query - gets all in-progress matches, no compound index needed
  Future<List<MatchModel>> getAllLiveMatches();

  Future<PlayerTournamentStats?> getPlayerStats({
    required String userId,
    required String tournamentId,
  });

  Future<List<PlayerTournamentStats>> getTournamentLeaderboard({
    required String tournamentId,
    String? communityId,
    int? limit,
  });

  Future<List<PlayerTournamentStats>> getCommunityLeaderboard({
    required String tournamentId,
    required String communityId,
    int? limit,
  });

  Future<List<TournamentModel>> searchTournaments({
    required String query,
    TournamentType? type,
    TournamentStatus? status,
  });

  Future<List<MatchModel>> searchMatches({
    required String query,
    String? tournamentId,
    MatchStatus? status,
  });

  Future<String> createTournament(TournamentModel tournament);
  Future<void> updateTournament(TournamentModel tournament);
  Future<void> deleteTournament(String tournamentId);
}

/// Firebase implementation of tournament remote data source
/// PRODUCTION-READY: Designed to minimize index dependencies and provide graceful fallbacks
class FirebaseTournamentRemoteDataSource implements TournamentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for production performance
  static List<TournamentModel>? _tournamentCache;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  FirebaseTournamentRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// PRODUCTION-SAFE: Simple query with no compound indexes
  @override
  Future<List<TournamentModel>> getAllTournaments() async {
    try {
      // Check cache first for performance
      if (_tournamentCache != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) <
              _cacheValidityDuration) {
        print(
            '🚀 CACHE HIT: Returning cached tournaments (${_tournamentCache!.length})');
        return List.from(_tournamentCache!);
      }

      print('🔥 FETCHING ALL TOURNAMENTS: Production-safe simple query...');

      // SIMPLE QUERY: No compound fields, just order by a single indexed field
      final snapshot = await _firestore
          .collection('tournaments')
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ Query successful: ${snapshot.docs.length} documents found');

      final tournaments = <TournamentModel>[];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        try {
          final tournament = TournamentModel.fromFirestore(doc);
          tournaments.add(tournament);
        } catch (e) {
          print('⚠️ Skipping corrupted tournament ${doc.id}: $e');
          // Continue processing other tournaments - don't fail the entire operation
          continue;
        }
      }

      // Update cache
      _tournamentCache = tournaments;
      _lastCacheUpdate = DateTime.now();

      print('✅ Processed ${tournaments.length} tournaments successfully');
      return tournaments;
    } catch (e) {
      print('❌ FALLBACK: Simple query failed, trying basic fetch: $e');

      try {
        // ULTIMATE FALLBACK: No ordering at all
        final snapshot = await _firestore.collection('tournaments').get();
        final tournaments = snapshot.docs
            .map((doc) {
              try {
                return TournamentModel.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .where((t) => t != null)
            .cast<TournamentModel>()
            .toList();

        // Sort client-side
        tournaments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print(
            '✅ FALLBACK SUCCESS: Retrieved ${tournaments.length} tournaments');
        return tournaments;
      } catch (fallbackError) {
        print('💀 COMPLETE FAILURE: $fallbackError');
        throw ServerException(
            'Unable to fetch tournaments. Please check your connection.');
      }
    }
  }

  /// PRODUCTION-SAFE: Single field query
  @override
  Future<List<TournamentModel>> getTournamentsByStatus(
      TournamentStatus status) async {
    try {
      print('🔥 GETTING TOURNAMENTS BY STATUS: ${status.name}');

      final snapshot = await _firestore
          .collection('tournaments')
          .where('status', isEqualTo: status.name)
          .get();

      final tournaments = snapshot.docs
          .map((doc) {
            try {
              return TournamentModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted tournament ${doc.id}: $e');
              return null;
            }
          })
          .where((t) => t != null)
          .cast<TournamentModel>()
          .toList();

      // Sort client-side by start date
      tournaments.sort((a, b) => a.startDate.compareTo(b.startDate));

      print(
          '✅ Found ${tournaments.length} tournaments with status: ${status.name}');
      return tournaments;
    } catch (e) {
      print('❌ FALLBACK: Status query failed, using getAllTournaments: $e');

      // GRACEFUL FALLBACK: Get all and filter client-side
      final allTournaments = await getAllTournaments();
      final filtered = allTournaments.where((t) => t.status == status).toList();

      print('✅ FALLBACK SUCCESS: Filtered to ${filtered.length} tournaments');
      return filtered;
    }
  }

  /// PRODUCTION-SAFE: Single field query
  @override
  Future<List<TournamentModel>> getTournamentsByType(
      TournamentType type) async {
    try {
      print('🔥 GETTING TOURNAMENTS BY TYPE: ${type.name}');

      final snapshot = await _firestore
          .collection('tournaments')
          .where('type', isEqualTo: type.name)
          .get();

      final tournaments = snapshot.docs
          .map((doc) {
            try {
              return TournamentModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted tournament ${doc.id}: $e');
              return null;
            }
          })
          .where((t) => t != null)
          .cast<TournamentModel>()
          .toList();

      // Sort client-side by creation date
      tournaments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
          '✅ Found ${tournaments.length} tournaments with type: ${type.name}');
      return tournaments;
    } catch (e) {
      print('❌ FALLBACK: Type query failed, using getAllTournaments: $e');

      // GRACEFUL FALLBACK: Get all and filter client-side
      final allTournaments = await getAllTournaments();
      final filtered = allTournaments.where((t) => t.type == type).toList();

      print('✅ FALLBACK SUCCESS: Filtered to ${filtered.length} tournaments');
      return filtered;
    }
  }

  @override
  Future<TournamentModel> getTournamentById(String tournamentId) async {
    try {
      final doc =
          await _firestore.collection('tournaments').doc(tournamentId).get();

      if (!doc.exists) {
        throw ServerException('Tournament not found');
      }

      return TournamentModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch tournament: $e');
    }
  }

  /// SIMPLE QUERY: No compound index needed
  @override
  Future<List<MatchModel>> getAllLiveMatches() async {
    try {
      print('🔥 GETTING ALL LIVE MATCHES: Simple status query');

      final snapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'inProgress')
          .get();

      final matches = snapshot.docs
          .map((doc) {
            try {
              return MatchModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted match ${doc.id}: $e');
              return null;
            }
          })
          .where((m) => m != null)
          .cast<MatchModel>()
          .toList();

      // Client-side filtering for live streamed and sorting
      final liveStreamMatches = matches.where((m) => m.isLiveStreamed).toList();
      liveStreamMatches.sort((a, b) => (b.actualStartTime ?? DateTime(1970))
          .compareTo(a.actualStartTime ?? DateTime(1970)));

      print('✅ Found ${liveStreamMatches.length} live streamed matches');
      return liveStreamMatches;
    } catch (e) {
      print('❌ Live matches query failed: $e');
      // Return empty list instead of failing
      return <MatchModel>[];
    }
  }

  // DEPRECATED METHODS - Kept for backward compatibility but log warnings

  @override
  Future<List<TournamentModel>> getTournaments({
    TournamentStatus? status,
    TournamentType? type,
    bool? isFeatured,
    int? limit,
  }) async {
    print(
        '⚠️ DEPRECATED: Using deprecated getTournaments - switch to getAllTournaments + client filtering');

    // Fallback to safe implementation
    final allTournaments = await getAllTournaments();

    var filtered = allTournaments;

    if (status != null) {
      filtered = filtered.where((t) => t.status == status).toList();
    }

    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    }

    if (isFeatured != null) {
      filtered = filtered.where((t) => t.isFeatured == isFeatured).toList();
    }

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  @override
  Future<List<TournamentModel>> getFeaturedTournaments() async {
    print(
        '⚠️ DEPRECATED: Using deprecated getFeaturedTournaments - switch to getAllTournaments + client filtering');

    // Safe fallback implementation
    final allTournaments = await getAllTournaments();
    final featured = allTournaments
        .where((t) => t.status == TournamentStatus.active && t.isFeatured)
        .toList();

    // Sort by start date
    featured.sort((a, b) => a.startDate.compareTo(b.startDate));

    return featured;
  }

  @override
  Future<List<TournamentModel>> getActiveTournaments() async {
    print(
        '⚠️ DEPRECATED: Using deprecated getActiveTournaments - switch to getTournamentsByStatus');

    return getTournamentsByStatus(TournamentStatus.active);
  }

  @override
  Future<bool> registerForTournament({
    required String tournamentId,
    required String userId,
    required String communityId,
  }) async {
    try {
      final registrationId = '${userId}_$tournamentId';

      // Use Firestore transaction for race condition safety
      return await _firestore.runTransaction<bool>(
        (transaction) async {
          try {
            // Check if user is already registered
            final registrationRef = _firestore
                .collection('tournament_registrations')
                .doc(registrationId);

            final existingRegistration = await transaction.get(registrationRef);
            if (existingRegistration.exists) {
              throw Exception('User already registered for this tournament');
            }

            // Get current tournament data
            final tournamentRef =
                _firestore.collection('tournaments').doc(tournamentId);

            final tournamentSnapshot = await transaction.get(tournamentRef);
            if (!tournamentSnapshot.exists) {
              throw Exception('Tournament not found');
            }

            final tournamentData = tournamentSnapshot.data()!;
            final registeredUserIds =
                List<String>.from(tournamentData['registeredUserIds'] ?? []);
            final maxPlayers = tournamentData['maxPlayers'] as int? ?? 0;
            final currentPlayers = registeredUserIds.length;

            // Check if tournament is full (race condition safe)
            if (maxPlayers > 0 && currentPlayers >= maxPlayers) {
              throw Exception('Tournament is full');
            }

            // Check tournament status
            final status = tournamentData['status'] as String? ?? '';
            if (status != 'registration_open') {
              throw Exception('Registration is not open for this tournament');
            }

            // Check if user is already in the list (double check)
            if (registeredUserIds.contains(userId)) {
              throw Exception('User already registered for this tournament');
            }

            // Create registration record
            transaction.set(registrationRef, {
              'userId': userId,
              'tournamentId': tournamentId,
              'communityId': communityId,
              'status': 'registered',
              'registeredAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Update tournament with new user (atomic operation)
            final updatedUserIds = [...registeredUserIds, userId];
            transaction.update(tournamentRef, {
              'registeredUserIds': updatedUserIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            print('✅ Tournament registration completed successfully');
            
            // Clear cache to ensure fresh tournament data is loaded
            _tournamentCache = null;
            _lastCacheUpdate = null;
            
            return true;
          } catch (e) {
            print('❌ Transaction error: $e');
            rethrow; // Re-throw to be caught by outer catch block
          }
        },
        timeout: const Duration(seconds: 10), // Add timeout to prevent hanging
      );
    } on FirebaseException catch (e) {
      final errorMsg = e.message ?? 'Firebase error occurred';
      print('❌ Firebase error during registration: $errorMsg (code: ${e.code})');
      
      if (e.code == 'aborted') {
        throw Exception(
            'Registration failed due to concurrent access. Please try again.');
      } else if (e.code == 'deadline-exceeded') {
        throw Exception('Registration timeout. Please check your connection and try again.');
      } else if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to register for this tournament.');
      }
      
      throw ServerException('Failed to register: $errorMsg');
    } catch (e) {
      print('❌ Error during tournament registration: $e');
      
      // Handle specific error types
      if (e.toString().contains('User already registered')) {
        throw Exception('You are already registered for this tournament');
      } else if (e.toString().contains('Tournament not found')) {
        throw Exception('Tournament no longer exists');
      } else if (e.toString().contains('Tournament is full')) {
        throw Exception('Tournament is full - no spots remaining');
      } else if (e.toString().contains('Registration is not open')) {
        throw Exception('Registration is closed for this tournament');
      }
      
      throw ServerException('Failed to register for tournament: $e');
    }
  }

  @override
  Future<bool> isUserRegistered({
    required String tournamentId,
    required String userId,
  }) async {
    try {
      final registrationId = '${userId}_$tournamentId';
      final doc = await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking registration status: $e');
      return false; // Safe default
    }
  }

  @override
  Future<List<MatchModel>> getPlayerMatches({
    required String playerId,
    MatchStatus? status,
    int? limit,
  }) async {
    try {
      // Simple queries - no compound indexes needed
      Query query1 = _firestore
          .collection('matches')
          .where('player1Id', isEqualTo: playerId);

      Query query2 = _firestore
          .collection('matches')
          .where('player2Id', isEqualTo: playerId);

      final results = await Future.wait([
        query1.get(),
        query2.get(),
      ]);

      final matches = <MatchModel>[];

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          try {
            final match = MatchModel.fromFirestore(doc);
            matches.add(match);
          } catch (e) {
            print('⚠️ Skipping corrupted match ${doc.id}: $e');
            continue;
          }
        }
      }

      // Client-side filtering and sorting
      var filtered = matches;

      if (status != null) {
        filtered = filtered.where((m) => m.status == status).toList();
      }

      // Remove duplicates and sort
      filtered = filtered.toSet().toList();
      filtered
          .sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      if (limit != null && filtered.length > limit) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e) {
      print('❌ Error getting player matches: $e');
      return <MatchModel>[]; // Safe default
    }
  }

  @override
  Future<List<MatchModel>> getTournamentMatches({
    required String tournamentId,
    MatchStatus? status,
    int? limit,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      var matches = snapshot.docs
          .map((doc) {
            try {
              return MatchModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted match ${doc.id}: $e');
              return null;
            }
          })
          .where((m) => m != null)
          .cast<MatchModel>()
          .toList();

      // Client-side filtering
      if (status != null) {
        matches = matches.where((m) => m.status == status).toList();
      }

      // Sort by scheduled date
      matches
          .sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      if (limit != null && matches.length > limit) {
        matches = matches.take(limit).toList();
      }

      return matches;
    } catch (e) {
      print('❌ Error getting tournament matches: $e');
      return <MatchModel>[]; // Safe default
    }
  }

  @override
  Future<MatchModel> getMatchById(String matchId) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();

      if (!doc.exists) {
        throw ServerException('Match not found');
      }

      return MatchModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch match: $e');
    }
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches({
    String? playerId,
    int? limit,
  }) async {
    try {
      // Simple query with basic filtering
      final snapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'scheduled')
          .get();

      var matches = snapshot.docs
          .map((doc) {
            try {
              return MatchModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted match ${doc.id}: $e');
              return null;
            }
          })
          .where((m) => m != null)
          .cast<MatchModel>()
          .toList();

      // Client-side filtering for upcoming and player
      final now = DateTime.now();
      matches = matches.where((m) => m.scheduledDateTime.isAfter(now)).toList();

      if (playerId != null) {
        matches = matches.where((m) => m.hasPlayer(playerId)).toList();
      }

      // Sort by scheduled date
      matches
          .sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      if (limit != null && matches.length > limit) {
        matches = matches.take(limit).toList();
      }

      return matches;
    } catch (e) {
      print('❌ Error getting upcoming matches: $e');
      return <MatchModel>[]; // Safe default
    }
  }

  @override
  Future<PlayerTournamentStats?> getPlayerStats({
    required String userId,
    required String tournamentId,
  }) async {
    try {
      final statsId = '${userId}_$tournamentId';
      final doc = await _firestore
          .collection('player_tournament_stats')
          .doc(statsId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return PlayerTournamentStats(
        id: doc.id,
        userId: data['userId'],
        tournamentId: data['tournamentId'],
        communityId: data['communityId'],
        totalPoints: data['totalPoints'] ?? 0,
        matchesPlayed: data['matchesPlayed'] ?? 0,
        matchesWon: data['matchesWon'] ?? 0,
        matchesLost: data['matchesLost'] ?? 0,
        communityRanking: data['communityRanking'] ?? 0,
        isActive: data['isActive'] ?? true,
        hasAdvanced: data['hasAdvanced'] ?? false,
        winPercentage: (data['winPercentage'] ?? 0.0).toDouble(),
        currentWinStreak: data['currentWinStreak'] ?? 0,
        longestWinStreak: data['longestWinStreak'] ?? 0,
        nextMatchId: data['nextMatchId'],
        nextMatchDate: data['nextMatchDate'] != null
            ? (data['nextMatchDate'] as Timestamp).toDate()
            : null,
        nextOpponentId: data['nextOpponentId'],
        nextOpponentName: data['nextOpponentName'],
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('❌ Error getting player stats: $e');
      return null; // Safe default
    }
  }

  @override
  Future<List<PlayerTournamentStats>> getTournamentLeaderboard({
    required String tournamentId,
    String? communityId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('player_tournament_stats')
          .where('tournamentId', isEqualTo: tournamentId);

      final snapshot = await query.get();
      var stats = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return PlayerTournamentStats(
                id: doc.id,
                userId: data['userId'],
                tournamentId: data['tournamentId'],
                communityId: data['communityId'],
                totalPoints: data['totalPoints'] ?? 0,
                matchesPlayed: data['matchesPlayed'] ?? 0,
                matchesWon: data['matchesWon'] ?? 0,
                matchesLost: data['matchesLost'] ?? 0,
                communityRanking: data['communityRanking'] ?? 0,
                isActive: data['isActive'] ?? true,
                hasAdvanced: data['hasAdvanced'] ?? false,
                winPercentage: (data['winPercentage'] ?? 0.0).toDouble(),
                currentWinStreak: data['currentWinStreak'] ?? 0,
                longestWinStreak: data['longestWinStreak'] ?? 0,
                nextMatchId: data['nextMatchId'],
                nextMatchDate: data['nextMatchDate'] != null
                    ? (data['nextMatchDate'] as Timestamp).toDate()
                    : null,
                nextOpponentId: data['nextOpponentId'],
                nextOpponentName: data['nextOpponentName'],
                lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
              );
            } catch (e) {
              print('⚠️ Skipping corrupted stats ${doc.id}: $e');
              return null;
            }
          })
          .where((s) => s != null)
          .cast<PlayerTournamentStats>()
          .toList();

      // Client-side filtering and sorting
      if (communityId != null) {
        stats = stats.where((s) => s.communityId == communityId).toList();
      }

      stats.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      if (limit != null && stats.length > limit) {
        stats = stats.take(limit).toList();
      }

      return stats;
    } catch (e) {
      print('❌ Error getting tournament leaderboard: $e');
      return <PlayerTournamentStats>[]; // Safe default
    }
  }

  @override
  Future<List<PlayerTournamentStats>> getCommunityLeaderboard({
    required String tournamentId,
    required String communityId,
    int? limit,
  }) async {
    return getTournamentLeaderboard(
      tournamentId: tournamentId,
      communityId: communityId,
      limit: limit,
    );
  }

  @override
  Future<List<TournamentModel>> searchTournaments({
    required String query,
    TournamentType? type,
    TournamentStatus? status,
  }) async {
    try {
      // Use getAllTournaments for consistent caching and fallback
      final allTournaments = await getAllTournaments();

      var filtered = allTournaments;

      // Client-side filtering
      if (type != null) {
        filtered = filtered.where((t) => t.type == type).toList();
      }

      if (status != null) {
        filtered = filtered.where((t) => t.status == status).toList();
      }

      // Text search
      filtered = filtered
          .where((tournament) =>
              tournament.name.toLowerCase().contains(query.toLowerCase()) ||
              tournament.description
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      return filtered;
    } catch (e) {
      print('❌ Error searching tournaments: $e');
      return <TournamentModel>[]; // Safe default
    }
  }

  @override
  Future<List<MatchModel>> searchMatches({
    required String query,
    String? tournamentId,
    MatchStatus? status,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('matches');

      if (tournamentId != null) {
        firestoreQuery =
            firestoreQuery.where('tournamentId', isEqualTo: tournamentId);
      }

      final snapshot = await firestoreQuery.get();
      var matches = snapshot.docs
          .map((doc) {
            try {
              return MatchModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted match ${doc.id}: $e');
              return null;
            }
          })
          .where((m) => m != null)
          .cast<MatchModel>()
          .toList();

      // Client-side filtering
      if (status != null) {
        matches = matches.where((m) => m.status == status).toList();
      }

      // Text search
      matches = matches
          .where((match) =>
              match.player1Name.toLowerCase().contains(query.toLowerCase()) ||
              match.player2Name.toLowerCase().contains(query.toLowerCase()) ||
              match.venue.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return matches;
    } catch (e) {
      print('❌ Error searching matches: $e');
      return <MatchModel>[]; // Safe default
    }
  }

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    try {
      final docRef = await _firestore
          .collection('tournaments')
          .add(tournament.toFirestore());

      // Clear cache
      _tournamentCache = null;

      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create tournament: $e');
    }
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournament.id)
          .update(tournament.toFirestore());

      // Clear cache
      _tournamentCache = null;
    } catch (e) {
      throw ServerException('Failed to update tournament: $e');
    }
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    try {
      await _firestore.collection('tournaments').doc(tournamentId).delete();

      // Clear cache
      _tournamentCache = null;
    } catch (e) {
      throw ServerException('Failed to delete tournament: $e');
    }
  }
}
