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
import 'package:pool_billiard_app/features/community/presentation/screens/community_screen.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/core/services/ranking_service.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:pool_billiard_app/features/shop/presentation/bloc/shop_event.dart';
import 'package:pool_billiard_app/features/shop/presentation/screens/shop_main_screen.dart';
import 'package:pool_billiard_app/features/tournaments/presentation/tournament_screen.dart';

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
  void initState() {
    super.initState();

    // Initialize shop data when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final shopBloc = context.read<ShopBloc>();
        shopBloc.add(LoadCartItemsEvent(authState.user.id));
        shopBloc.add(LoadProductsEvent());
        shopBloc.add(LoadFeaturedProductsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go to home tab instead of closing app
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Don't close the app
        }
        return true; // Allow app to close only when on home tab
      },
      child: Scaffold(
        backgroundColor:
            AppTheme.backgroundColor, // Use theme color for consistency
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
        BlocProvider(
          create: (context) => di.sl<CommunityBloc>(),
          child: const CommunityScreen(),
        ),
        // 3: Shop
        ShopMainScreen(
          onBackPressed: () => _switchToTab(0), // Go back to home tab
        ),
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
    return const TournamentScreen();
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
