import 'dart:convert';

Future<void> main() async {
  // Simple JSON data structure that represents what would be in Firebase

  // Sample tournaments
  final tournaments = [
    {
      'id': 'tournament1',
      'name': 'Summer Championship 2024',
      'organizerId': 'community1',
      'startDate': '2024-06-01T00:00:00Z',
      'endDate': '2024-06-15T00:00:00Z',
      'status': 'in_progress',
    },
    {
      'id': 'tournament2',
      'name': 'Winter League 2024',
      'organizerId': 'community2',
      'startDate': '2024-12-01T00:00:00Z',
      'endDate': '2024-12-20T00:00:00Z',
      'status': 'upcoming',
    },
    {
      'id': 'tournament3',
      'name': 'Spring Open 2024',
      'organizerId': 'community1',
      'startDate': '2024-03-01T00:00:00Z',
      'endDate': '2024-03-10T00:00:00Z',
      'status': 'completed',
    },
  ];

  // Sample matches demonstrating different scenarios
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
      'startTime': '2024-06-01T14:00:00Z',
      'endTime': '2024-06-01T15:30:00Z',
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
      'startTime': '2024-12-01T10:00:00Z',
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
      'startTime': '2024-06-03T14:00:00Z',
      'endTime': '2024-06-03T15:00:00Z',
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
      'startTime': '2024-06-05T14:00:00Z',
      'endTime': '2024-06-05T15:45:00Z',
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
      'startTime': '2024-06-07T14:00:00Z',
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
      'startTime': '2024-03-01T10:00:00Z',
      'endTime': '2024-03-01T11:30:00Z',
      'venue': 'Spring Arena',
      'refereeId': 'referee3',
    },
  ];

  print('=== SAMPLE TOURNAMENT AND MATCH DATA ===\n');

  print('TOURNAMENTS:');
  for (var tournament in tournaments) {
    print('Tournament: ${tournament['name']} (${tournament['id']})');
    print('  Organizer: ${tournament['organizerId']}');
    print('  Status: ${tournament['status']}');
    print('  Date: ${tournament['startDate']} to ${tournament['endDate']}');
    print('');
  }

  print('MATCHES:');
  for (var match in matches) {
    print('Match: ${match['id']} (${match['status']})');
    print('  Tournament: ${match['tournamentId']}');
    print('  Round: ${match['round']}, Match: ${match['matchNumber']}');
    print('  Players: ${match['player1Id']} vs ${match['player2Id']}');
    if (match['score'] != null) {
      print('  Score: ${match['score']}');
      print('  Winner: ${match['winnerId']}');
    }
    print('  Time: ${match['startTime']}');
    print('  Venue: ${match['venue']}');
    print('');
  }

  // Example queries
  print('=== EXAMPLE QUERIES ===\n');

  // Query 1: Get all matches for player1
  var player1Matches = matches
      .where((match) =>
          match['player1Id'] == 'player1' || match['player2Id'] == 'player1')
      .toList();
  print('Player1 total matches: ${player1Matches.length}');

  // Query 2: Get recent completed matches for player1
  var recentMatches = matches
      .where((match) =>
          (match['player1Id'] == 'player1' ||
              match['player2Id'] == 'player1') &&
          match['status'] == 'completed')
      .toList();
  recentMatches.sort((a, b) => DateTime.parse(b['startTime'] as String)
      .compareTo(DateTime.parse(a['startTime'] as String)));
  print('Player1 recent completed matches: ${recentMatches.take(4).length}');

  // Query 3: Get matches for a specific tournament
  var tournamentMatches =
      matches.where((match) => match['tournamentId'] == 'tournament1').toList();
  print('Tournament1 matches: ${tournamentMatches.length}');

  // Query 4: Get matches organized by community1
  var community1Tournaments = tournaments
      .where((t) => t['organizerId'] == 'community1')
      .map((t) => t['id'])
      .toSet();
  var communityMatches = matches
      .where((match) => community1Tournaments.contains(match['tournamentId']))
      .toList();
  print('Community1 organized matches: ${communityMatches.length}');

  print('\n=== JSON OUTPUT FOR FIREBASE ===\n');
  print('Tournaments JSON:');
  print(const JsonEncoder.withIndent('  ').convert(tournaments));
  print('\nMatches JSON:');
  print(const JsonEncoder.withIndent('  ').convert(matches));
}
