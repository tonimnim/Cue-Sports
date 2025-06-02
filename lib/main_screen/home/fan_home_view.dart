import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';
import 'package:pool_billiard_app/main_screen/home/components/upgrade_promotion_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/shop_merchandise_carousel.dart';
import 'package:pool_billiard_app/main_screen/home/components/quick_action_component.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pool_billiard_app/features/tournaments/presentation/live_tournaments_screen.dart';

class FanHomeView extends StatelessWidget {
  final String userName;
  final String? communityName;
  final String? userImageUrl;
  final VoidCallback onNotificationTap;
  final VoidCallback onTournamentsSeeAllTap;
  final VoidCallback onCommunitiesSeeAllTap;
  final VoidCallback onShootersSeeAllTap;
  final VoidCallback? onUpgradeTap;
  final VoidCallback? onShopTap;

  const FanHomeView({
    Key? key,
    required this.userName,
    this.communityName,
    this.userImageUrl,
    required this.onNotificationTap,
    required this.onTournamentsSeeAllTap,
    required this.onCommunitiesSeeAllTap,
    required this.onShootersSeeAllTap,
    this.onUpgradeTap,
    this.onShopTap,
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
          // Upgrade promotion card (replaces play pool banner)
          UpgradePromotionCard(
            onUpgradeTap: onUpgradeTap ?? () => _handleUpgrade(context),
          ),
          const SizedBox(height: 24),
          // Live tournaments section
          _buildSectionHeader('Live tournaments', onSeeAllTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LiveTournamentsScreen(),
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildTournamentsCarousel(context),
          const SizedBox(height: 24),
          // Quick Action component
          QuickActionComponent(
            onFindMatchTap: () {
              // For fans, show upgrade prompt
              _showUpgradeDialog(context);
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
          // Shop merchandise section
          ShopMerchandiseCarousel(
            onShopTap: onShopTap ?? () => _handleShopNavigation(context),
          ),
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
        'players': 32,
        'prize': 'KSh 50,000',
        'venue': 'City Hall',
        'isLive': true,
        'youtubeUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      },
      {
        'title': 'Kenya Championship',
        'players': 24,
        'prize': 'KSh 30,000',
        'venue': 'Sports Complex',
        'isLive': true,
        'youtubeUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      },
      {
        'title': 'Mombasa Open',
        'players': 16,
        'prize': 'KSh 25,000',
        'venue': 'Ocean View Club',
        'isLive': false,
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
              players: tournament['players'],
              prize: tournament['prize'],
              venue: tournament['venue'],
              isLive: tournament['isLive'],
              youtubeUrl: tournament['youtubeUrl'],
              onTap: () {
                if (tournament['isLive'] && tournament['youtubeUrl'] != null) {
                  // Launch YouTube URL for live matches
                  _launchYoutube(tournament['youtubeUrl']);
                } else {
                  // Navigate to tournament details for regular tournaments
                  Navigator.pushNamed(
                    context,
                    '/tournament-details',
                    arguments: {'tournamentId': index.toString()},
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchYoutube(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error launching YouTube: $e');
    }
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

  void _handleUpgrade(BuildContext context) {
    // Navigate to upgrade/payment screen
    Navigator.pushNamed(context, '/payment');
  }

  void _handleShopNavigation(BuildContext context) {
    // Navigate to shop
    Navigator.pushNamed(context, '/shop');
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B4332),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Upgrade Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature is only available for Club Players. Upgrade your account to access match finding and other exclusive features.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleUpgrade(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
