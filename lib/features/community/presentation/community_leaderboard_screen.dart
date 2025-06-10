import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/features/community/domain/entities/community.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';

/// Community Leaderboard Screen
///
/// Shows a ranking of communities based on their member count and activity
class CommunityLeaderboardScreen extends StatelessWidget {
  static const String routeName = '/community-leaderboard';

  const CommunityLeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CommunityBloc>()..add(const LoadTopRankedCommunitiesEvent()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Community Rankings'),
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
                  state.errorMessage ?? 'Failed to load community rankings',
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
            child: Text('No communities found.'),
          );
        }

        final topCommunities = state.topCommunities!;

        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor,
              child: const Column(
                children: [
                  Text(
                    'Community Rankings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ranked by member count and community activity',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Top 3 communities highlight
            if (topCommunities.length >= 3)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 2nd place
                    Expanded(
                      child: _buildTopCommunityCard(
                        community: topCommunities[1],
                        rank: 2,
                        color: Colors.grey[400]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 1st place
                    Expanded(
                      child: _buildTopCommunityCard(
                        community: topCommunities[0],
                        rank: 1,
                        color: Colors.amber,
                        isWinner: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 3rd place
                    Expanded(
                      child: _buildTopCommunityCard(
                        community: topCommunities[2],
                        rank: 3,
                        color: Colors.brown[400]!,
                      ),
                    ),
                  ],
                ),
              ),

            // Full rankings list
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: topCommunities.length,
                itemBuilder: (context, index) {
                  final community = topCommunities[index];
                  final rank = index + 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (community.location != null)
                            Text(community.location!),
                          Text(
                            'Skill Level: ${community.skillLevel}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${community.memberCount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Text(
                            'members',
                            style: TextStyle(
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
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopCommunityCard({
    required Community community,
    required int rank,
    required Color color,
    bool isWinner = false,
  }) {
    return Card(
      elevation: isWinner ? 8 : 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isWinner
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 179),
                    color
                  ], // 0.7 * 255 ≈ 179
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color:
              isWinner ? null : color.withValues(alpha: 51), // 0.2 * 255 ≈ 51
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              community.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isWinner ? 14 : 12,
                color: isWinner ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${community.memberCount} members',
              style: TextStyle(
                fontSize: 11,
                color: isWinner ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
