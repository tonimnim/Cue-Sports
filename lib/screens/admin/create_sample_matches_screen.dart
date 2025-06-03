import 'package:flutter/material.dart';
import 'package:pool_billiard_app/services/match_service.dart';

class CreateSampleMatchesScreen extends StatefulWidget {
  const CreateSampleMatchesScreen({Key? key}) : super(key: key);

  @override
  State<CreateSampleMatchesScreen> createState() =>
      _CreateSampleMatchesScreenState();
}

class _CreateSampleMatchesScreenState extends State<CreateSampleMatchesScreen> {
  final MatchService _matchService = MatchService();
  bool _isCreating = false;

  Future<void> _createSampleMatches() async {
    setState(() => _isCreating = true);

    try {
      // Sample tournament and player data
      const tournamentId = 'tournament_demo_2024';
      const tournamentName = 'Demo Championship 2024';
      const organizerId = 'admin_001';

      // Create 4 sample matches for player_001
      final sampleMatches = [
        {
          'round': 1,
          'matchNumber': 1,
          'player1Id': 'player_001',
          'player1Name': 'John Doe',
          'player2Id': 'player_002',
          'player2Name': 'Jane Smith',
          'scheduledTime': DateTime.now().add(Duration(days: 1)),
          'venue': 'Table 1',
          'refereeId': 'referee_001',
          'refereeName': 'Mike Johnson',
        },
        {
          'round': 1,
          'matchNumber': 2,
          'player1Id': 'player_003',
          'player1Name': 'Bob Wilson',
          'player2Id': 'player_004',
          'player2Name': 'Alice Brown',
          'scheduledTime': DateTime.now().add(Duration(days: 1, hours: 2)),
          'venue': 'Table 2',
          'refereeId': 'referee_002',
          'refereeName': 'Sarah Connor',
        },
        {
          'round': 2,
          'matchNumber': 1,
          'player1Id': 'player_001',
          'player1Name': 'John Doe',
          'player2Id': 'player_005',
          'player2Name': 'Charlie Davis',
          'scheduledTime': DateTime.now().add(Duration(days: 2)),
          'venue': 'Main Table',
          'refereeId': 'referee_001',
          'refereeName': 'Mike Johnson',
        },
        {
          'round': 2,
          'matchNumber': 2,
          'player1Id': 'player_006',
          'player1Name': 'Eve Martinez',
          'player2Id': 'player_001',
          'player2Name': 'John Doe',
          'scheduledTime': DateTime.now().add(Duration(days: 3)),
          'venue': 'Center Court',
          'refereeId': 'referee_003',
          'refereeName': 'Tom Anderson',
        },
      ];

      // Create each match
      for (var match in sampleMatches) {
        final matchId = await _matchService.createMatch(
          tournamentId: tournamentId,
          tournamentName: tournamentName,
          round: match['round'] as int,
          matchNumber: match['matchNumber'] as int,
          player1Id: match['player1Id'] as String,
          player1Name: match['player1Name'] as String,
          player2Id: match['player2Id'] as String,
          player2Name: match['player2Name'] as String,
          scheduledTime: match['scheduledTime'] as DateTime,
          venue: match['venue'] as String,
          refereeId: match['refereeId'] as String,
          refereeName: match['refereeName'] as String,
          organizerId: organizerId,
        );

        print('Created match: $matchId');
      }

      // Create one live match
      final liveMatchId = await _matchService.createMatch(
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        round: 1,
        matchNumber: 3,
        player1Id: 'player_001',
        player1Name: 'John Doe',
        player2Id: 'player_007',
        player2Name: 'Frank Garcia',
        scheduledTime: DateTime.now().subtract(Duration(hours: 1)),
        venue: 'Live Table',
        refereeId: 'referee_001',
        refereeName: 'Mike Johnson',
        organizerId: organizerId,
      );

      // Start the live match
      await _matchService.startMatch(liveMatchId);

      // Update score
      await _matchService.updateMatchScore(
        matchId: liveMatchId,
        player1Score: 3,
        player2Score: 2,
      );

      // Create one completed match
      final completedMatchId = await _matchService.createMatch(
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        round: 1,
        matchNumber: 4,
        player1Id: 'player_001',
        player1Name: 'John Doe',
        player2Id: 'player_008',
        player2Name: 'Grace Lee',
        scheduledTime: DateTime.now().subtract(Duration(days: 1)),
        venue: 'Table 3',
        refereeId: 'referee_002',
        refereeName: 'Sarah Connor',
        organizerId: organizerId,
      );

      // Start and complete the match
      await _matchService.startMatch(completedMatchId);
      await _matchService.updateMatchScore(
        matchId: completedMatchId,
        player1Score: 5,
        player2Score: 3,
      );
      await _matchService.completeMatch(
        matchId: completedMatchId,
        winnerId: 'player_001',
        winnerName: 'John Doe',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully created ${sampleMatches.length + 2} sample matches!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sample Matches'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_esports,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Sample Matches',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will create sample matches in your Firebase database for testing purposes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createSampleMatches,
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Matches'),
                ),
              ),
              const SizedBox(height: 48),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What will be created:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• 4 scheduled matches for player_001'),
                      Text('• 1 live match (in progress)'),
                      Text('• 1 completed match'),
                      Text('• Different rounds and opponents'),
                      Text('• Sample scores and match data'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
