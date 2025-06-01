import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/main_screen/home/fan_home_view.dart';
import 'package:pool_billiard_app/main_screen/home/player_home_view.dart';
import 'package:pool_billiard_app/widget/display/buttom_navigation' as navigation;
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user_ranking.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/core/services/ranking_service.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;

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
              return _buildAuthenticatedBody(state.user);
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
  
  Widget _buildAuthenticatedBody(User user) {
    // Load ranking data if user is a player and ranking is not loaded
    if (user.isPlayer && _userRanking == null && !_isLoadingRanking) {
      _loadUserRanking(user);
    }

    // Show different view based on user type
    if (user.isPlayer) {
      // Player view with ranks
      return PlayerHomeView(
        userName: user.fullName,
        communityName: _getCommunityName(user),
        userImageUrl: user.profileImageUrl,
        communityRank: _userRanking?.communityRank ?? 0,
        nationalRank: _userRanking?.nationalRank ?? 0,
        onNotificationTap: _navigateToNotifications,
        onTournamentsSeeAllTap: () => _navigateToSection(1),
        onCommunitiesSeeAllTap: () => _navigateToSection(2),
        onShootersSeeAllTap: () => _navigateToSection(3),
      );
    } else {
      // Fan view with upgrade promotion
      return FanHomeView(
        userName: user.fullName,
        communityName: _getCommunityName(user),
        userImageUrl: user.profileImageUrl,
        onNotificationTap: _navigateToNotifications,
        onTournamentsSeeAllTap: () => _navigateToSection(1),
        onCommunitiesSeeAllTap: () => _navigateToSection(2),
        onShootersSeeAllTap: () => _navigateToSection(3),
        onUpgradeTap: _handleUpgradeToPlayer,
        onShopTap: () => _navigateToSection(3), // Navigate to shop
      );
    }
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
    _navigateToSection(index);
  }
  
  void _navigateToSection(int index) {
    switch (index) {
      case 0: // Home
        // Already on home
        break;
      case 1: // Tournaments
        Navigator.pushNamed(context, '/tournaments');
        break;
      case 2: // Communities
        Navigator.pushNamed(context, '/communities');
        break;
      case 3: // Shop
        Navigator.pushNamed(context, '/shop');
        break;
    }
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