import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/features/auth/presentation/login_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/register_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/community_selection_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/select_community_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/select_community_optimized_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/pages/email_verification_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/pages/player_payment_screen.dart';
import 'package:pool_billiard_app/features/payment/presentation/screens/unified_payment_screen.dart';
import 'package:pool_billiard_app/features/payment/domain/entities/payment.dart'
    as payment_entity;
import 'package:pool_billiard_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;
import 'package:pool_billiard_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:pool_billiard_app/features/shop/presentation/bloc/shop_event.dart';

// Import individual pages
import '../main_screen/splash_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';

// Import screen implementations
import '../main_screen/home/home.dart';
import '../features/shop/presentation/screens/shop_main_screen.dart';
import '../features/shop/presentation/screens/bloc_cart_screen.dart';
import '../features/shop/presentation/screens/shop_orders_screen.dart';

import '../features/tournaments/presentation/tournament_screen.dart';

class RouteConfig {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register'; // Combined registration screen
  static const String emailVerification =
      '/email-verification'; // New Firebase email verification
  static const String communitySelection = '/community-selection';
  static const String selectCommunity = '/select-community';
  static const String selectCommunityOptimized = '/select-community-optimized';
  static const String payment = '/payment';
  static const String unifiedPayment =
      '/unified-payment'; // New unified payment route
  static const String playerPayment =
      '/player-payment'; // New player payment screen
  static const String paymentSimulation =
      '/payment-simulation'; // Payment simulation for testing
  static const String passwordReset = '/forgot-password';
  static const String home = '/home';

  // Feature route names
  static const String communities = '/communities';
  static const String tournaments = '/tournaments';
  static const String shop = '/shop';
  static const String cart = '/cart';
  static const String orders = '/orders';
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
      case paymentSimulation:
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
        // Redirect old payment route to unified payment
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }

        // Convert old string payment type to enum
        payment_entity.PaymentType? paymentType;
        final typeString = args['paymentType'] as String?;
        if (typeString != null) {
          switch (typeString.toLowerCase()) {
            case 'registration':
              paymentType = payment_entity.PaymentType.registration;
              break;
            case 'tournament':
            case 'tournament_registration':
              paymentType = payment_entity.PaymentType.tournament;
              break;
            case 'merchandise':
            case 'shop':
              paymentType = payment_entity.PaymentType.merchandise;
              break;
          }
        }

        if (paymentType == null) {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }

        return MaterialPageRoute(
            builder: (_) => BlocProvider(
                  create: (context) => di.sl<PaymentBloc>(),
                  child: UnifiedPaymentScreen(
                    paymentType: paymentType!,
                    typeId: args['typeId'] as String,
                    userId: args['userId'] as String,
                    amount: args['amount'] as double,
                    prefillPhoneNumber: args['prefillPhoneNumber'] as String?,
                  ),
                ));
      case unifiedPayment:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return MaterialPageRoute(
            builder: (_) => BlocProvider(
                  create: (context) => di.sl<PaymentBloc>(),
                  child: UnifiedPaymentScreen(
                    paymentType:
                        args['paymentType'] as payment_entity.PaymentType,
                    typeId: args['typeId'] as String,
                    userId: args['userId'] as String,
                    amount: args['amount'] as double,
                    prefillPhoneNumber: args['prefillPhoneNumber'] as String?,
                    metadata: args['metadata'] as Map<String, dynamic>?,
                    onSuccess: args['onSuccess'] as VoidCallback?,
                    onFailure: args['onFailure'] as VoidCallback?,
                  ),
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
          builder: (_) => const HomeScreen(),
        );
      case tournaments:
        return MaterialPageRoute(
          builder: (_) => const TournamentScreen(),
        );
      case shop:
        return MaterialPageRoute(
          builder: (_) => const ShopMainScreen(),
        );
      case cart:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) =>
                di.sl<ShopBloc>()..add(LoadCartItemsEvent('current_user')),
            child: const BlocCartScreen(),
          ),
        );
      case orders:
        return MaterialPageRoute(
          builder: (_) => const ShopOrdersScreen(),
        );
      case notifications:
        // Placeholder until notifications screen is implemented
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body:
                const Center(child: Text('Notifications screen - Coming soon')),
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
