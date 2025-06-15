import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/config/theme.dart';
import '../../domain/entities/tournament.dart';
import '../../../auth/domain/entities/user.dart' as app_user;

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final bool isFeatured;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final app_user.User? currentUser;

  const TournamentCard({
    Key? key,
    required this.tournament,
    this.isFeatured = false,
    this.onTap,
    this.onRegister,
    this.currentUser,
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
                tournament.primaryVenue,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.people,
                '${tournament.currentPlayerCount} Players',
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

              // Register button or status (only for players)
              if (_canUserRegister())
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
              // Already registered status
              if (_isUserAlreadyRegistered())
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '✓ Already Registered',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // Info message for fans
              if (!_canUserRegister() && currentUser?.isFan == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Upgrade to Player to register for tournaments',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
                      tournament.primaryVenue,
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
                      '${tournament.currentPlayerCount}/${tournament.maxPlayers == 0 ? '∞' : tournament.maxPlayers} players',
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
                  if (_canUserRegister())
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
                  if (_isUserAlreadyRegistered())
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          '✓ Registered',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (!_canUserRegister() && !_isUserAlreadyRegistered())
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          currentUser?.isFan == true ? 'Fans Only' : 'View Only',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
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
        badgeColor = Colors.purple;
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

  /// Check if the current user can register for tournaments
  bool _canUserRegister() {
    // If no user provided, check if firebase user exists and assume they can register
    if (currentUser == null) {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // Check if firebase user is already registered
      return !tournament.isUserRegistered(firebaseUser.uid);
    }
    
    // Only players can register for tournaments, and only if not already registered
    final user = currentUser;
    if (user == null) return false;
    return user.isPlayer && !tournament.isUserRegistered(user.id);
  }

  /// Check if current user is already registered
  bool _isUserAlreadyRegistered() {
    final user = currentUser;
    if (user != null) {
      return tournament.isUserRegistered(user.id);
    }
    
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return tournament.isUserRegistered(firebaseUser.uid);
    }
    
    return false;
  }
}
