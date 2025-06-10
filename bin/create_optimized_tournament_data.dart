import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase/firebase_options.dart';

/// OPTIMIZED Script to create streamlined tournament system data in Firebase
/// Only 8 essential collections - no redundancy
/// Merges match_scores into matches, removes live_matches, etc.

void main() async {
  print('🏆 Starting OPTIMIZED tournament system creation script...');

  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );

    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Current user details from logs
    const currentUserId = 'uHBdKN0LhNcmvKycuVasItWalJH2';
    const currentUserName = 'Anthony Cheg';

    await createTournamentVenues(firestore, now);
    await createTournaments(firestore, now, currentUserId);
    await createTournamentRegistrations(
        firestore, now, currentUserId, currentUserName);
    await createMatches(firestore, now, currentUserId, currentUserName);
    await createTournamentBrackets(firestore, now);
    await createPlayerTournamentStats(firestore, now, currentUserId);
    await createTournamentLeaderboards(
        firestore, now, currentUserId, currentUserName);
    await createTournamentPayments(firestore, now, currentUserId);

    print('\n🎯 OPTIMIZED Tournament system successfully created!');
    print('📊 Summary - Only Essential Collections:');
    print('   • 3 Tournament venues');
    print('   • 3 Tournaments (1 national featured)');
    print('   • 3 Tournament registrations');
    print('   • 3 Matches (with embedded scores & referee data)');
    print('   • 1 Tournament bracket');
    print('   • 2 Player statistics records');
    print('   • 1 Tournament leaderboard');
    print('   • 2 Tournament payments');
    print('\n✅ TOTAL: 8 Collections (instead of 14)');
    print(
        '✨ Current user ($currentUserName) is registered for multiple tournaments!');
    print('🚀 Optimized script completed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> createTournamentVenues(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📍 Creating tournament venues...');

  final venues = [
    {
      'name': 'Nairobi Sports Club',
      'address': 'Ngong Road, Nairobi',
      'city': 'Nairobi',
      'coordinates': {'lat': -1.3064, 'lng': 36.7867},
      'capacity': 200,
      'tables': [
        {'number': 1, 'type': '9-foot', 'condition': 'excellent'},
        {'number': 2, 'type': '9-foot', 'condition': 'excellent'},
        {'number': 3, 'type': '8-foot', 'condition': 'good'},
        {'number': 4, 'type': '8-foot', 'condition': 'good'},
      ],
      'facilities': [
        'Parking',
        'Restaurant',
        'Restrooms',
        'WiFi',
        'Air Conditioning'
      ],
      'contactInfo': {
        'phone': '+254-700-123456',
        'email': 'events@nairobisportsclub.co.ke',
        'manager': 'James Mwangi'
      },
      'images': [
        'https://via.placeholder.com/800x400?text=Nairobi+Sports+Club+Main',
        'https://via.placeholder.com/800x400?text=Pool+Tables'
      ],
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 100))),
      'updatedAt': Timestamp.fromDate(now),
    },
    {
      'name': 'Westlands Pool Arena',
      'address': 'Westlands Road, Nairobi',
      'city': 'Nairobi',
      'coordinates': {'lat': -1.2667, 'lng': 36.8086},
      'capacity': 150,
      'tables': [
        {'number': 1, 'type': '9-foot', 'condition': 'excellent'},
        {'number': 2, 'type': '9-foot', 'condition': 'excellent'},
        {'number': 3, 'type': '9-foot', 'condition': 'good'},
      ],
      'facilities': ['Parking', 'Cafe', 'Restrooms', 'WiFi'],
      'contactInfo': {
        'phone': '+254-700-234567',
        'email': 'info@westlandsarena.com',
        'manager': 'Sarah Ochieng'
      },
      'images': ['https://via.placeholder.com/800x400?text=Westlands+Arena'],
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 80))),
      'updatedAt': Timestamp.fromDate(now),
    },
    {
      'name': 'Community Center',
      'address': 'Downtown, Nairobi',
      'city': 'Nairobi',
      'coordinates': {'lat': -1.2864, 'lng': 36.8172},
      'capacity': 80,
      'tables': [
        {'number': 1, 'type': '8-foot', 'condition': 'good'},
        {'number': 2, 'type': '8-foot', 'condition': 'fair'},
      ],
      'facilities': ['Parking', 'Restrooms', 'Basic Lighting'],
      'contactInfo': {
        'phone': '+254-700-345678',
        'email': 'community@downtown.co.ke',
        'manager': 'Peter Kiprotich'
      },
      'images': ['https://via.placeholder.com/800x400?text=Community+Center'],
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      'updatedAt': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (int i = 0; i < venues.length; i++) {
    final venue = venues[i];
    final docRef = firestore.collection('tournament_venues').doc();
    batch.set(docRef, venue);
  }
  await batch.commit();
  print('   ✅ Created ${venues.length} tournament venues');
}

Future<void> createTournaments(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n🏆 Creating tournaments...');

  final tournaments = [
    {
      'name': 'National Championship 2025',
      'description':
          'The premier national pool billiards championship bringing together the best players from across Kenya.',
      'createdByAdminId': 'admin_national_001',
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
      'rules': [
        'Professional 8-ball rules apply',
        'Best of 7 games in finals',
        'Dress code strictly enforced',
        'No coaching during matches'
      ],
      'bannerImageUrl':
          'https://via.placeholder.com/1200x400?text=National+Championship+2025',
      'youtubeChannelId': 'UC_KenyaPoolFederation',
      'registeredUserIds': [
        currentUserId,
        'player_002',
        'player_003',
        'player_004'
      ],
      'status': 'registration_open',
      'isPublic': true,
      'communityIds': [],
      'imageUrl':
          'https://via.placeholder.com/800x600?text=National+Championship',
      'prizeStructure': {
        '1st': 200000,
        '2nd': 150000,
        '3rd': 100000,
        '4th': 50000
      },
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin_national_001',
    },
    {
      'name': 'Beginner\'s Weekly Tournament',
      'description':
          'Weekly tournament for beginner players looking to improve their skills in a friendly environment.',
      'createdByAdminId': 'admin_downtown_001',
      'type': 'beginner',
      'location': 'Community Center',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'maxPlayers': 16,
      'entryFee': 500.0,
      'isFeatured': false,
      'isNational': false,
      'prizePool': 5000.0,
      'venue': 'Community Center',
      'currentPlayers': 14,
      'sponsorName': null,
      'rules': [
        'Beginner level only',
        'Best of 3 games',
        'Friendly competition',
        'Entry Fee: KSh 500'
      ],
      'bannerImageUrl': null,
      'youtubeChannelId': null,
      'registeredUserIds': ['player_005', 'player_006', 'player_007'],
      'status': 'upcoming',
      'isPublic': true,
      'communityIds': ['downtown_players_001'],
      'imageUrl': null,
      'prizeStructure': {'1st': 2500, '2nd': 1500, '3rd': 1000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin_downtown_001',
    },
    {
      'name': 'Premier League Championship',
      'description':
          'Professional level tournament for advanced players with live YouTube streaming.',
      'createdByAdminId': 'admin_westlands_003',
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
      'rules': [
        'Professional level only',
        'Best of 5 games',
        'Timed matches',
        'Live streaming available'
      ],
      'bannerImageUrl':
          'https://via.placeholder.com/1200x400?text=Premier+League+Championship',
      'youtubeChannelId': 'UC_WestlandsWarriors',
      'registeredUserIds': [currentUserId, 'player_008', 'player_009'],
      'status': 'in_progress',
      'isPublic': true,
      'communityIds': ['westlands_warriors_003'],
      'imageUrl': 'https://via.placeholder.com/800x600?text=Premier+League',
      'prizeStructure': {'1st': 50000, '2nd': 30000, '3rd': 20000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin_westlands_003',
    },
  ];

  final batch = firestore.batch();
  for (final tournament in tournaments) {
    final docRef = firestore.collection('tournaments').doc();
    batch.set(docRef, tournament);
  }
  await batch.commit();
  print('   ✅ Created ${tournaments.length} tournaments');
}

Future<void> createTournamentRegistrations(FirebaseFirestore firestore,
    DateTime now, String currentUserId, String currentUserName) async {
  print('\n📝 Creating tournament registrations...');

  final registrations = [
    {
      'tournamentId': 'national_championship_2025',
      'userId': currentUserId,
      'playerName': currentUserName,
      'communityId': null,
      'status': 'confirmed',
      'paymentId': 'pay_001',
      'registeredAt':
          Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now),
      'notes': 'Regular registration',
    },
    {
      'tournamentId': 'premier_league_championship',
      'userId': currentUserId,
      'playerName': currentUserName,
      'communityId': null,
      'status': 'confirmed',
      'paymentId': 'pay_002',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'updatedAt': Timestamp.fromDate(now),
      'notes': 'Professional level entry',
    },
    {
      'tournamentId': 'national_championship_2025',
      'userId': 'player_002',
      'playerName': 'John Kamau',
      'communityId': 'downtown_players_001',
      'status': 'confirmed',
      'paymentId': 'pay_003',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
      'updatedAt': Timestamp.fromDate(now),
      'notes': 'Early bird registration',
    },
  ];

  final batch = firestore.batch();
  for (final registration in registrations) {
    final docRef = firestore.collection('tournament_registrations').doc();
    batch.set(docRef, registration);
  }
  await batch.commit();
  print('   ✅ Created ${registrations.length} tournament registrations');
}

Future<void> createMatches(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n🎮 Creating matches (with embedded scores & referee data)...');

  final matches = [
    {
      'tournamentId': 'premier_league_championship',
      'player1Id': 'player_009',
      'player1Name': 'David Kiprop',
      'player1Avatar': null,
      'player2Id': 'player_010',
      'player2Name': 'Samuel Mutua',
      'player2Avatar': null,
      'winnerId': null,
      'loserId': null,
      'scheduledDateTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      'venue': 'Westlands Pool Arena',
      'tableNumber': 'Table 1',
      'status': 'in_progress',
      'bestOf': 5,
      'gameType': '8Ball',
      'player1Score': 2,
      'player2Score': 1,
      'player1Points': 6,
      'player2Points': 3,
      'actualStartTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'actualEndTime': null,
      'createdByCommunityAdminId': 'admin_westlands_003',
      'updatedByCommunityAdminId': null,
      // EMBEDDED REFEREE DATA (instead of separate collection)
      'refereeId': 'referee_003',
      'refereeName': 'Mary Wanjiku',
      'refereeAssignedBy': 'admin_westlands_003',
      'refereeStatus': 'confirmed',
      'notes': 'Currently live - Round 2 of 4',
      // EMBEDDED LIVE STREAMING DATA (instead of separate collection)
      'youtubeStreamUrl': 'https://youtube.com/watch?v=live_match_001',
      'isLiveStreamed': true,
      'streamStatus': 'live',
      'viewerCount': 47,
      'streamStartTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      // EMBEDDED GAME SCORES (instead of separate match_scores collection)
      'gameScores': [
        {
          'gameNumber': 1,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': 'player_009',
          'duration': 18,
          'notes': 'Great break shot',
          'timestamp':
              Timestamp.fromDate(now.subtract(const Duration(minutes: 40)))
        },
        {
          'gameNumber': 2,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': 'player_009',
          'duration': 25,
          'notes': 'Safety battle',
          'timestamp':
              Timestamp.fromDate(now.subtract(const Duration(minutes: 20)))
        },
        {
          'gameNumber': 3,
          'player1Score': 0,
          'player2Score': 1,
          'winnerUserId': 'player_010',
          'duration': 22,
          'notes': 'Comeback win',
          'timestamp':
              Timestamp.fromDate(now.subtract(const Duration(minutes: 5)))
        }
      ],
      'bracketRound': 2,
      'bracketPosition': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
    },
    {
      'tournamentId': 'national_championship_2025',
      'player1Id': currentUserId,
      'player1Name': currentUserName,
      'player1Avatar': null,
      'player2Id': 'player_002',
      'player2Name': 'John Kamau',
      'player2Avatar': null,
      'winnerId': null,
      'loserId': null,
      'scheduledDateTime':
          Timestamp.fromDate(now.add(const Duration(days: 45, hours: 10))),
      'venue': 'Nairobi Sports Club',
      'tableNumber': 'Table 1',
      'status': 'scheduled',
      'bestOf': 7,
      'gameType': '8Ball',
      'player1Score': 0,
      'player2Score': 0,
      'player1Points': 0,
      'player2Points': 0,
      'actualStartTime': null,
      'actualEndTime': null,
      'createdByCommunityAdminId': 'admin_national_001',
      'updatedByCommunityAdminId': null,
      // EMBEDDED REFEREE DATA
      'refereeId': 'referee_001',
      'refereeName': 'Paul Mwangi',
      'refereeAssignedBy': 'admin_national_001',
      'refereeStatus': 'assigned',
      'notes': 'First round match - National Championship',
      // EMBEDDED STREAMING DATA
      'youtubeStreamUrl': 'https://youtube.com/watch?v=example1',
      'isLiveStreamed': true,
      'streamStatus': 'scheduled',
      'viewerCount': 0,
      'streamStartTime': null,
      // EMPTY GAME SCORES (will be filled during match)
      'gameScores': [],
      'bracketRound': 1,
      'bracketPosition': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'updatedAt': Timestamp.fromDate(now),
    },
    {
      'tournamentId': 'premier_league_championship',
      'player1Id': currentUserId,
      'player1Name': currentUserName,
      'player2Id': 'player_008',
      'player2Name': 'Michael Omondi',
      'player2Avatar': null,
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
      'player1Points': 10,
      'player2Points': 3,
      'actualStartTime':
          Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 2))),
      'actualEndTime':
          Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 1))),
      'createdByCommunityAdminId': 'admin_westlands_003',
      'updatedByCommunityAdminId': 'admin_westlands_003',
      // EMBEDDED REFEREE DATA
      'refereeId': 'referee_002',
      'refereeName': 'Alice Njeri',
      'refereeAssignedBy': 'admin_westlands_003',
      'refereeStatus': 'completed',
      'notes': 'Excellent competitive match',
      // NO STREAMING
      'youtubeStreamUrl': null,
      'isLiveStreamed': false,
      'streamStatus': 'none',
      'viewerCount': 0,
      'streamStartTime': null,
      // COMPLETE GAME SCORES
      'gameScores': [
        {
          'gameNumber': 1,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 15,
          'notes': 'Clean break and run',
          'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 2, hours: 2)))
        },
        {
          'gameNumber': 2,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 22,
          'notes': 'Strategic safety play',
          'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 2, hours: 1, minutes: 45)))
        },
        {
          'gameNumber': 3,
          'player1Score': 0,
          'player2Score': 1,
          'winnerUserId': 'player_008',
          'duration': 28,
          'notes': 'Opponent comeback',
          'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 2, hours: 1, minutes: 30)))
        },
        {
          'gameNumber': 4,
          'player1Score': 1,
          'player2Score': 0,
          'winnerUserId': currentUserId,
          'duration': 19,
          'notes': 'Winning shot',
          'timestamp': Timestamp.fromDate(
              now.subtract(const Duration(days: 2, hours: 1, minutes: 15)))
        }
      ],
      'bracketRound': 1,
      'bracketPosition': 2,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    },
  ];

  final batch = firestore.batch();
  for (final match in matches) {
    final docRef = firestore.collection('matches').doc();
    batch.set(docRef, match);
  }
  await batch.commit();
  print(
      '   ✅ Created ${matches.length} matches (with embedded scores & referee data)');
}

Future<void> createTournamentBrackets(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📊 Creating tournament brackets...');

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
      'updatedAt': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final bracket in brackets) {
    final docRef = firestore.collection('tournament_brackets').doc();
    batch.set(docRef, bracket);
  }
  await batch.commit();
  print('   ✅ Created ${brackets.length} tournament brackets');
}

Future<void> createPlayerTournamentStats(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n📈 Creating player tournament stats...');

  final stats = [
    {
      'userId': currentUserId,
      'tournamentId': 'national_championship_2025',
      'communityId': null,
      'matchesPlayed': 0,
      'matchesWon': 0,
      'matchesLost': 0,
      'gamesWon': 0,
      'gamesLost': 0,
      'winRate': 0.0,
      'tournamentPoints': 0,
      'communityRank': 0,
      'nationalRank': 87, // Rank among all registered players
      'achievements': [],
      'lastUpdated': Timestamp.fromDate(now),
    },
    {
      'userId': currentUserId,
      'tournamentId': 'premier_league_championship',
      'communityId': null,
      'matchesPlayed': 1,
      'matchesWon': 1,
      'matchesLost': 0,
      'gamesWon': 3,
      'gamesLost': 1,
      'winRate': 100.0,
      'tournamentPoints': 10,
      'communityRank': 0,
      'nationalRank': 12,
      'achievements': ['First Round Winner'],
      'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    },
  ];

  final batch = firestore.batch();
  for (final stat in stats) {
    final docRef = firestore.collection('player_tournament_stats').doc();
    batch.set(docRef, stat);
  }
  await batch.commit();
  print('   ✅ Created ${stats.length} player tournament stats');
}

Future<void> createTournamentLeaderboards(FirebaseFirestore firestore,
    DateTime now, String currentUserId, String currentUserName) async {
  print('\n🏅 Creating tournament leaderboards...');

  final leaderboards = [
    {
      'tournamentId': 'national_championship_2025',
      'communityId': null,
      'playerRankings': [
        {
          'userId': 'player_elite_001',
          'playerName': 'Kevin Ochieng',
          'points': 25,
          'matchesWon': 3,
          'matchesPlayed': 3,
          'rank': 1
        },
        {
          'userId': 'player_elite_002',
          'playerName': 'Grace Wanjiru',
          'points': 20,
          'matchesWon': 2,
          'matchesPlayed': 2,
          'rank': 2
        },
        {
          'userId': currentUserId,
          'playerName': currentUserName,
          'points': 0,
          'matchesWon': 0,
          'matchesPlayed': 0,
          'rank': 87
        }
      ],
      'lastUpdated': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final leaderboard in leaderboards) {
    final docRef = firestore.collection('tournament_leaderboards').doc();
    batch.set(docRef, leaderboard);
  }
  await batch.commit();
  print('   ✅ Created ${leaderboards.length} tournament leaderboards');
}

Future<void> createTournamentPayments(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n💳 Creating tournament payments...');

  final payments = [
    {
      'tournamentId': 'national_championship_2025',
      'userId': currentUserId,
      'registrationId': 'reg_001',
      'amount': 2500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_001',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'refundedAt': null,
      'notes': 'M-Pesa payment successful - National Championship',
    },
    {
      'tournamentId': 'premier_league_championship',
      'userId': currentUserId,
      'registrationId': 'reg_002',
      'amount': 500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_002',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'refundedAt': null,
      'notes': 'M-Pesa payment successful - Premier League',
    },
  ];

  final batch = firestore.batch();
  for (final payment in payments) {
    final docRef = firestore.collection('tournament_payments').doc();
    batch.set(docRef, payment);
  }
  await batch.commit();
  print('   ✅ Created ${payments.length} tournament payments');
}
