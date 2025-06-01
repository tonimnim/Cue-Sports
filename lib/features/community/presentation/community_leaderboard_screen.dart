import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/features/community/domain/entities/community.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';
import 'package:pool_billiard_app/core/widgets/loading_indicator.dart';
import 'package:pool_billiard_app/features/community/presentation/widgets/community_card.dart';

/// Community Leaderboard Screen
/// 
/// Shows a ranking of communities based on their points and achievements
class CommunityLeaderboardScreen extends StatelessWidget {
  static const String routeName = '/community-leaderboard';
  
  const CommunityLeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CommunityBloc>()
        ..add(const LoadTopRankedCommunitiesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Leaderboard'),
        ),
        body: const _CommunityLeaderboardView(),
      ),
    );
  }
}

class _CommunityLeaderboardView extends StatelessWidget {
  const _CommunityLeaderboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == CommunityStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorMessage ?? 'Failed to load leaderboard',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<CommunityBloc>().add(
                    const LoadTopRankedCommunitiesEvent(),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        } else if (state.topCommunities?.isEmpty ?? true) {
          return const Center(
            child: Text('No communities found in the leaderboard.'),
          );
        }

        final topCommunities = state.topCommunities!;
        
        return Column(
          children: [
            // Leaderboard header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor,
              child: const Column(
                children: [
                  Text(
                    'Top Communities',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Based on community points, achievements, and activity',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Podium (top 3 communities)
            if (topCommunities.isNotEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd place
                    if (topCommunities.length > 1)
                      _buildPodiumItem(
                        community: topCommunities[1],
                        rank: 2,
                        height: 100,
                        fontSize: 18,
                      ),
                    
                    // 1st place
                    _buildPodiumItem(
                      community: topCommunities[0],
                      rank: 1,
                      height: 130,
                      fontSize: 20,
                      isWinner: true,
                    ),
                    
                    // 3rd place
                    if (topCommunities.length > 2)
                      _buildPodiumItem(
                        community: topCommunities[2],
                        rank: 3,
                        height: 80,
                        fontSize: 16,
                      ),
                  ],
                ),
              ),
            
            // Full leaderboard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: topCommunities.length,
                itemBuilder: (context, index) {
                  final community = topCommunities[index];
                  final rank = index + 1;
                  
                  // Determine background color based on rank
                  Color? backgroundColor;
                  if (rank == 1) {
                    backgroundColor = Colors.amber[100];
                  } else if (rank == 2) {
                    backgroundColor = Colors.grey[200];
                  } else if (rank == 3) {
                    backgroundColor = Colors.brown[100];
                  }
                  
                  return ListTile(
                    tileColor: backgroundColor,
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(rank),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      community.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      community.location ?? 'No location',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${community.communityPoints.toStringAsFixed(0)} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${community.trophyCount} trophies',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to community details
                      Navigator.of(context).pushNamed(
                        '/community-details',
                        arguments: community.id,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPodiumItem({
    required Community community,
    required int rank,
    required double height,
    required double fontSize,
    bool isWinner = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRankColor(rank),
            border: isWinner ? Border.all(color: Colors.amber, width: 2) : null,
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 128), // 0.5 * 255 = 128
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Community name
        SizedBox(
          width: 100,
          child: Text(
            community.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        // Points
        Text(
          '${community.communityPoints.toStringAsFixed(0)} pts',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: _getRankColor(rank).withValues(alpha: 179), // 0.7 * 255 ≈ 179
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: isWinner
              ? const Center(
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : null,
        ),
      ],
    );
  }
  
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[500]!;
      default:
        return Colors.blue[700]!;
    }
  }
}
