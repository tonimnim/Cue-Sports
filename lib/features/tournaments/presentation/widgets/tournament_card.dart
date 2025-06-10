import 'package:flutter/material.dart';
import '../../../../core/config/theme.dart';
import '../../domain/entities/tournament.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final bool isFeatured;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;

  const TournamentCard({
    Key? key,
    required this.tournament,
    this.isFeatured = false,
    this.onTap,
    this.onRegister,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedCard(context);
    } else {
      return _buildRegularCard(context);
    }
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.3),
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
              // Featured badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.emoji_events, size: 16, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tournament name
              Text(
                tournament.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tournament details
              _buildDetailRow(
                Icons.calendar_today,
                tournament.dateRange,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.location_on,
                tournament.venue,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.people,
                '${tournament.currentPlayers} Players',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.emoji_events,
                tournament.typeDisplayName,
              ),
              const SizedBox(height: 16),

              // Prize pool
              Text(
                'Prize Pool: ${_formatAmount(tournament.prizePool)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      tournament.isOpenForRegistration ? onRegister : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tournament.isOpenForRegistration
                        ? 'Register Now - ${_formatAmount(tournament.entryFee)}'
                        : 'Registration Closed',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegularCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tournament name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tournament.typeDisplayName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // Tournament details in a row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      Icons.calendar_today,
                      tournament.dateRange,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailRow(
                      Icons.location_on,
                      tournament.venue,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      Icons.people,
                      '${tournament.currentPlayers}/${tournament.maxPlayers == 0 ? '∞' : tournament.maxPlayers} players',
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailRow(
                      Icons.emoji_events,
                      _formatAmount(tournament.prizePool),
                      isCompact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Entry fee and register button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
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
                          _formatAmount(tournament.entryFee),
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tournament.spotsRemaining > 0 &&
                      tournament.spotsRemaining <= 5)
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Only ${tournament.spotsRemaining} spots left!',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed:
                          tournament.isOpenForRegistration ? onRegister : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FittedBox(
                        child: Text(
                          tournament.isOpenForRegistration
                              ? 'Register'
                              : 'Full',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildDetailRow(IconData icon, String text, {bool isCompact = false}) {
    return Row(
      mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(
          icon,
          size: isCompact ? 14 : 16,
          color: AppTheme.accentColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isCompact ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;

    switch (tournament.status) {
      case TournamentStatus.upcoming:
        badgeColor = Colors.blue;
        statusText = 'UPCOMING';
        break;
      case TournamentStatus.registration_open:
        badgeColor = Colors.green;
        statusText = 'OPEN';
        break;
      case TournamentStatus.registration_closed:
        badgeColor = Colors.orange;
        statusText = 'CLOSED';
        break;
      case TournamentStatus.in_progress:
        badgeColor = Colors.purple;
        statusText = 'LIVE';
        break;
      case TournamentStatus.completed:
        badgeColor = Colors.grey;
        statusText = 'COMPLETED';
        break;
      case TournamentStatus.cancelled:
        badgeColor = Colors.red;
        statusText = 'CANCELLED';
        break;
      case TournamentStatus.draft:
        badgeColor = Colors.orange;
        statusText = 'DRAFT';
        break;
      case TournamentStatus.active:
        badgeColor = Colors.blue;
        statusText = 'ACTIVE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return 'KSh ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'KSh ${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return 'KSh ${amount.toStringAsFixed(0)}';
    }
  }
}
