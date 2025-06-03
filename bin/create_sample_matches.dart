import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pool_billiard_app/firebase/firebase_options.dart';

Future<void> main() async {
  print('🔥 Initializing Firebase...');

  // Initialize Firebase - same as in your app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('✅ Firebase initialized successfully!');

  try {
    // Create matches collection with best practices
    await createMatchesCollection(firestore);

    // Create sample data
    await createSampleTournaments(firestore);
    await createSampleMatches(firestore);

    // Test queries
    await testQueries(firestore);

    print('\n✨ All done! Check your Firebase console to see the data.');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> createMatchesCollection(FirebaseFirestore firestore) async {
  print('\n📊 Setting up matches collection structure...');

  // The collection will be created automatically when we add documents
  // But let's add a metadata document to track collection info
  await firestore.collection('_metadata').doc('matches').set({
    'version': '1.0',
    'createdAt': FieldValue.serverTimestamp(),
    'indexes': [
      'tournamentId + round + matchNumber',
      'player1Id + status + startTime',
      'player2Id + status + startTime',
      'organizerId + status + scheduledTime',
      'status + scheduledTime',
    ],
    'description': 'Collection for tracking all pool matches',
  });

  print('✅ Matches collection structure defined');
}

Future<void> createSampleTournaments(FirebaseFirestore firestore) async {
  print('\n📋 Creating sample tournaments...');

  final batch = firestore.batch();

  // Tournament 1 - Active tournament
  batch.set(firestore.collection('tournaments').doc('tournament_summer_2024'), {
    'name': 'Summer Championship 2024',
    'organizerId': 'community_admin_001',
    'organizerName': 'John\'s Pool Hall', // Denormalized for fast access
    'startDate': DateTime(2024, 6, 1).toIso8601String(),
    'endDate': DateTime(2024, 6, 15).toIso8601String(),
    'status': 'in_progress',
    'description': 'Annual summer pool championship',
    'maxParticipants': 32,
    'currentParticipants': 16,
    'entryFee': 50.0,
    'prizePool': 1600.0,
    'venue': 'Main Sports Center',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // Tournament 2 - Upcoming tournament
  batch.set(firestore.collection('tournaments').doc('tournament_winter_2024'), {
    'name': 'Winter League 2024',
    'organizerId': 'community_admin_002',
    'organizerName': 'Winter Arena Club', // Denormalized
    'startDate': DateTime(2024, 12, 1).toIso8601String(),
    'endDate': DateTime(2024, 12, 20).toIso8601String(),
    'status': 'upcoming',
    'description': 'Winter league tournament',
    'maxParticipants': 24,
    'currentParticipants': 8,
    'entryFee': 30.0,
    'prizePool': 720.0,
    'venue': 'Winter Arena',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // Tournament 3 - Completed tournament
  batch.set(firestore.collection('tournaments').doc('tournament_spring_2024'), {
    'name': 'Spring Open 2024',
    'organizerId': 'community_admin_001',
    'organizerName': 'John\'s Pool Hall', // Denormalized
    'startDate': DateTime(2024, 3, 1).toIso8601String(),
    'endDate': DateTime(2024, 3, 10).toIso8601String(),
    'status': 'completed',
    'description': 'Spring open championship',
    'maxParticipants': 16,
    'currentParticipants': 16,
    'entryFee': 40.0,
    'prizePool': 640.0,
    'venue': 'Spring Arena',
    'winnerId': 'player_007', // Tournament winner
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
  print('✅ Sample tournaments created');
}

Future<void> createSampleMatches(FirebaseFirestore firestore) async {
  print('\n🏓 Creating sample matches...');

  final batch = firestore.batch();
  final now = DateTime.now();

  // Generate unique match IDs using timestamp
  String generateMatchId(String tournamentId, int round, int matchNumber) {
    return '${tournamentId}_r${round}_m${matchNumber}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Match 1 - Player1 completed match in tournament 1
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_summer_2024', 1, 1)),
      {
        'tournamentId': 'tournament_summer_2024',
        'tournamentName': 'Summer Championship 2024', // Denormalized
        'round': 1,
        'matchNumber': 1,
        'player1Id': 'player_001',
        'player1Name': 'John Doe', // Denormalized for fast display
        'player2Id': 'player_002',
        'player2Name': 'Jane Smith', // Denormalized
        'status': 'completed',
        'score': {
          'player1': 5,
          'player2': 3,
        },
        'winnerId': 'player_001',
        'winnerName': 'John Doe', // Denormalized
        'scheduledTime': DateTime(2024, 6, 1, 14, 0).toIso8601String(),
        'startTime': DateTime(2024, 6, 1, 14, 5).toIso8601String(),
        'endTime': DateTime(2024, 6, 1, 15, 30).toIso8601String(),
        'duration': 85, // minutes
        'venue': 'Table 1',
        'refereeId': 'referee_001',
        'refereeName': 'Mike Johnson', // Denormalized
        'organizerId': 'community_admin_001',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Match 2 - Player1 scheduled match in tournament 2
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_winter_2024', 1, 1)),
      {
        'tournamentId': 'tournament_winter_2024',
        'tournamentName': 'Winter League 2024',
        'round': 1,
        'matchNumber': 1,
        'player1Id': 'player_001',
        'player1Name': 'John Doe',
        'player2Id': 'player_003',
        'player2Name': 'Bob Wilson',
        'status': 'scheduled',
        'scheduledTime': DateTime(2024, 12, 1, 10, 0).toIso8601String(),
        'venue': 'Main Table',
        'refereeId': 'referee_002',
        'refereeName': 'Sarah Connor',
        'organizerId': 'community_admin_002',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Match 3 - Player1 second round match (completed)
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_summer_2024', 2, 1)),
      {
        'tournamentId': 'tournament_summer_2024',
        'tournamentName': 'Summer Championship 2024',
        'round': 2,
        'matchNumber': 1,
        'player1Id': 'player_001',
        'player1Name': 'John Doe',
        'player2Id': 'player_004',
        'player2Name': 'Alice Brown',
        'status': 'completed',
        'score': {
          'player1': 5,
          'player2': 2,
        },
        'winnerId': 'player_001',
        'winnerName': 'John Doe',
        'scheduledTime': DateTime(2024, 6, 3, 14, 0).toIso8601String(),
        'startTime': DateTime(2024, 6, 3, 14, 0).toIso8601String(),
        'endTime': DateTime(2024, 6, 3, 15, 0).toIso8601String(),
        'duration': 60,
        'venue': 'Table 2',
        'refereeId': 'referee_001',
        'refereeName': 'Mike Johnson',
        'organizerId': 'community_admin_001',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Match 4 - Player1 semifinal (completed)
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_summer_2024', 3, 1)),
      {
        'tournamentId': 'tournament_summer_2024',
        'tournamentName': 'Summer Championship 2024',
        'round': 3,
        'matchNumber': 1,
        'player1Id': 'player_001',
        'player1Name': 'John Doe',
        'player2Id': 'player_005',
        'player2Name': 'Charlie Davis',
        'status': 'completed',
        'score': {
          'player1': 5,
          'player2': 4,
        },
        'winnerId': 'player_001',
        'winnerName': 'John Doe',
        'scheduledTime': DateTime(2024, 6, 5, 14, 0).toIso8601String(),
        'startTime': DateTime(2024, 6, 5, 14, 0).toIso8601String(),
        'endTime': DateTime(2024, 6, 5, 15, 45).toIso8601String(),
        'duration': 105,
        'venue': 'Center Table',
        'refereeId': 'referee_001',
        'refereeName': 'Mike Johnson',
        'organizerId': 'community_admin_001',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Match 5 - Player1 current live match
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_summer_2024', 4, 1)),
      {
        'tournamentId': 'tournament_summer_2024',
        'tournamentName': 'Summer Championship 2024',
        'round': 4,
        'matchNumber': 1,
        'player1Id': 'player_001',
        'player1Name': 'John Doe',
        'player2Id': 'player_006',
        'player2Name': 'Eve Martinez',
        'status': 'in_progress',
        'score': {
          'player1': 3,
          'player2': 2,
        },
        'scheduledTime':
            DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'startTime':
            DateTime.now().subtract(Duration(minutes: 45)).toIso8601String(),
        'venue': 'Final Table',
        'refereeId': 'referee_001',
        'refereeName': 'Mike Johnson',
        'organizerId': 'community_admin_001',
        'isLive': true, // For real-time filtering
        'viewers': 156, // Live viewers count
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Match 6 - Different players in completed tournament
  batch.set(
      firestore
          .collection('matches')
          .doc(generateMatchId('tournament_spring_2024', 1, 1)),
      {
        'tournamentId': 'tournament_spring_2024',
        'tournamentName': 'Spring Open 2024',
        'round': 1,
        'matchNumber': 1,
        'player1Id': 'player_007',
        'player1Name': 'Frank Garcia',
        'player2Id': 'player_008',
        'player2Name': 'Grace Lee',
        'status': 'completed',
        'score': {
          'player1': 5,
          'player2': 3,
        },
        'winnerId': 'player_007',
        'winnerName': 'Frank Garcia',
        'scheduledTime': DateTime(2024, 3, 1, 10, 0).toIso8601String(),
        'startTime': DateTime(2024, 3, 1, 10, 0).toIso8601String(),
        'endTime': DateTime(2024, 3, 1, 11, 30).toIso8601String(),
        'duration': 90,
        'venue': 'Spring Arena Table 1',
        'refereeId': 'referee_003',
        'refereeName': 'Tom Anderson',
        'organizerId': 'community_admin_001',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  await batch.commit();
  print('✅ Sample matches created');
}

Future<void> testQueries(FirebaseFirestore firestore) async {
  print('\n🔍 Testing queries...');

  // Query 1: Get player's recent matches
  print('\n📊 Player 001 recent matches:');
  final playerMatches = await firestore
      .collection('matches')
      .where(Filter.or(
        Filter('player1Id', isEqualTo: 'player_001'),
        Filter('player2Id', isEqualTo: 'player_001'),
      ))
      .orderBy('scheduledTime', descending: true)
      .limit(5)
      .get();

  print('  Found ${playerMatches.docs.length} matches for player_001');
  for (var doc in playerMatches.docs) {
    final data = doc.data();
    print(
        '  - ${data['tournamentName']} Round ${data['round']}: ${data['status']}');
  }

  // Query 2: Get tournament matches
  print('\n🏆 Summer Championship matches:');
  final tournamentMatches = await firestore
      .collection('matches')
      .where('tournamentId', isEqualTo: 'tournament_summer_2024')
      .orderBy('round')
      .orderBy('matchNumber')
      .get();

  print('  Found ${tournamentMatches.docs.length} matches');

  // Query 3: Get live matches
  print('\n🔴 Live matches:');
  final liveMatches = await firestore
      .collection('matches')
      .where('status', isEqualTo: 'in_progress')
      .get();

  print('  Found ${liveMatches.docs.length} live matches');

  // Query 4: Community admin's matches
  print('\n👤 Community admin matches:');
  final adminMatches = await firestore
      .collection('matches')
      .where('organizerId', isEqualTo: 'community_admin_001')
      .where('status', whereIn: ['scheduled', 'in_progress']).get();

  print('  Found ${adminMatches.docs.length} upcoming/live matches for admin');
}

// Additional helper functions for production use

Future<void> archiveOldMatches(FirebaseFirestore firestore) async {
  // Archive matches older than 90 days
  final cutoffDate = DateTime.now().subtract(Duration(days: 90));

  final oldMatches = await firestore
      .collection('matches')
      .where('endTime', isLessThan: cutoffDate.toIso8601String())
      .where('status', isEqualTo: 'completed')
      .limit(500) // Process in batches
      .get();

  if (oldMatches.docs.isEmpty) {
    print('No matches to archive');
    return;
  }

  final batch = firestore.batch();

  for (var doc in oldMatches.docs) {
    // Move to archive collection
    batch.set(
      firestore.collection('matches_archive_${cutoffDate.year}').doc(doc.id),
      doc.data(),
    );

    // Delete from active collection
    batch.delete(doc.reference);
  }

  await batch.commit();
  print('Archived ${oldMatches.docs.length} matches');
}
