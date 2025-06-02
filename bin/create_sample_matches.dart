import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pool_billiard_app/firebase/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase with the proper configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  // Sample data for different scenarios
  final tournaments = [
    {
      'id': 'tournament1',
      'name': 'Summer Championship 2024',
      'organizerId': 'community1',
      'startDate': DateTime(2024, 6, 1),
      'endDate': DateTime(2024, 6, 15),
      'status': 'in_progress',
    },
    {
      'id': 'tournament2',
      'name': 'Winter League 2024',
      'organizerId': 'community2',
      'startDate': DateTime(2024, 12, 1),
      'endDate': DateTime(2024, 12, 20),
      'status': 'upcoming',
    },
    {
      'id': 'tournament3',
      'name': 'Spring Open 2024',
      'organizerId': 'community1',
      'startDate': DateTime(2024, 3, 1),
      'endDate': DateTime(2024, 3, 10),
      'status': 'completed',
    },
  ];

  // Create tournaments
  for (var tournament in tournaments) {
    await firestore
        .collection('tournaments')
        .doc(tournament['id'] as String)
        .set(tournament);
  }

  // Sample matches for different scenarios
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
      'startTime': DateTime(2024, 6, 1, 14, 0),
      'endTime': DateTime(2024, 6, 1, 15, 30),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
    },
    {
      'id': 'match2',
      'tournamentId': 'tournament2',
      'round': 1,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player3',
      'status': 'scheduled',
      'startTime': DateTime(2024, 12, 1, 10, 0),
      'venue': 'Winter Arena',
      'refereeId': 'referee2',
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
      'startTime': DateTime(2024, 6, 3, 14, 0),
      'endTime': DateTime(2024, 6, 3, 15, 0),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
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
      'startTime': DateTime(2024, 6, 5, 14, 0),
      'endTime': DateTime(2024, 6, 5, 15, 45),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
    },
    {
      'id': 'match5',
      'tournamentId': 'tournament1',
      'round': 4,
      'matchNumber': 1,
      'player1Id': 'player1',
      'player2Id': 'player6',
      'status': 'in_progress',
      'startTime': DateTime(2024, 6, 7, 14, 0),
      'venue': 'Main Hall',
      'refereeId': 'referee1',
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
      'startTime': DateTime(2024, 3, 1, 10, 0),
      'endTime': DateTime(2024, 3, 1, 11, 30),
      'venue': 'Spring Arena',
      'refereeId': 'referee3',
    },
  ];

  // Create matches
  for (var match in matches) {
    await firestore.collection('matches').doc(match['id'] as String).set(match);
  }

  print('Sample data created successfully!');

  // Example queries to test the data
  print('\nExample Queries:');

  // Query 1: Get all matches for player1
  final player1Matches = await firestore
      .collection('matches')
      .where('player1Id', isEqualTo: 'player1')
      .get();
  print('\nPlayer1 matches: ${player1Matches.docs.length}');

  // Query 2: Get recent completed matches for player1
  final recentMatches = await firestore
      .collection('matches')
      .where('player1Id', isEqualTo: 'player1')
      .where('status', isEqualTo: 'completed')
      .orderBy('startTime', descending: true)
      .limit(4)
      .get();
  print('Recent completed matches for Player1: ${recentMatches.docs.length}');

  // Query 3: Get matches for a specific tournament
  final tournamentMatches = await firestore
      .collection('matches')
      .where('tournamentId', isEqualTo: 'tournament1')
      .get();
  print('Tournament1 matches: ${tournamentMatches.docs.length}');

  // Query 4: Get matches organized by a specific community
  final communityMatches = await firestore
      .collection('matches')
      .where('tournamentId', whereIn: ['tournament1', 'tournament3']).get();
  print('Community1 matches: ${communityMatches.docs.length}');
}
