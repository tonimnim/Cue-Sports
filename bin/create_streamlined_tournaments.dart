import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase/firebase_options.dart';

/// STREAMLINED Script - Only 8 Essential Collections
/// Embeds referee data, match scores, and streaming info into matches
/// Removes redundant collections like live_matches, match_scores, etc.

void main() async {
  print('🎯 Starting STREAMLINED tournament system (8 collections only)...');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    const currentUserId = 'uHBdKN0LhNcmvKycuVasItWalJH2';
    const currentUserName = 'Anthony Cheg';

    await createVenues(firestore, now);
    await createTournaments(firestore, now, currentUserId);
    await createRegistrations(firestore, now, currentUserId, currentUserName);
    await createMatches(firestore, now, currentUserId, currentUserName);
    await createBrackets(firestore, now);
    await createStats(firestore, now, currentUserId);
    await createLeaderboards(firestore, now, currentUserId, currentUserName);
    await createPayments(firestore, now, currentUserId);

    print('\n🎯 STREAMLINED Tournament system created!');
    print('📊 Only 8 Essential Collections:');
    print('   • tournament_venues');
    print('   • tournaments');
    print('   • tournament_registrations');
    print('   • matches (with embedded scores, referee, streaming)');
    print('   • tournament_brackets');
    print('   • player_tournament_stats');
    print('   • tournament_leaderboards');
    print('   • tournament_payments');
    print('\n✅ REDUCED FROM 14 to 8 Collections!');
    print('✨ $currentUserName registered & participating!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> createVenues(FirebaseFirestore firestore, DateTime now) async {
  print('\n📍 Creating venues...');
  final venues = [
    {
      'name': 'Nairobi Sports Club',
      'address': 'Ngong Road, Nairobi',
      'city': 'Nairobi',
      'capacity': 200,
      'tables': [
        {'number': 1, 'type': '9-foot', 'condition': 'excellent'},
        {'number': 2, 'type': '9-foot', 'condition': 'excellent'},
      ],
      'facilities': ['Parking', 'Restaurant', 'WiFi'],
      'contactInfo': {'phone': '+254-700-123456', 'manager': 'James Mwangi'},
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 100))),
    },
    {
      'name': 'Westlands Pool Arena',
      'address': 'Westlands Road, Nairobi',
      'city': 'Nairobi',
      'capacity': 150,
      'tables': [
        {'number': 1, 'type': '9-foot', 'condition': 'excellent'}
      ],
      'facilities': ['Parking', 'Cafe', 'WiFi'],
      'contactInfo': {'phone': '+254-700-234567', 'manager': 'Sarah Ochieng'},
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 80))),
    },
    {
      'name': 'Community Center',
      'address': 'Downtown, Nairobi',
      'city': 'Nairobi',
      'capacity': 80,
      'tables': [
        {'number': 1, 'type': '8-foot', 'condition': 'good'}
      ],
      'facilities': ['Parking', 'Basic Lighting'],
      'contactInfo': {'phone': '+254-700-345678', 'manager': 'Peter Kiprotich'},
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
    },
  ];

  final batch = firestore.batch();
  for (final venue in venues) {
    batch.set(firestore.collection('tournament_venues').doc(), venue);
  }
  await batch.commit();
  print('   ✅ Created ${venues.length} venues');
}

Future<void> createTournaments(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n🏆 Creating tournaments...');
  final tournaments = [
    {
      'name': 'National Championship 2025',
      'description': 'Premier national pool billiards championship',
      'type': 'national',
      'location': 'Nairobi',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 47))),
      'maxPlayers': 128,
      'entryFee': 2500.0,
      'isFeatured': true,
      'isNational': true,
      'prizePool': 500000.0,
      'venue': 'Nairobi Sports Club',
      'currentPlayers': 87,
      'sponsorName': 'Kenya Pool Federation',
      'status': 'registration_open',
      'registeredUserIds': [currentUserId, 'player_002', 'player_003'],
      'prizeStructure': {'1st': 200000, '2nd': 150000, '3rd': 100000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    },
    {
      'name': 'Beginner\'s Weekly Tournament',
      'description': 'Weekly tournament for beginners',
      'type': 'beginner',
      'location': 'Community Center',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'maxPlayers': 16,
      'entryFee': 500.0,
      'isFeatured': false,
      'isNational': false,
      'prizePool': 5000.0,
      'venue': 'Community Center',
      'currentPlayers': 14,
      'status': 'upcoming',
      'registeredUserIds': ['player_005', 'player_006'],
      'prizeStructure': {'1st': 2500, '2nd': 1500, '3rd': 1000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
    },
    {
      'name': 'Premier League Championship',
      'description': 'Professional tournament with live streaming',
      'type': 'professional',
      'location': 'Westlands',
      'startDate': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'endDate': Timestamp.fromDate(now.add(const Duration(hours: 6))),
      'maxPlayers': 64,
      'entryFee': 500.0,
      'isFeatured': true,
      'isNational': false,
      'prizePool': 100000.0,
      'venue': 'Westlands Pool Arena',
      'currentPlayers': 47,
      'sponsorName': 'Elite Cues Ltd',
      'status': 'in_progress',
      'registeredUserIds': [currentUserId, 'player_008', 'player_009'],
      'prizeStructure': {'1st': 50000, '2nd': 30000, '3rd': 20000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
    },
  ];

  final batch = firestore.batch();
  for (final tournament in tournaments) {
    batch.set(firestore.collection('tournaments').doc(), tournament);
  }
  await batch.commit();
  print('   ✅ Created ${tournaments.length} tournaments');
}

Future<void> createRegistrations(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n📝 Creating registrations...');
  final registrations = [
    {
      'tournamentId': 'national_championship_2025',
      'userId': currentUserId,
      'playerName': currentUserName,
      'status': 'confirmed',
      'paymentId': 'pay_001',
      'registeredAt':
          Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'notes': 'National championship registration',
    },
    {
      'tournamentId': 'premier_league_championship',
      'userId': currentUserId,
      'playerName': currentUserName,
      'status': 'confirmed',
      'paymentId': 'pay_002',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'notes': 'Professional level entry',
    },
    {
      'tournamentId': 'national_championship_2025',
      'userId': 'player_002',
      'playerName': 'John Kamau',
      'status': 'confirmed',
      'paymentId': 'pay_003',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
      'notes': 'Early bird registration',
    },
  ];

  final batch = firestore.batch();
  for (final registration in registrations) {
    batch.set(
        firestore.collection('tournament_registrations').doc(), registration);
  }
  await batch.commit();
  print('   ✅ Created ${registrations.length} registrations');
}

Future<void> createMatches(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n🎮 Creating matches (with embedded data)...');
  final matches = [
    {
      'tournamentId': 'premier_league_championship',
      'player1Id': 'player_009',
      'player1Name': 'David Kiprop',
      'player2Id': 'player_010',
      'player2Name': 'Samuel Mutua',
      'scheduledDateTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      'venue': 'Westlands Pool Arena',
      'tableNumber': 'Table 1',
      'status': 'in_progress',
      'bestOf': 5,
      'gameType': '8Ball',
      'player1Score': 2,
      'player2Score': 1,
      'actualStartTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'notes': 'Round 2 of 4 - Currently live',

      // EMBEDDED REFEREE DATA (no separate collection needed)
      'refereeId': 'referee_003',
      'refereeName': 'Mary Wanjiku',
      'refereeStatus': 'confirmed',

      // EMBEDDED STREAMING DATA (no separate live_streams collection)
      'youtubeStreamUrl': 'https://youtube.com/watch?v=live_match_001',
      'isLiveStreamed': true,
      'streamStatus': 'live',
      'viewerCount': 47,

      // EMBEDDED GAME SCORES (no separate match_scores collection)
      'gameScores': [
        {
          'gameNumber': 1,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': 'player_009',
          'duration': 18,
          'notes': 'Great break shot',
        },
        {
          'gameNumber': 2,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': 'player_009',
          'duration': 25,
          'notes': 'Safety battle',
        },
        {
          'gameNumber': 3,
          'player1Score': 0,
          'player2Score': 1,
          'winnerUserId': 'player_010',
          'duration': 22,
          'notes': 'Comeback win',
        }
      ],

      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
    },
    {
      'tournamentId': 'national_championship_2025',
      'player1Id': currentUserId,
      'player1Name': currentUserName,
      'player2Id': 'player_002',
      'player2Name': 'John Kamau',
      'scheduledDateTime':
          Timestamp.fromDate(now.add(const Duration(days: 45, hours: 10))),
      'venue': 'Nairobi Sports Club',
      'tableNumber': 'Table 1',
      'status': 'scheduled',
      'bestOf': 7,
      'gameType': '8Ball',
      'player1Score': 0,
      'player2Score': 0,
      'notes': 'First round match - National Championship',

      // EMBEDDED REFEREE DATA
      'refereeId': 'referee_001',
      'refereeName': 'Paul Mwangi',
      'refereeStatus': 'assigned',

      // EMBEDDED STREAMING DATA
      'youtubeStreamUrl': 'https://youtube.com/watch?v=example1',
      'isLiveStreamed': true,
      'streamStatus': 'scheduled',
      'viewerCount': 0,

      // EMPTY GAME SCORES (will be filled during match)
      'gameScores': [],

      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'updatedAt': Timestamp.fromDate(now),
    },
    {
      'tournamentId': 'premier_league_championship',
      'player1Id': currentUserId,
      'player1Name': currentUserName,
      'player2Id': 'player_008',
      'player2Name': 'Michael Omondi',
      'winnerId': currentUserId,
      'loserId': 'player_008',
      'scheduledDateTime':
          Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'venue': 'Westlands Pool Arena',
      'tableNumber': 'Table 2',
      'status': 'completed',
      'bestOf': 5,
      'gameType': '8Ball',
      'player1Score': 3,
      'player2Score': 1,
      'actualStartTime':
          Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 2))),
      'actualEndTime':
          Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 1))),
      'notes': 'Excellent competitive match',

      // EMBEDDED REFEREE DATA
      'refereeId': 'referee_002',
      'refereeName': 'Alice Njeri',
      'refereeStatus': 'completed',

      // NO STREAMING
      'youtubeStreamUrl': null,
      'isLiveStreamed': false,
      'streamStatus': 'none',
      'viewerCount': 0,

      // COMPLETE GAME SCORES
      'gameScores': [
        {
          'gameNumber': 1,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 15,
          'notes': 'Clean break'
        },
        {
          'gameNumber': 2,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 22,
          'notes': 'Strategic play'
        },
        {
          'gameNumber': 3,
          'player1Score': 0,
          'player2Score': 1,
          'winnerUserId': 'player_008',
          'duration': 28,
          'notes': 'Opponent comeback'
        },
        {
          'gameNumber': 4,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 19,
          'notes': 'Winning shot'
        },
      ],

      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    },
  ];

  final batch = firestore.batch();
  for (final match in matches) {
    batch.set(firestore.collection('matches').doc(), match);
  }
  await batch.commit();
  print(
      '   ✅ Created ${matches.length} matches (with embedded referee, scores, streaming)');
}

Future<void> createBrackets(FirebaseFirestore firestore, DateTime now) async {
  print('\n📊 Creating brackets...');
  final brackets = [
    {
      'tournamentId': 'national_championship_2025',
      'bracketType': 'single_elimination',
      'totalRounds': 7,
      'currentRound': 1,
      'bracketData': {
        'round_1': {
          'matches': ['match_001', 'match_002'],
          'completed': false
        },
        'round_2': {'matches': [], 'completed': false}
      },
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
    },
  ];

  final batch = firestore.batch();
  for (final bracket in brackets) {
    batch.set(firestore.collection('tournament_brackets').doc(), bracket);
  }
  await batch.commit();
  print('   ✅ Created ${brackets.length} brackets');
}

Future<void> createStats(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n📈 Creating stats...');
  final stats = [
    {
      'userId': currentUserId,
      'tournamentId': 'national_championship_2025',
      'matchesPlayed': 0,
      'matchesWon': 0,
      'gamesWon': 0,
      'gamesLost': 0,
      'winRate': 0.0,
      'tournamentPoints': 0,
      'nationalRank': 87,
      'achievements': [],
      'lastUpdated': Timestamp.fromDate(now),
    },
    {
      'userId': currentUserId,
      'tournamentId': 'premier_league_championship',
      'matchesPlayed': 1,
      'matchesWon': 1,
      'gamesWon': 3,
      'gamesLost': 1,
      'winRate': 100.0,
      'tournamentPoints': 10,
      'nationalRank': 12,
      'achievements': ['First Round Winner'],
      'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    },
  ];

  final batch = firestore.batch();
  for (final stat in stats) {
    batch.set(firestore.collection('player_tournament_stats').doc(), stat);
  }
  await batch.commit();
  print('   ✅ Created ${stats.length} stats');
}

Future<void> createLeaderboards(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n🏅 Creating leaderboards...');
  final leaderboards = [
    {
      'tournamentId': 'national_championship_2025',
      'playerRankings': [
        {
          'userId': 'player_elite_001',
          'playerName': 'Kevin Ochieng',
          'points': 25,
          'rank': 1
        },
        {
          'userId': 'player_elite_002',
          'playerName': 'Grace Wanjiru',
          'points': 20,
          'rank': 2
        },
        {
          'userId': currentUserId,
          'playerName': currentUserName,
          'points': 0,
          'rank': 87
        }
      ],
      'lastUpdated': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final leaderboard in leaderboards) {
    batch.set(
        firestore.collection('tournament_leaderboards').doc(), leaderboard);
  }
  await batch.commit();
  print('   ✅ Created ${leaderboards.length} leaderboards');
}

Future<void> createPayments(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n💳 Creating payments...');
  final payments = [
    {
      'tournamentId': 'national_championship_2025',
      'userId': currentUserId,
      'amount': 2500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_001',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'notes': 'National Championship entry',
    },
    {
      'tournamentId': 'premier_league_championship',
      'userId': currentUserId,
      'amount': 500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_002',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'notes': 'Premier League entry',
    },
  ];

  final batch = firestore.batch();
  for (final payment in payments) {
    batch.set(firestore.collection('tournament_payments').doc(), payment);
  }
  await batch.commit();
  print('   ✅ Created ${payments.length} payments');
}
