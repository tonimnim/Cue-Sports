import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pool_billiard_app/main_screen/home/components/community_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/tournament_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/top_shooters_list.dart';
import 'package:pool_billiard_app/main_screen/home/components/upgrade_promotion_card.dart';
import 'package:pool_billiard_app/main_screen/home/components/quick_action_component.dart';

class FanHomeView extends StatefulWidget {
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
  State<FanHomeView> createState() => _FanHomeViewState();
}

class _FanHomeViewState extends State<FanHomeView> {
  final PageController _heroPageController = PageController();
  Timer? _heroAutoScrollTimer;
  int _currentHeroPage = 0;

  @override
  void initState() {
    super.initState();
    _startHeroAutoScroll();
  }

  @override
  void dispose() {
    _heroAutoScrollTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _startHeroAutoScroll() {
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_heroPageController.hasClients) {
        // Auto-scroll ALL cards (including "BECOME A PLAYER")
        final allCards = _getHeroCards();
        final nextPage = (_currentHeroPage + 1) % allCards.length;
        _heroPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentHeroPage = nextPage;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getHeroCards() {
    return [
      {
        'type': 'upgrade',
        'title': 'BECOME A\nPLAYER',
        'subtitle': 'UPGRADE TO PLAYER',
        'description': 'JOIN TOURNAMENTS · TRACK STATS',
        'buttonText': 'UPGRADE NOW - KSh 500',
        'color': const Color(0xFFF9D61D),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'PREMIUM\nPOOL CUE',
        'subtitle': 'SHOP EQUIPMENT',
        'description': 'PROFESSIONAL GRADE · 25% OFF',
        'buttonText': 'GET NOW - KSh 4,500',
        'color': const Color(0xFF0066FF),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'CLUB\nJERSEY',
        'subtitle': 'OFFICIAL MERCHANDISE',
        'description': 'REPRESENT YOUR COMMUNITY',
        'buttonText': 'ORDER NOW - KSh 1,200',
        'color': const Color(0xFF00CC66),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'TOURNAMENT\nRANKING',
        'subtitle': 'TRACK PROGRESS',
        'description': 'VIEW LEADERBOARDS · STATS',
        'buttonText': 'VIEW RANKINGS',
        'color': const Color(0xFFFF6600),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'POOL BALL\nSET',
        'subtitle': 'COMPLETE SET',
        'description': 'PROFESSIONAL TOURNAMENT BALLS',
        'buttonText': 'BUY NOW - KSh 3,200',
        'color': const Color(0xFF9933FF),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
    ];
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
          // ALL cards auto-scroll together (including "BECOME A PLAYER")
          _buildAllCardsCarousel(),
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
              // For fans, show upgrade prompt
              _showUpgradeDialog(context);
            },
            onCommunityTap: widget.onCommunitiesSeeAllTap,
            onTournamentsTap: widget.onTournamentsSeeAllTap,
            onLeaderboardTap: () {
              // TODO: Navigate to leaderboard screen
            },
          ),
          const SizedBox(height: 24),
          // Top communities section
          _buildSectionHeader('Top communities',
              onSeeAllTap: widget.onCommunitiesSeeAllTap),
          const SizedBox(height: 16),
          _buildCommunitiesCarousel(context),
          const SizedBox(height: 24),
          // Top shooters section
          TopShootersList(
            shooters: const [], // Empty list for placeholder display
            onSeeAllTap: widget.onShootersSeeAllTap,
          ),
          const SizedBox(
              height: 100), // Extra bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildAllCardsCarousel() {
    final allCards = _getHeroCards(); // ALL cards including "BECOME A PLAYER"

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _heroPageController,
            onPageChanged: (page) {
              setState(() {
                _currentHeroPage = page;
              });
            },
            itemCount: allCards.length,
            itemBuilder: (context, index) {
              final card = allCards[index];
              return _buildHeroCard(card);
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(allCards.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentHeroPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF093218),
            const Color(0xFF0B3D1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card['subtitle'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      card['title'],
                      style: TextStyle(
                        color: card['color'],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card['description'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      if (card['type'] == 'upgrade') {
                        if (widget.onUpgradeTap != null) {
                          widget.onUpgradeTap!();
                        } else {
                          _handleUpgrade(context);
                        }
                      } else {
                        if (widget.onShopTap != null) {
                          widget.onShopTap!();
                        } else {
                          _handleShopNavigation(context);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: card['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        card['buttonText'],
                        style: TextStyle(
                          color: card['color'],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Image
          Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              card['image'],
              fit: BoxFit.contain,
            ),
          ),
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
                            'assets/images/BILLIARD POOL.svg'), // Using logo as default
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.communityName != null) ...[
                  Text(
                    widget.communityName!,
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
          onPressed: widget.onNotificationTap,
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
