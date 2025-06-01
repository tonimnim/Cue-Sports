import 'package:flutter/material.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/features/auth/presentation/login_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/register_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/community_selection_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/select_community_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/select_community_optimized_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/pages/email_verification_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/pages/player_payment_screen.dart';
import 'package:pool_billiard_app/features/payment/presentation/screens/payment_screen.dart';

// Import individual pages
import '../main_screen/splash_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/payment/presentation/screens/payment_screen.dart';

// Import screen implementations
import '../main_screen/home/home.dart';
import '../features/community/presentation/community_list_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
import '../features/tournaments/presentation/tournament_screen.dart';

class RouteConfig {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register'; // Combined registration screen
  static const String emailVerification = '/email-verification'; // New Firebase email verification
  static const String communitySelection = '/community-selection';
  static const String selectCommunity = '/select-community';
  static const String selectCommunityOptimized = '/select-community-optimized';
  static const String payment = '/payment';
  static const String playerPayment = '/player-payment'; // New player payment screen
  static const String passwordReset = '/forgot-password';
  static const String home = '/home';
  
  // Feature route names
  static const String communities = '/communities';
  static const String tournaments = '/tournaments';
  static const String shop = '/shop';
  static const String notifications = '/notifications';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case emailVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
                  email: args['email'] as String,
                  uid: args['uid'] as String,
                ));
      case playerPayment:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return MaterialPageRoute(
            builder: (_) => PlayerPaymentScreen(
                  user: args['user'] as User,
                  paymentId: args['paymentId'] as String,
                  paymentDeadline: args['paymentDeadline'] as DateTime?,
                ));
      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }
        return MaterialPageRoute(
            builder: (_) => PaymentScreen(
                  paymentType: args['paymentType'] as String,
                  typeId: args['typeId'] as String,
                  userId: args['userId'] as String,
                  amount: args['amount'] as double,
                  prefillPhoneNumber: args['prefillPhoneNumber'] as String? ?? '',
                ));
      case passwordReset:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case communitySelection:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        final isPlayer = args?['isPlayer'] as bool? ?? false;
        final userId = args?['userId'] as String?;
        final phoneNumber = args?['phoneNumber'] as String?;
        return MaterialPageRoute(
            builder: (_) => CommunitySelectionScreen(
                  email: email,
                  isPlayer: isPlayer,
                  userId: userId,
                  phoneNumber: phoneNumber,
                ));
      case selectCommunity:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }
        return MaterialPageRoute(
            builder: (_) => SelectCommunityScreen(
                  fullName: args['fullName'] as String,
                  email: args['email'] as String,
                  phoneNumber: args['phoneNumber'] as String,
                  password: args['password'] as String,
                ));
      case selectCommunityOptimized:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }
        return MaterialPageRoute(
            builder: (_) => SelectCommunityOptimizedScreen(
                  fullName: args['fullName'] as String,
                  email: args['email'] as String,
                  phoneNumber: args['phoneNumber'] as String,
                  password: args['password'] as String,
                ));
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case communities:
        return MaterialPageRoute(
          builder: (_) => const CommunityListScreen(),
        );
      case tournaments:
        return MaterialPageRoute(
          builder: (_) => const TournamentScreen(),
        );
      case shop:
        return MaterialPageRoute(
          builder: (_) => const ShopScreen(),
        );
      case notifications:
        // Placeholder until notifications screen is implemented
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: const Center(child: Text('Notifications screen - Coming soon')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
