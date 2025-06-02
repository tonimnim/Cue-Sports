import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/main_screen/home/fan_home_view.dart';
import 'package:pool_billiard_app/main_screen/home/player_home_view.dart';
import 'package:pool_billiard_app/widget/display/buttom_navigation'
    as navigation;
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user_ranking.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/core/services/ranking_service.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;
import 'package:pool_billiard_app/core/config/theme.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserRanking? _userRanking;
  bool _isLoadingRanking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F4A22), // Dark green background
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: LoadingIndicator());
            } else if (state is AuthAuthenticated) {
              return _buildMainContent(state.user);
            } else if (state is AuthError) {
              return _buildErrorBody(state.message);
            } else {
              // Unauthenticated - redirect to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Center(child: LoadingIndicator());
            }
          },
        ),
      ),
      bottomNavigationBar: navigation.AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildMainContent(User user) {
    // Load ranking data if user is a player and ranking is not loaded
    if (user.isPlayer && _userRanking == null && !_isLoadingRanking) {
      _loadUserRanking(user);
    }

    // Use IndexedStack to keep navigation persistent
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // 0: Home
        _buildHomeContent(user),
        // 1: Tournaments
        _buildTournamentContent(),
        // 2: Communities
        _buildCommunityContent(),
        // 3: Shop
        _buildShopContent(),
        // 4: Profile
        _buildProfileContent(user),
      ],
    );
  }

  Widget _buildHomeContent(User user) {
    // Show different view based on user type
    if (user.isPlayer) {
      // Player view with ranks - wrapped in SingleChildScrollView
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: PlayerHomeView(
          userName: user.fullName,
          communityName: _getCommunityName(user),
          userImageUrl: user.profileImageUrl,
          communityRank: _userRanking?.communityRank ?? 0,
          nationalRank: _userRanking?.nationalRank ?? 0,
          onNotificationTap: _navigateToNotifications,
          onTournamentsSeeAllTap: () => _switchToTab(1),
          onCommunitiesSeeAllTap: () => _switchToTab(2),
          onShootersSeeAllTap: () => _switchToTab(4), // Profile for now
        ),
      );
    } else {
      // Fan view with upgrade promotion - wrapped in SingleChildScrollView
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FanHomeView(
          userName: user.fullName,
          communityName: _getCommunityName(user),
          userImageUrl: user.profileImageUrl,
          onNotificationTap: _navigateToNotifications,
          onTournamentsSeeAllTap: () => _switchToTab(1),
          onCommunitiesSeeAllTap: () => _switchToTab(2),
          onShootersSeeAllTap: () => _switchToTab(4),
          onUpgradeTap: _handleUpgradeToPlayer,
          onShopTap: () => _switchToTab(3),
        ),
      );
    }
  }

  Widget _buildTournamentContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;

          if (user.isPlayer) {
            // Players can participate in tournaments
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tournament participation header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: AppTheme.accentColor, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tournament Hub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Join competitions and track your progress',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tournament categories
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.construction,
                              size: 64, color: Colors.white54),
                          const SizedBox(height: 16),
                          const Text(
                            'Tournament Features',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Coming soon...',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Future: Navigate to tournament creation
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Tournament'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Fans can only spectate tournaments
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Spectator mode header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.blue, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tournament Spectator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Watch live tournaments and follow your favorite players',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Upgrade prompt
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.star,
                            color: AppTheme.accentColor, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Want to Participate?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Upgrade to Player to join tournaments',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleUpgradeToPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Upgrade to Player'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Live tournaments for viewing
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.live_tv,
                              size: 64, color: Colors.white54),
                          const SizedBox(height: 16),
                          const Text(
                            'Live Tournaments',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Coming soon...',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildCommunityContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;

          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Community header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isPlayer
                                  ? 'Your Communities'
                                  : 'Browse Communities',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.isPlayer
                                  ? 'Manage your community memberships'
                                  : 'Discover communities to follow',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User-specific content
                if (user.isPlayer) ...[
                  // Player community management
                  if (user.communityId != null) ...[
                    // User has a community
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified,
                                  color: AppTheme.accentColor, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Community',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCommunityName(user) ?? 'Community Name',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Player without community
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group_add,
                              color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Join a Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Connect with players in your area',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to community selection
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Browse Communities'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Fan community browsing
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.explore, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Explore Communities',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Follow communities and their tournaments',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Browse communities as spectator
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blue),
                                ),
                                child: const Text('Browse',
                                    style: TextStyle(color: Colors.blue)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleUpgradeToPlayer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Join as Player'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Coming soon placeholder
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.construction,
                            size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          'Community Features',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Coming soon...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildShopContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Shop header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.purple, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pool Billiard Shop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Equipment, merchandise, and accessories',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Shop categories
          Row(
            children: [
              Expanded(
                child: _buildShopCategory(
                  icon: Icons.sports,
                  title: 'Equipment',
                  subtitle: 'Cues & Tables',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShopCategory(
                  icon: Icons.checkroom,
                  title: 'Merchandise',
                  subtitle: 'Apparel & Gear',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Coming soon
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.construction,
                      size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'Shop Features',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Coming soon...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCategory({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              user.email,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutEvent());
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry authentication check
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation for different tabs
    _switchToTab(index);
  }

  void _switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _handleUpgradeToPlayer() {
    // Navigate to upgrade/payment screen
    Navigator.pushNamed(context, '/payment');
  }

  // Load user ranking data
  Future<void> _loadUserRanking(User user) async {
    if (_isLoadingRanking) return;

    setState(() {
      _isLoadingRanking = true;
    });

    try {
      final rankingService = di.sl<RankingService>();
      final ranking = await rankingService.getUserRanking(
        user.id,
        communityId: user.communityId,
      );

      if (mounted) {
        setState(() {
          _userRanking = ranking;
          _isLoadingRanking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRanking = false;
        });
      }
    }
  }

  // Helper methods to extract user data
  String? _getCommunityName(User user) {
    // This would typically fetch community name from community service
    // For now, return a placeholder or null
    return user.communityId != null ? 'Community Name' : null;
  }
}
