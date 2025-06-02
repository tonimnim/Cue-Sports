import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class QuickActionComponent extends StatelessWidget {
  final VoidCallback? onFindMatchTap;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onTournamentsTap;
  final VoidCallback? onLeaderboardTap;

  const QuickActionComponent({
    Key? key,
    this.onFindMatchTap,
    this.onCommunityTap,
    this.onTournamentsTap,
    this.onLeaderboardTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Action',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                title: 'Find Match',
                onTap: onFindMatchTap ?? () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.people,
                title: 'Community',
                onTap: onCommunityTap ?? () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.emoji_events,
                title: 'Tournaments',
                onTap: onTournamentsTap ?? () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.leaderboard,
                title: 'Leaderboard',
                onTap: onLeaderboardTap ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF16543A), // Using the requested color #16543A
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
