import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class RecentMatchesComponent extends StatelessWidget {
  final List<RecentMatch> matches;
  final VoidCallback? onSeeAllTap;

  const RecentMatchesComponent({
    Key? key,
    required this.matches,
    this.onSeeAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Matches',
              style: AppTheme.subheadingStyle,
            ),
            if (onSeeAllTap != null)
              GestureDetector(
                onTap: onSeeAllTap,
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
        if (matches.isEmpty)
          _buildEmptyState()
        else
          Column(
            children:
                matches.take(3).map((match) => _buildMatchCard(match)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Recent Matches',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your recent match results will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(RecentMatch match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Win/Loss indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: match.isWin
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF8E8E93),
              shape: BoxShape.circle,
            ),
            child: Icon(
              match.isWin ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Match details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vs ${match.opponentName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  match.timeAgo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Score and result
          Text(
            '${match.playerScore}-${match.opponentScore} ${match.isWin ? 'Win' : 'Loss'}',
            style: TextStyle(
              color: match.isWin
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFFF5722),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentMatch {
  final String id;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final String timeAgo;
  final bool isWin;

  RecentMatch({
    required this.id,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.timeAgo,
    required this.isWin,
  });
}
