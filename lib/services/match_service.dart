import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new match
  Future<String> createMatch({
    required String tournamentId,
    required String tournamentName,
    required int round,
    required int matchNumber,
    required String player1Id,
    required String player1Name,
    required String player2Id,
    required String player2Name,
    required DateTime scheduledTime,
    required String venue,
    required String refereeId,
    required String refereeName,
    required String organizerId,
  }) async {
    try {
      // Generate unique match ID
      final matchId =
          '${tournamentId}_r${round}_m${matchNumber}_${DateTime.now().millisecondsSinceEpoch}';

      // Create match document
      await _firestore.collection('matches').doc(matchId).set({
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'round': round,
        'matchNumber': matchNumber,
        'player1Id': player1Id,
        'player1Name': player1Name,
        'player2Id': player2Id,
        'player2Name': player2Name,
        'status': 'scheduled',
        'scheduledTime': scheduledTime.toIso8601String(),
        'venue': venue,
        'refereeId': refereeId,
        'refereeName': refereeName,
        'organizerId': organizerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return matchId;
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  // Update match score
  Future<void> updateMatchScore({
    required String matchId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'score': {
          'player1': player1Score,
          'player2': player2Score,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update score: $e');
    }
  }

  // Start a match
  Future<void> startMatch(String matchId) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'status': 'in_progress',
        'startTime': DateTime.now().toIso8601String(),
        'isLive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start match: $e');
    }
  }

  // Complete a match
  Future<void> completeMatch({
    required String matchId,
    required String winnerId,
    required String winnerName,
  }) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();
      final startTime = DateTime.parse(doc.data()!['startTime']);
      final duration = DateTime.now().difference(startTime).inMinutes;

      await _firestore.collection('matches').doc(matchId).update({
        'status': 'completed',
        'winnerId': winnerId,
        'winnerName': winnerName,
        'endTime': DateTime.now().toIso8601String(),
        'duration': duration,
        'isLive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to complete match: $e');
    }
  }

  // Get player's recent matches
  Stream<QuerySnapshot> getPlayerMatches(String playerId, {int limit = 10}) {
    return _firestore
        .collection('matches')
        .where(Filter.or(
          Filter('player1Id', isEqualTo: playerId),
          Filter('player2Id', isEqualTo: playerId),
        ))
        .orderBy('scheduledTime', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get tournament matches
  Stream<QuerySnapshot> getTournamentMatches(String tournamentId) {
    return _firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('round')
        .orderBy('matchNumber')
        .snapshots();
  }

  // Get live matches
  Stream<QuerySnapshot> getLiveMatches() {
    return _firestore
        .collection('matches')
        .where('status', isEqualTo: 'in_progress')
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // Get upcoming matches for organizer
  Stream<QuerySnapshot> getOrganizerUpcomingMatches(String organizerId) {
    return _firestore
        .collection('matches')
        .where('organizerId', isEqualTo: organizerId)
        .where('status', whereIn: ['scheduled', 'in_progress'])
        .orderBy('scheduledTime')
        .snapshots();
  }

  // Batch create matches for a tournament round
  Future<void> createTournamentRoundMatches({
    required String tournamentId,
    required String tournamentName,
    required int round,
    required List<Map<String, dynamic>> matchPairings,
    required String organizerId,
  }) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < matchPairings.length; i++) {
        final pairing = matchPairings[i];
        final matchId =
            '${tournamentId}_r${round}_m${i + 1}_${DateTime.now().millisecondsSinceEpoch}';

        batch.set(_firestore.collection('matches').doc(matchId), {
          'tournamentId': tournamentId,
          'tournamentName': tournamentName,
          'round': round,
          'matchNumber': i + 1,
          'player1Id': pairing['player1Id'],
          'player1Name': pairing['player1Name'],
          'player2Id': pairing['player2Id'],
          'player2Name': pairing['player2Name'],
          'status': 'scheduled',
          'scheduledTime': pairing['scheduledTime'],
          'venue': pairing['venue'],
          'refereeId': pairing['refereeId'],
          'refereeName': pairing['refereeName'],
          'organizerId': organizerId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create tournament round matches: $e');
    }
  }

  // Archive old matches (to be run periodically)
  Future<void> archiveOldMatches({int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldMatches = await _firestore
          .collection('matches')
          .where('endTime', isLessThan: cutoffDate.toIso8601String())
          .where('status', isEqualTo: 'completed')
          .limit(500)
          .get();

      if (oldMatches.docs.isEmpty) return;

      final batch = _firestore.batch();
      final archiveYear = cutoffDate.year;

      for (var doc in oldMatches.docs) {
        // Copy to archive collection
        batch.set(
          _firestore.collection('matches_archive_$archiveYear').doc(doc.id),
          doc.data(),
        );

        // Delete from active collection
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to archive matches: $e');
    }
  }
}
