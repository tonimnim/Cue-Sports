import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';
import 'package:pool_billiard_app/main_screen/home/components/quick_action_component.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class PlayerHomeView extends StatelessWidget {
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
              onSeeAllTap: onTournamentsSeeAllTap),
          const SizedBox(height: 16),
          _buildTournamentsCarousel(context),
          const SizedBox(height: 24),
          // Quick Action component
          QuickActionComponent(
            onFindMatchTap: () {
              // TODO: Navigate to find match screen
            },
            onCommunityTap: onCommunitiesSeeAllTap,
            onTournamentsTap: onTournamentsSeeAllTap,
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
              onSeeAllTap: onShootersSeeAllTap),
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
                image: userImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(userImageUrl!),
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
                  userName,
                  style: AppTheme.h3Style, // 18px Medium Raleway
                ),
                if (communityName != null) ...[
                  Text(
                    communityName!,
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
          onPressed: onNotificationTap,
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
                      '#${nationalRank > 0 ? nationalRank : 3}', // Show actual rank or default to 3
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
                      '${communityRank > 0 ? communityRank : 8}/10',
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
    // Sample tournament data
    final List<Map<String, dynamic>> tournaments = [
      {
        'title': 'Nairobi Premier League',
        'round': '3 of 5',
        'players': 32,
        'prize': 'KSh 50,000',
        'venue': 'City Hall',
        'isLive': true,
      },
      {
        'title': 'Nairobi Premier League',
        'round': '4 of 5',
        'players': 32,
        'prize': 'KSh 50,000',
        'venue': 'City Hall',
        'isLive': true,
      },
      {
        'title': 'Nairobi Premier League',
        'round': '5 of 5',
        'players': 32,
        'prize': 'KSh 50,000',
        'venue': 'City Hall',
        'isLive': true,
      },
    ];

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
              title: tournament['title'],
              round: tournament['round'],
              players: tournament['players'],
              prize: tournament['prize'],
              venue: tournament['venue'],
              isLive: tournament['isLive'],
              onTap: () {
                // Navigate to tournament details
                Navigator.pushNamed(
                  context,
                  '/tournament-details',
                  arguments: {'tournamentId': index.toString()},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentMatchesCarousel(BuildContext context) {
    // Sample recent matches data
    final List<Map<String, dynamic>> recentMatches = [
      {
        'opponent': 'James Mwangi',
        'timeAgo': '2 hours ago',
        'result': 'Win',
        'score': '8-6',
        'points': '+250',
        'isWin': true,
      },
      {
        'opponent': 'Mark Kariuki',
        'timeAgo': '2 hours ago',
        'result': 'Win',
        'score': '8-4',
        'points': '+180',
        'isWin': true,
      },
      {
        'opponent': 'Anthony Chege',
        'timeAgo': '2 hours ago',
        'result': 'Loss',
        'score': '5-8',
        'points': '-120',
        'isWin': false,
      },
    ];

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

  Widget _buildRecentMatchCard(Map<String, dynamic> match) {
    final isWin = match['isWin'] as bool;

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
                    match['result'],
                    style: AppTheme.captionStyle.copyWith(
                      color:
                          isWin ? AppTheme.successColor : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ), // 12px SemiBold Raleway
                  ),
                ],
              ),
              Text(
                match['timeAgo'],
                style: AppTheme.overlineStyle.copyWith(
                  color: Colors.white70,
                ), // 10px Regular Raleway
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Opponent and score
          Text(
            'Vs ${match['opponent']}',
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
                match['score'],
                style: AppTheme.bodyLargeStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ), // 16px SemiBold Raleway
              ),
              Text(
                match['points'],
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
}
