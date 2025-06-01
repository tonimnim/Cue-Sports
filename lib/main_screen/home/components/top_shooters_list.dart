import 'package:flutter/material.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user_ranking.dart';
import 'package:pool_billiard_app/core/services/ranking_service.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;

class TopShootersList extends StatefulWidget {
  final List<TopShooter> shooters;
  final VoidCallback onSeeAllTap;
  final String? communityId; // Optional: if provided, shows community top players

  const TopShootersList({
    Key? key,
    required this.shooters,
    required this.onSeeAllTap,
    this.communityId,
  }) : super(key: key);

  @override
  State<TopShootersList> createState() => _TopShootersListState();
}

class _TopShootersListState extends State<TopShootersList> {
  List<UserRanking> _topPlayers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTopPlayers();
  }

  Future<void> _loadTopPlayers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final rankingService = di.sl<RankingService>();
      List<UserRanking> players;
      
      if (widget.communityId != null) {
        // Load community top players
        players = await rankingService.getCommunityTopPlayers(
          widget.communityId!,
          limit: 4,
        );
      } else {
        // Load national top players
        players = await rankingService.getNationalTopPlayers(limit: 4);
      }
      
      if (mounted) {
        setState(() {
          _topPlayers = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.communityId != null ? 'Top community players' : 'Top shooters',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: widget.onSeeAllTap,
              child: const Text(
                'see all',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // List container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 51), // 0.2 * 255 ≈ 51
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Column(
                  children: _topPlayers.isNotEmpty
                      ? List.generate(_topPlayers.length, (index) {
                          final player = _topPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                // Rank
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _getRankColor(index + 1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Player name
                                Expanded(
                                  child: Text(
                                    _getPlayerDisplayName(player),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Win percentage
                                Text(
                                  '${player.winPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      : [
                          // If no players loaded, show placeholder items
                          for (int i = 0; i < 4; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 128), // 0.5 * 255 ≈ 128
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      '---',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '---%',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return const Color(0xFF0F4A22); // App green
    }
  }

  String _getPlayerDisplayName(UserRanking player) {
    // Extract a display name from the user ID
    // In a real app, this would fetch the actual user name
    if (player.userId.startsWith('user_')) {
      return 'Player ${player.userId.split('_').last}';
    } else if (player.userId.startsWith('national_player_')) {
      final playerNumber = player.userId.split('_').last;
      final names = ['Tom Njoroge', 'Sam Wachira', 'Mary Kamau', 'John Mwangi', 'Grace Wanjiku'];
      final index = int.tryParse(playerNumber) ?? 1;
      return names[(index - 1) % names.length];
    }
    return 'Player ${player.userId.hashCode.abs() % 1000}';
  }
}

class TopShooter {
  final String name;
  final String? score;
  final String? imageUrl;
  final String id;

  const TopShooter({
    required this.name,
    this.score,
    this.imageUrl,
    required this.id,
  });
}