import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/live_match_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';
import 'package:pool_billiard_app/main_screen/home/components/quick_action_component.dart';
import 'package:pool_billiard_app/main_screen/home/services/home_service.dart';
import 'package:pool_billiard_app/features/tournaments/data/models/tournament_model.dart';
import 'package:pool_billiard_app/features/tournaments/data/models/match_model.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/community.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class PlayerHomeView extends StatefulWidget {
  final String userName;
  final String? communityName;
  final String? userImageUrl;
  final int communityRank;
  final int nationalRank;
  final VoidCallback onNotificationTap;
  final VoidCallback onTournamentsSeeAllTap;
  final VoidCallback onCommunitiesSeeAllTap;
  final VoidCallback onShootersSeeAllTap;

  const PlayerHomeView({
    Key? key,
    required this.userName,
    this.communityName,
    this.userImageUrl,
    required this.communityRank,
    required this.nationalRank,
    required this.onNotificationTap,
    required this.onTournamentsSeeAllTap,
    required this.onCommunitiesSeeAllTap,
    required this.onShootersSeeAllTap,
  }) : super(key: key);

  @override
  State<PlayerHomeView> createState() => _PlayerHomeViewState();
}

class _PlayerHomeViewState extends State<PlayerHomeView> {
  // Home data management
  HomePageData? _homeData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Inject HomeService through dependency injection
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // User profile header
          _buildUserProfileHeader(),
          const SizedBox(height: 24),
          // Player rank card
          _buildPlayerRankCard(),
          const SizedBox(height: 24),
          // Live tournaments section
          _buildSectionHeader('Live tournaments',
              onSeeAllTap: widget.onTournamentsSeeAllTap),
          const SizedBox(height: 16),
          _buildTournamentsCarousel(context),
          const SizedBox(height: 24),
          // Quick Action component
          QuickActionComponent(
            onFindMatchTap: () {
              // TODO: Navigate to find match screen
            },
            onCommunityTap: widget.onCommunitiesSeeAllTap,
            onTournamentsTap: widget.onTournamentsSeeAllTap,
            onLeaderboardTap: () {
              // TODO: Navigate to leaderboard screen
            },
          ),
          const SizedBox(height: 24),
          // Recent Matches section (replacing Top Communities)
          _buildSectionHeader('Recent Matches', onSeeAllTap: () {
            // TODO: Navigate to matches history
          }),
          const SizedBox(height: 16),
          _buildRecentMatchesCarousel(context),
          const SizedBox(height: 24),
          // Top shooters section (now horizontal)
          _buildSectionHeader('Top Shooters This Week',
              onSeeAllTap: widget.onShootersSeeAllTap),
          const SizedBox(height: 16),
          _buildTopShootersHorizontal(context),
          const SizedBox(
              height: 100), // Extra bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // User avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: widget.userImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.userImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage(
                            'assets/images/logo.png'), // Using logo as default
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // User info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: AppTheme.h3Style, // 18px Medium Raleway
                ),
                if (widget.communityName != null) ...[
                  Text(
                    widget.communityName!,
                    style: AppTheme.bodySmallStyle.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ), // 14px Regular Raleway
                  ),
                ],
              ],
            ),
          ],
        ),
        // Notification icon
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.yellow,
            size: 28,
          ),
          onPressed: widget.onNotificationTap,
        ),
      ],
    );
  }

  Widget _buildPlayerRankCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Colorful gradient border at the top
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50), // Green
            Color(0xFF8BC34A), // Light green
            Color(0xFFCDDC39), // Lime
            Color(0xFFFFEB3B), // Yellow
            Color(0xFFFF9800), // Orange
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 4), // Space for the gradient border
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          color: AppTheme.cardColor, // Using proper card color
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // National Rank Section (Left) - Move 5px to the right
              Transform.translate(
                offset: const Offset(5, 0), // Move 5px to the right
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${widget.nationalRank > 0 ? widget.nationalRank : 3}', // Show actual rank or default to 3
                      style: TextStyle(
                        color: AppTheme.accentColor, // Gold color
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'National Rank',
                      style: AppTheme.captionStyle.copyWith(
                        color: const Color(0xFF81C784), // Light green
                        fontWeight: FontWeight.w500,
                      ), // 12px Medium Raleway
                    ),
                  ],
                ),
              ),

              const Spacer(), // This creates flexible space

              // Reduce space by 5px using negative margin
              Transform.translate(
                offset: const Offset(-5, 0), // Move 5px to the left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Added to minimize height
                  children: [
                    // People icon - more compact design
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: 2), // Reduced from 4 to 2
                      width: 36, // Reduced from 45 to 36
                      height: 18, // Reduced from 24 to 18
                      child: Stack(
                        children: [
                          // Left person (smaller circle)
                          Positioned(
                            left: 0,
                            top: 2,
                            child: Container(
                              width: 14, // Reduced from 16 to 14
                              height: 14, // Reduced from 16 to 14
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Center person (larger, main person)
                          Positioned(
                            left: 11, // Adjusted from 14 to 11
                            top: 0,
                            child: Container(
                              width: 18, // Reduced from 24 to 18
                              height: 18, // Reduced from 24 to 18
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Right person (smaller circle)
                          Positioned(
                            right: 0,
                            top: 2,
                            child: Container(
                              width: 14, // Reduced from 16 to 14
                              height: 14, // Reduced from 16 to 14
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.communityRank > 0 ? widget.communityRank : 8}/10',
                      style: AppTheme.h3Style.copyWith(
                        fontSize: 24, // Reduced from 32 to 24
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ), // 18px Bold Raleway
                    ),
                    Text(
                      'Community Board',
                      style: AppTheme.overlineStyle.copyWith(
                        color: const Color(0xFF81C784), // Light green
                        fontWeight: FontWeight.w500,
                      ), // 10px Medium Raleway
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {required VoidCallback onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.h3Style, // 18px Medium Raleway
        ),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Text(
            'see all',
            style: AppTheme.bodySmallStyle.copyWith(
              color: Colors.white70,
            ), // 14px Regular Raleway
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentsCarousel(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load tournaments',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadHomeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final tournaments = _homeData?.activeTournaments ?? [];
    
    if (tournaments.isEmpty) {
      return Container(
        height: 180,
        child: const Center(
          child: Text(
            'No active tournaments at the moment',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < tournaments.length - 1 ? 16.0 : 0),
            child: TournamentCard(
              title: tournament.name,
              round: 'Active Tournament',
              players: tournament.registeredUserIds.length,
              prize: 'KSh ${tournament.prizePool.toStringAsFixed(0)}',
              venue: tournament.venue ?? tournament.location,
              onTap: () {
                // Navigate to tournament details
                Navigator.pushNamed(
                  context,
                  '/tournament-details',
                  arguments: {'tournamentId': tournament.id},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentMatchesCarousel(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final recentMatches = _homeData?.recentMatches ?? [];
    
    if (recentMatches.isEmpty) {
      return Container(
        height: 100,
        child: const Center(
          child: Text(
            'No recent matches',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentMatches.length,
        itemBuilder: (context, index) {
          final match = recentMatches[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < recentMatches.length - 1 ? 16.0 : 0),
            child: _buildRecentMatchCard(match),
          );
        },
      ),
    );
  }

  Widget _buildRecentMatchCard(MatchModel match) {
    // TODO: Get current user ID from context/state management
    final currentUserId = 'current_user_id'; // Placeholder - should use actual user ID
    final isPlayer1 = match.player1Id == currentUserId;
    final opponent = isPlayer1 ? match.player2Name : match.player1Name;
    
    // Determine if current user won
    final currentUserScore = isPlayer1 ? match.player1Score : match.player2Score;
    final opponentScore = isPlayer1 ? match.player2Score : match.player1Score;
    final isWin = currentUserScore != null && opponentScore != null && currentUserScore > opponentScore;
    
    // Calculate time ago
    final timeAgo = _getTimeAgo(match.actualEndTime ?? match.createdAt);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, // Using proper card color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match result and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isWin ? Icons.check_circle : Icons.cancel,
                    color: isWin ? AppTheme.successColor : AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isWin ? 'Win' : 'Loss',
                    style: AppTheme.captionStyle.copyWith(
                      color:
                          isWin ? AppTheme.successColor : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ), // 12px SemiBold Raleway
                  ),
                ],
              ),
              Text(
                timeAgo,
                style: AppTheme.overlineStyle.copyWith(
                  color: Colors.white70,
                ), // 10px Regular Raleway
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Opponent and score
          Text(
            'Vs $opponent',
            style: AppTheme.bodySmallStyle.copyWith(
              fontWeight: FontWeight.w600,
            ), // 14px SemiBold Raleway
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Score and points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentUserScore ?? 0}-${opponentScore ?? 0}',
                style: AppTheme.bodyLargeStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ), // 16px SemiBold Raleway
              ),
              Text(
                isWin ? '+150' : '-50', // Placeholder points calculation
                style: AppTheme.captionStyle.copyWith(
                  color: isWin ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ), // 12px SemiBold Raleway
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopShootersHorizontal(BuildContext context) {
    // Sample top shooters data
    final List<Map<String, dynamic>> topShooters = [
      {
        'name': 'Alex Maina',
        'rank': '#1 Regional',
        'image': 'assets/images/logo.png',
      },
      {
        'name': 'Alex Maina',
        'rank': '#1 Regional',
        'image': 'assets/images/logo.png',
      },
      {
        'name': 'Alex Maina',
        'rank': '#1 Regional',
        'image': 'assets/images/logo.png',
      },
      {
        'name': 'Alex Maina',
        'rank': '#1 Regional',
        'image': 'assets/images/logo.png',
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topShooters.length,
        itemBuilder: (context, index) {
          final shooter = topShooters[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < topShooters.length - 1 ? 16.0 : 0),
            child: _buildShooterCard(shooter),
          );
        },
      ),
    );
  }

  Widget _buildShooterCard(Map<String, dynamic> shooter) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, // Using proper card color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shooter avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor, width: 2),
              image: DecorationImage(
                image: AssetImage(shooter['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Shooter name
          Text(
            shooter['name'],
            style: AppTheme.captionStyle.copyWith(
              fontWeight: FontWeight.w600,
            ), // 12px SemiBold Raleway
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Shooter rank
          Text(
            shooter['rank'],
            style: AppTheme.overlineStyle.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ), // 10px Medium Raleway
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
