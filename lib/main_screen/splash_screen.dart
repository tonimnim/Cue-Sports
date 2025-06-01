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
    final authRepository = sl<AuthRepository>();
    logger.i('🚀 Checking authentication status...');

    try {
      // Ensure splash screen shows for at least 1 second
      final splashStartTime = DateTime.now();
      
      // Use AuthRepository for comprehensive auth check instead of just token
      final result = await authRepository.getCurrentUser();

      result.fold(
        (failure) {
          logger.w('❌ Auth check failed: ${failure.message}');
          _ensureMinimumSplashTime(splashStartTime, _navigateToLogin);
        },
        (user) {
          if (user == null) {
            logger.i('👤 No user logged in');
            _ensureMinimumSplashTime(splashStartTime, _navigateToLogin);
          } else {
            logger.i('✅ User authenticated: ${user.fullName}');
            
            // IMPROVED: Better payment status checking
            if (user.isPlayer) {
              final paymentStatus = user.playerPaymentStatus;
              logger.i('💳 Player payment status: $paymentStatus');
              
              if (paymentStatus == PaymentStatus.completed) {
                logger.i('✅ Payment completed, navigating to home');
                _ensureMinimumSplashTime(splashStartTime, _navigateToHome);
              } else {
                logger.i('⏳ Payment incomplete, navigating to payment screen');
                _ensureMinimumSplashTime(splashStartTime, () => _navigateToOptimizedPayment(user));
              }
            } else {
              // Fan user, go directly to home
              logger.i('👥 Fan user, navigating to home');
              _ensureMinimumSplashTime(splashStartTime, _navigateToHome);
            }
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Auth check exception: $e');
      _navigateToLogin();
    }
  }

  // Ensure splash screen shows for minimum duration for better UX
  void _ensureMinimumSplashTime(DateTime startTime, VoidCallback navigationCallback) {
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

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _navigateToOptimizedPayment(User user) {
    if (mounted) {
      // Generate M-Pesa prompt for existing user
      final mpesaPrompt = 'Send KSh 500 to MPESA Till Number 247247\nReference: ${user.playerPaymentId ?? 'PENDING'}\nFor: ${user.fullName}';
      
      Navigator.of(context).pushReplacementNamed(
        '/payment-optimized',
        arguments: {
          'user': user,
          'paymentId': user.playerPaymentId ?? 'PENDING_${user.id}',
          'mpesaPrompt': mpesaPrompt,
          'amount': 500.0,
        },
      );
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
