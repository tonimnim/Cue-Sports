import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase/firebase_options.dart';

/// Script to create comprehensive tournament system data in Firebase
/// Includes tournaments, matches, registrations, venues, and all related collections
/// Run this script to populate the database with properly structured tournament documents

void main() async {
  print('🏆 Starting tournament system creation script...');

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
    const currentUserEmail = 'anthonychege599@gmail.com';

    await createTournamentVenues(firestore, now);
    await createTournaments(firestore, now, currentUserId);
    await createTournamentRegistrations(
        firestore, now, currentUserId, currentUserName);
    await createMatches(firestore, now, currentUserId, currentUserName);
    await createTournamentBrackets(firestore, now);
    await createPlayerTournamentStats(firestore, now, currentUserId);
    await createTournamentLeaderboards(
        firestore, now, currentUserId, currentUserName);
    await createMatchScores(firestore, now, currentUserId);
    await createLiveMatches(firestore, now, currentUserId, currentUserName);
    await createRefereeAssignments(firestore, now);
    await createTournamentAnnouncements(firestore, now);
    await createTournamentSchedules(firestore, now);
    await createTournamentPayments(firestore, now, currentUserId);
    await createLiveStreams(firestore, now);

    print('\n🎯 Tournament system successfully created!');
    print('📊 Summary:');
    print('   • 3 Tournament venues');
    print('   • 3 Tournaments (1 national, others community-based)');
    print('   • 3 Tournament registrations');
    print('   • 3 Matches');
    print('   • 1 Tournament bracket');
    print('   • 2 Player statistics records');
    print('   • 1 Tournament leaderboard');
    print('   • 2 Match scores');
    print('   • 1 Live match');
    print('   • 1 Referee assignment');
    print('   • 1 Tournament announcement');
    print('   • 1 Tournament schedule');
    print('   • 2 Tournament payments');
    print('   • 2 Live streams');
    print(
        '\n✨ Current user ($currentUserName) is registered for multiple tournaments!');
    print('🚀 Script completed successfully!');
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
      'id': 'nairobi_sports_club_001',
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
      'id': 'westlands_arena_002',
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
      'id': 'mombasa_beach_club_003',
      'name': 'Mombasa Beach Club',
      'address': 'Diani Beach Road, Mombasa',
      'city': 'Mombasa',
      'coordinates': {'lat': -4.3179, 'lng': 39.5776},
      'capacity': 120,
      'tables': [
        {'number': 1, 'type': '8-foot', 'condition': 'good'},
        {'number': 2, 'type': '8-foot', 'condition': 'good'},
      ],
      'facilities': ['Parking', 'Beach View', 'Restaurant', 'Restrooms'],
      'contactInfo': {
        'phone': '+254-700-345678',
        'email': 'events@mombasabeach.co.ke',
        'manager': 'Ali Hassan'
      },
      'images': ['https://via.placeholder.com/800x400?text=Mombasa+Beach+Club'],
      'isActive': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      'updatedAt': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final venue in venues) {
    final docRef =
        firestore.collection('tournament_venues').doc(venue['id'] as String);
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
      'id': 'national_championship_2025',
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
      'id': 'downtown_weekly_001',
      'name': 'Downtown Players Weekly',
      'description':
          'Weekly tournament for Downtown Players community members.',
      'createdByAdminId': 'admin_downtown_001',
      'type': 'beginner',
      'location': 'Downtown',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
      'maxPlayers': 32,
      'entryFee': 500.0,
      'isFeatured': false,
      'isNational': false,
      'prizePool': 8000.0,
      'venue': 'Downtown Pool Hall',
      'currentPlayers': 24,
      'sponsorName': null,
      'rules': [
        'Community members only',
        'Best of 3 games',
        'Friendly competition'
      ],
      'bannerImageUrl': null,
      'youtubeChannelId': null,
      'registeredUserIds': ['player_005', 'player_006', 'player_007'],
      'status': 'registration_open',
      'isPublic': true,
      'communityIds': ['downtown_players_001'],
      'imageUrl': null,
      'prizeStructure': {'1st': 4000, '2nd': 2400, '3rd': 1600},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin_downtown_001',
    },
    {
      'id': 'westlands_pro_tournament_001',
      'name': 'Westlands Professional Tournament',
      'description':
          'High-stakes professional tournament for advanced players.',
      'createdByAdminId': 'admin_westlands_003',
      'type': 'professional',
      'location': 'Westlands',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 21))),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 22))),
      'maxPlayers': 64,
      'entryFee': 1500.0,
      'isFeatured': true,
      'isNational': false,
      'prizePool': 50000.0,
      'venue': 'Westlands Pool Arena',
      'currentPlayers': 45,
      'sponsorName': 'Elite Cues Ltd',
      'rules': ['Professional level only', 'Best of 5 games', 'Timed matches'],
      'bannerImageUrl':
          'https://via.placeholder.com/1200x400?text=Westlands+Pro+Tournament',
      'youtubeChannelId': 'UC_WestlandsWarriors',
      'registeredUserIds': [currentUserId, 'player_008', 'player_009'],
      'status': 'registration_open',
      'isPublic': true,
      'communityIds': ['westlands_warriors_003'],
      'imageUrl': 'https://via.placeholder.com/800x600?text=Pro+Tournament',
      'prizeStructure': {'1st': 25000, '2nd': 15000, '3rd': 10000},
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin_westlands_003',
    },
  ];

  final batch = firestore.batch();
  for (final tournament in tournaments) {
    final docRef =
        firestore.collection('tournaments').doc(tournament['id'] as String);
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
      'id': 'reg_001',
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
      'id': 'reg_002',
      'tournamentId': 'westlands_pro_tournament_001',
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
      'id': 'reg_003',
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
    final docRef = firestore
        .collection('tournament_registrations')
        .doc(registration['id'] as String);
    batch.set(docRef, registration);
  }
  await batch.commit();
  print('   ✅ Created ${registrations.length} tournament registrations');
}

Future<void> createMatches(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n🎮 Creating matches...');

  final matches = [
    {
      'id': 'match_001',
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
      'refereeId': 'referee_001',
      'notes': 'First round match',
      'youtubeStreamUrl': 'https://youtube.com/watch?v=example1',
      'isLiveStreamed': true,
      'bracketRound': 1,
      'bracketPosition': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'updatedAt': Timestamp.fromDate(now),
    },
    {
      'id': 'match_002',
      'tournamentId': 'westlands_pro_tournament_001',
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
      'refereeId': 'referee_002',
      'notes': 'Great competitive match',
      'youtubeStreamUrl': null,
      'isLiveStreamed': false,
      'bracketRound': 1,
      'bracketPosition': 2,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    },
    {
      'id': 'match_live_001',
      'tournamentId': 'westlands_pro_tournament_001',
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
      'refereeId': 'referee_003',
      'notes': 'Currently live - intense match',
      'youtubeStreamUrl': 'https://youtube.com/watch?v=live_match_001',
      'isLiveStreamed': true,
      'bracketRound': 2,
      'bracketPosition': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
    },
  ];

  final batch = firestore.batch();
  for (final match in matches) {
    final docRef = firestore.collection('matches').doc(match['id'] as String);
    batch.set(docRef, match);
  }
  await batch.commit();
  print('   ✅ Created ${matches.length} matches');
}

Future<void> createTournamentBrackets(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📊 Creating tournament brackets...');

  final brackets = [
    {
      'id': 'bracket_001',
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
    final docRef = firestore
        .collection('tournament_brackets')
        .doc(bracket['id'] as String);
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
      'id': 'stats_${currentUserId}_national_championship_2025',
      'userId': currentUserId,
      'tournamentId': 'national_championship_2025',
      'communityId': null,
      'matchesPlayed': 1,
      'matchesWon': 0,
      'matchesLost': 0,
      'gamesWon': 0,
      'gamesLost': 0,
      'winRate': 0.0,
      'tournamentPoints': 0,
      'communityRank': 0,
      'nationalRank': 45,
      'achievements': [],
      'lastUpdated': Timestamp.fromDate(now),
    },
    {
      'id': 'stats_${currentUserId}_westlands_pro_tournament_001',
      'userId': currentUserId,
      'tournamentId': 'westlands_pro_tournament_001',
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
    final docRef = firestore
        .collection('player_tournament_stats')
        .doc(stat['id'] as String);
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
      'id': 'leaderboard_national_championship_2025',
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
          'userId': currentUserId,
          'playerName': currentUserName,
          'points': 10,
          'matchesWon': 1,
          'matchesPlayed': 1,
          'rank': 45
        }
      ],
      'lastUpdated': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final leaderboard in leaderboards) {
    final docRef = firestore
        .collection('tournament_leaderboards')
        .doc(leaderboard['id'] as String);
    batch.set(docRef, leaderboard);
  }
  await batch.commit();
  print('   ✅ Created ${leaderboards.length} tournament leaderboards');
}

Future<void> createMatchScores(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n🎯 Creating match scores...');

  final scores = [
    {
      'id': 'score_match_002_game_1',
      'matchId': 'match_002',
      'gameNumber': 1,
      'player1Score': 1,
      'player2Score': 0,
      'winnerUserId': currentUserId,
      'gameType': '8Ball',
      'duration': 15, // minutes
      'notes': 'Clean break and run',
      'timestamp':
          Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 2))),
    },
    {
      'id': 'score_match_002_game_2',
      'matchId': 'match_002',
      'gameNumber': 2,
      'player1Score': 1,
      'player2Score': 0,
      'winnerUserId': currentUserId,
      'gameType': '8Ball',
      'duration': 22,
      'notes': 'Strategic safety play',
      'timestamp': Timestamp.fromDate(
          now.subtract(const Duration(days: 2, hours: 1, minutes: 45))),
    },
  ];

  final batch = firestore.batch();
  for (final score in scores) {
    final docRef =
        firestore.collection('match_scores').doc(score['id'] as String);
    batch.set(docRef, score);
  }
  await batch.commit();
  print('   ✅ Created ${scores.length} match scores');
}

Future<void> createLiveMatches(FirebaseFirestore firestore, DateTime now,
    String currentUserId, String currentUserName) async {
  print('\n🔴 Creating live matches...');

  final liveMatches = [
    {
      'id': 'live_match_001',
      'matchId': 'match_live_001',
      'tournamentId': 'westlands_pro_tournament_001',
      'player1Id': 'player_009',
      'player2Id': 'player_010',
      'currentScore': {'player1': 2, 'player2': 1},
      'streamUrl': 'https://youtube.com/watch?v=live_match_001',
      'viewerCount': 47,
      'startTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'status': 'live',
      'lastUpdated':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 1))),
    },
  ];

  final batch = firestore.batch();
  for (final liveMatch in liveMatches) {
    final docRef =
        firestore.collection('live_matches').doc(liveMatch['id'] as String);
    batch.set(docRef, liveMatch);
  }
  await batch.commit();
  print('   ✅ Created ${liveMatches.length} live matches');
}

Future<void> createRefereeAssignments(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n👨‍⚖️ Creating referee assignments...');

  final assignments = [
    {
      'id': 'ref_assign_001',
      'matchId': 'match_001',
      'refereeId': 'referee_001',
      'refereeName': 'Paul Mwangi',
      'assignedBy': 'admin_national_001',
      'assignedAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      'status': 'confirmed',
      'notes': 'Experienced national level referee',
    },
  ];

  final batch = firestore.batch();
  for (final assignment in assignments) {
    final docRef = firestore
        .collection('referee_assignments')
        .doc(assignment['id'] as String);
    batch.set(docRef, assignment);
  }
  await batch.commit();
  print('   ✅ Created ${assignments.length} referee assignments');
}

Future<void> createTournamentAnnouncements(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📢 Creating tournament announcements...');

  final announcements = [
    {
      'id': 'announce_001',
      'tournamentId': 'national_championship_2025',
      'title': 'Registration Deadline Extended',
      'message':
          'Due to high demand, registration deadline has been extended by one week.',
      'type': 'general',
      'createdBy': 'admin_national_001',
      'targetAudience': 'all',
      'isImportant': true,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
    },
  ];

  final batch = firestore.batch();
  for (final announcement in announcements) {
    final docRef = firestore
        .collection('tournament_announcements')
        .doc(announcement['id'] as String);
    batch.set(docRef, announcement);
  }
  await batch.commit();
  print('   ✅ Created ${announcements.length} tournament announcements');
}

Future<void> createTournamentSchedules(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📅 Creating tournament schedules...');

  final schedules = [
    {
      'id': 'schedule_001',
      'tournamentId': 'national_championship_2025',
      'date': Timestamp.fromDate(now.add(const Duration(days: 45))),
      'matches': ['match_001'],
      'venue': 'Nairobi Sports Club',
      'startTime':
          Timestamp.fromDate(now.add(const Duration(days: 45, hours: 9))),
      'endTime':
          Timestamp.fromDate(now.add(const Duration(days: 45, hours: 18))),
      'notes': 'First round matches',
      'createdBy': 'admin_national_001',
      'lastUpdated': Timestamp.fromDate(now),
    },
  ];

  final batch = firestore.batch();
  for (final schedule in schedules) {
    final docRef = firestore
        .collection('tournament_schedules')
        .doc(schedule['id'] as String);
    batch.set(docRef, schedule);
  }
  await batch.commit();
  print('   ✅ Created ${schedules.length} tournament schedules');
}

Future<void> createTournamentPayments(
    FirebaseFirestore firestore, DateTime now, String currentUserId) async {
  print('\n💳 Creating tournament payments...');

  final payments = [
    {
      'id': 'payment_001',
      'tournamentId': 'national_championship_2025',
      'userId': currentUserId,
      'registrationId': 'reg_001',
      'amount': 2500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_001',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'refundedAt': null,
      'notes': 'M-Pesa payment successful',
    },
    {
      'id': 'payment_002',
      'tournamentId': 'westlands_pro_tournament_001',
      'userId': currentUserId,
      'registrationId': 'reg_002',
      'amount': 1500.0,
      'paymentMethod': 'mpesa',
      'paymentStatus': 'completed',
      'transactionId': 'MPESA_TXN_002',
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'refundedAt': null,
      'notes': 'M-Pesa payment successful',
    },
  ];

  final batch = firestore.batch();
  for (final payment in payments) {
    final docRef = firestore
        .collection('tournament_payments')
        .doc(payment['id'] as String);
    batch.set(docRef, payment);
  }
  await batch.commit();
  print('   ✅ Created ${payments.length} tournament payments');
}

Future<void> createLiveStreams(
    FirebaseFirestore firestore, DateTime now) async {
  print('\n📺 Creating live streams...');

  final streams = [
    {
      'id': 'stream_001',
      'tournamentId': 'national_championship_2025',
      'matchId': 'match_001',
      'streamUrl': 'https://youtube.com/watch?v=example1',
      'streamKey': 'yt_key_001',
      'platform': 'youtube',
      'status': 'scheduled',
      'viewerCount': 0,
      'startTime':
          Timestamp.fromDate(now.add(const Duration(days: 45, hours: 10))),
      'endTime': null,
      'recordingUrl': null,
    },
    {
      'id': 'stream_002',
      'tournamentId': 'westlands_pro_tournament_001',
      'matchId': 'match_live_001',
      'streamUrl': 'https://youtube.com/watch?v=live_match_001',
      'streamKey': 'yt_key_002',
      'platform': 'youtube',
      'status': 'live',
      'viewerCount': 47,
      'startTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'endTime': null,
      'recordingUrl': null,
    },
  ];

  final batch = firestore.batch();
  for (final stream in streams) {
    final docRef =
        firestore.collection('live_streams').doc(stream['id'] as String);
    batch.set(docRef, stream);
  }
  await batch.commit();
  print('   ✅ Created ${streams.length} live streams');
}
