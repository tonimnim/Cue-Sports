import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/core/services/logger_service.dart';
import 'package:pool_billiard_app/features/auth/domain/auth_repository.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';

import '../constants/asset_paths.dart';

/// Splash screen that displays on app startup
///
/// Shows the Kenya Pool Billiards logo and checks if a user is already logged in
/// Maximum display time is 2 seconds for optimal user experience
class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();

    // Setup fade-in animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Faster animation
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Start auth check immediately
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasCheckedAuth) return;
    _hasCheckedAuth = true;

    final logger = sl<LoggerService>();
    logger.i('🚀 Checking authentication status...');

    try {
      // Ensure splash screen shows for minimum duration for better UX
      final splashStartTime = DateTime.now();

      // DON'T navigate from splash screen - let AuthWrapper handle all navigation
      // Just ensure minimum splash time and let BLoC states drive navigation
      _ensureMinimumSplashTime(splashStartTime, () {
        // Do nothing - AuthWrapper will handle navigation based on auth states
        logger.i(
            '🎯 Splash screen timer completed - letting AuthWrapper handle navigation');
      });
    } catch (e) {
      logger.e('🔥 Auth check exception: $e');
      // Still don't navigate - let AuthWrapper show login screen
    }
  }

  // Ensure splash screen shows for minimum duration for better UX
  void _ensureMinimumSplashTime(
      DateTime startTime, VoidCallback navigationCallback) {
    const minimumSplashDuration = Duration(milliseconds: 1500); // 1.5 seconds
    final elapsed = DateTime.now().difference(startTime);

    if (elapsed < minimumSplashDuration) {
      Future.delayed(minimumSplashDuration - elapsed, () {
        if (mounted) {
          navigationCallback();
        }
      });
    } else {
      navigationCallback();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                AssetPaths.logo,
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 30),
              // App name
              Text(
                'Kenya Pool Billiards',
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 50),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
