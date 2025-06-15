import 'package:flutter/material.dart';
import '../../../../core/config/theme.dart';
import '../../domain/entities/match.dart';

class LiveMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  final VoidCallback? onViewLive;

  const LiveMatchCard({
    Key? key,
    required this.match,
    this.onTap,
    this.onViewLive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live badge and tournament info
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (match.isLiveStreamed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Tournament name
              Text(
                'Premier League Championship', // You might want to add tournament name to match
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Professional',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Match details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      Icons.sports,
                      'Round 2 of 4',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      Icons.people,
                      '47 players active',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      Icons.emoji_events,
                      'KSh 100,000 prize',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailRow(
                      Icons.access_time,
                      _getTimeRemaining(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Entry fee and view live button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entry Fee',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'KSh ${match.bestOf * 100}', // Placeholder calculation
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (match.hasPlayer(_getCurrentUserId()))
                    const Text(
                      'You\'re participating',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onViewLive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Live',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.accentColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _getTimeRemaining() {
    if (match.actualStartTime != null) {
      final elapsed = DateTime.now().difference(match.actualStartTime!);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}min remaining';
      } else {
        return '${minutes}min remaining';
      }
    }
    return '2hr 15min remaining'; // Placeholder
  }

  String _getCurrentUserId() {
    // This should get the current user ID from Firebase Auth
    // For now, returning empty string
    return '';
  }
}
