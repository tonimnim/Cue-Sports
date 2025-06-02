import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pool_billiard_app/firebase/firebase_options.dart';

Future<void> main() async {
  print('🔥 Initializing Firebase...');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('✅ Firebase initialized successfully!');

  // Sample tournaments data
  final tournaments = [
    {
      'id': 'tournament1',
      'name': 'Summer Championship 2024',
      'organizerId': 'community1',
      'startDate': Timestamp.fromDate(DateTime(2024, 6, 1)),
      'endDate': Timestamp.fromDate(DateTime(2024, 6, 15)),
      'status': 'in_progress',
      'description': 'Annual summer pool championship',
      'maxParticipants': 32,
      'currentParticipants': 16,
      'entryFee': 50.0,
      'prizePool': 1600.0,
      'venue': 'Main Sports Center',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'tournament2',
      'name': 'Winter League 2024',
      'organizerId': 'community2',
      'startDate': Timestamp.fromDate(DateTime(2024, 12, 1)),
      'endDate': Timestamp.fromDate(DateTime(2024, 12, 20)),
      'status': 'upcoming',
      'description': 'Winter league tournament',
      'maxParticipants': 24,
      'currentParticipants': 8,
      'entryFee': 30.0,
      'prizePool': 720.0,
      'venue': 'Winter Arena',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'tournament3',
      'name': 'Spring Open 2024',
      'organizerId': 'community1',
      'startDate': Timestamp.fromDate(DateTime(2024, 3, 1)),
      'endDate': Timestamp.fromDate(DateTime(2024, 3, 10)),
      'status': 'completed',
      'description': 'Spring open championship',
      'maxParticipants': 16,
      'currentParticipants': 16,
      'entryFee': 40.0,
      'prizePool': 640.0,
      'venue': 'Spring Arena',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // Sample matches data
  final matches = [
    // Scenario 1: Player playing in multiple tournaments
    {
      'id': 'match1',
      'tournamentId': 'tournament1',
      'round': 1,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player2',
      'status': 'completed',
      'score': {'player1': 5, 'player2': 3},
      'winnerId': 'player1',
      'startTime': Timestamp.fromDate(DateTime(2024, 6, 1, 14, 0)),
      'endTime': Timestamp.fromDate(DateTime(2024, 6, 1, 15, 30)),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'match2',
      'tournamentId': 'tournament2',
      'round': 1,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player3',
      'status': 'scheduled',
      'startTime': Timestamp.fromDate(DateTime(2024, 12, 1, 10, 0)),
      'venue': 'Winter Arena',
      'refereeId': 'referee2',
      'createdAt': FieldValue.serverTimestamp(),
    },

    // Scenario 2: Player's recent matches (4 matches for player1)
    {
      'id': 'match3',
      'tournamentId': 'tournament1',
      'round': 2,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player4',
      'status': 'completed',
      'score': {'player1': 5, 'player2': 2},
      'winnerId': 'player1',
      'startTime': Timestamp.fromDate(DateTime(2024, 6, 3, 14, 0)),
      'endTime': Timestamp.fromDate(DateTime(2024, 6, 3, 15, 0)),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'match4',
      'tournamentId': 'tournament1',
      'round': 3,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player5',
      'status': 'completed',
      'score': {'player1': 5, 'player2': 4},
      'winnerId': 'player1',
      'startTime': Timestamp.fromDate(DateTime(2024, 6, 5, 14, 0)),
      'endTime': Timestamp.fromDate(DateTime(2024, 6, 5, 15, 45)),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'match5',
      'tournamentId': 'tournament1',
      'round': 4,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player6',
      'status': 'in_progress',
      'startTime': Timestamp.fromDate(DateTime(2024, 6, 7, 14, 0)),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
      'createdAt': FieldValue.serverTimestamp(),
    },

    // Scenario 3: Different community leaders organizing tournaments
    {
      'id': 'match6',
      'tournamentId': 'tournament3',
      'round': 1,
      'matchNumber': 1,
      'player1Id': 'player7',
      'player2Id': 'player8',
      'status': 'completed',
      'score': {'player1': 5, 'player2': 3},
      'winnerId': 'player7',
      'startTime': Timestamp.fromDate(DateTime(2024, 3, 1, 10, 0)),
      'endTime': Timestamp.fromDate(DateTime(2024, 3, 1, 11, 30)),
      'venue': 'Spring Arena',
      'refereeId': 'referee3',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  try {
    print('\n📝 Writing tournaments to Firebase...');

    // Write tournaments to Firebase
    final batch = firestore.batch();

    for (var tournament in tournaments) {
      final docRef =
          firestore.collection('tournaments').doc(tournament['id'] as String);
      batch.set(docRef, tournament);
      print('  ✅ Queued tournament: ${tournament['name']}');
    }

    await batch.commit();
    print('🎉 All tournaments written successfully!');

    print('\n🏓 Writing matches to Firebase...');

    // Write matches to Firebase
    final matchBatch = firestore.batch();

    for (var match in matches) {
      final docRef = firestore.collection('matches').doc(match['id'] as String);
      matchBatch.set(docRef, match);
      print('  ✅ Queued match: ${match['id']} (${match['status']})');
    }

    await matchBatch.commit();
    print('🎉 All matches written successfully!');

    print('\n📊 Data Summary:');
    print('  Tournaments created: ${tournaments.length}');
    print('  Matches created: ${matches.length}');

    // Test queries to verify data
    print('\n🔍 Testing queries...');

    final player1Matches = await firestore
        .collection('matches')
        .where('player1Id', isEqualTo: 'player1')
        .get();
    print('  Player1 matches found: ${player1Matches.docs.length}');

    final tournament1Matches = await firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: 'tournament1')
        .get();
    print('  Tournament1 matches found: ${tournament1Matches.docs.length}');

    final completedMatches = await firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();
    print('  Completed matches found: ${completedMatches.docs.length}');

    print('\n✨ All done! Check your Firebase console to see the data.');
    print('🔗 Firebase Console: https://console.firebase.google.com/');
  } catch (e) {
    print('❌ Error writing to Firebase: $e');
  }
}
