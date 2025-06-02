import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';
import 'package:pool_billiard_app/main_screen/home/components/quick_action_component.dart';

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
          // Top communities section
          _buildSectionHeader('Top communities',
              onSeeAllTap: onCommunitiesSeeAllTap),
          const SizedBox(height: 16),
          _buildCommunitiesCarousel(context),
          const SizedBox(height: 24),
          // Top shooters section
          TopShootersList(
            shooters: const [], // Empty list for placeholder display
            onSeeAllTap: onShootersSeeAllTap,
          ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (communityName != null) ...[
                  Text(
                    communityName!,
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 204), // 0.8 * 255 ≈ 204
                      fontSize: 14,
                    ),
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
          color: const Color(0xFF1B5E20), // Dark green background
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
                      style: const TextStyle(
                        color: Color(0xFFFFD700), // Gold color
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'National Rank',
                      style: TextStyle(
                        color: Color(0xFF81C784), // Light green
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Reduced from 32 to 24
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'Community Board',
                      style: TextStyle(
                        color: Color(0xFF81C784), // Light green
                        fontSize: 11, // Reduced from 13 to 11
                        fontWeight: FontWeight.w500,
                      ),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildCommunitiesCarousel(BuildContext context) {
    // Sample community data
    final List<Map<String, dynamic>> communities = [
      {
        'name': 'Nairobi East',
        'playerCount': 156,
      },
      {
        'name': 'Nairobi East',
        'playerCount': 156,
      },
      {
        'name': 'Nairobi East',
        'playerCount': 156,
      },
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < communities.length - 1 ? 16.0 : 0),
            child: CommunityCard(
              name: community['name'],
              playerCount: community['playerCount'],
              onTap: () {
                // Navigate to community details
                Navigator.pushNamed(
                  context,
                  '/community-details',
                  arguments: {'communityId': index.toString()},
                );
              },
            ),
          );
        },
      ),
    );
  }
}
