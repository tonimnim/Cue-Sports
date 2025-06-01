import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';

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
    return SingleChildScrollView(
      child: Padding(
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
            _buildSectionHeader('Live tournaments', onSeeAllTap: onTournamentsSeeAllTap),
            const SizedBox(height: 16),
            _buildTournamentsCarousel(context),
            const SizedBox(height: 24),
            // Top communities section
            _buildSectionHeader('Top communities', onSeeAllTap: onCommunitiesSeeAllTap),
            const SizedBox(height: 16),
            _buildCommunitiesCarousel(context),
            const SizedBox(height: 24),
            // Top shooters section
            TopShootersList(
              shooters: const [], // Empty list for placeholder display
              onSeeAllTap: onShootersSeeAllTap,
            ),
            const SizedBox(height: 24),
          ],
        ),
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
                        image: AssetImage('assets/images/logo.png'), // Using logo as default
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
                      color: Colors.white.withValues(alpha: 204), // 0.8 * 255 ≈ 204
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
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF9DE884), Color(0xFFFFF176)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Community Rank
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Community',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Rank',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$communityRank',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 50,
            width: 1,
            color: Colors.black38,
          ),
          // National Rank
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'National',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Rank',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$nationalRank',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAllTap}) {
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
            padding: EdgeInsets.only(right: index < tournaments.length - 1 ? 16.0 : 0),
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
            padding: EdgeInsets.only(right: index < communities.length - 1 ? 16.0 : 0),
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