import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/route_config.dart';
import 'core/config/theme.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/email_verification_screen.dart';
import 'features/auth/presentation/pages/player_payment_screen.dart';
import 'features/community/presentation/bloc/community_bloc.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'main_screen/splash_screen.dart';
import 'main_screen/home/home.dart';
import 'features/auth/presentation/login_screen.dart';

/// Main application widget with integrated authentication flow
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            final bloc = di.sl<AuthBloc>();
            // Check authentication status when app starts
            bloc.add(CheckAuthStatusEvent());
            return bloc;
          },
        ),
        BlocProvider<CommunityBloc>(
          create: (context) => di.sl<CommunityBloc>(),
        ),
        BlocProvider<PaymentBloc>(
          create: (context) => di.sl<PaymentBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kenya Pool Billiards',
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        onGenerateRoute: RouteConfig.generateRoute,
      ),
    );
  }
}

/// Wrapper widget that handles authentication state and navigation
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    // Don't call ResumeRegistrationEvent here - CheckAuthStatusEvent handles everything
    // The auth bloc already calls CheckAuthStatusEvent and handles registration drafts
    // as a fallback when no authenticated user is found
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle state transitions that require navigation
        if (state is EmailVerificationSent) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: state.email,
                uid: state.uid,
              ),
            ),
            (route) => false,
          );
        } else if (state is PlayerAccountCreated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => PlayerPaymentScreen(
                user: state.user,
                paymentId: state.paymentId,
              ),
            ),
            (route) => false,
          );
        } else if (state is PlayerPaymentRequired) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => PlayerPaymentScreen(
                user: state.user,
                paymentId: state.paymentId,
                paymentDeadline: state.paymentDeadline,
              ),
            ),
            (route) => false,
          );
        } else if (state is RegistrationExpired) {
          // Show expired message and redirect to login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }

        // Update initialization state
        if (_isInitializing && state is! AuthInitial && state is! AuthLoading) {
          setState(() => _isInitializing = false);
        }
      },
      builder: (context, state) {
        // Show splash screen during initialization or loading
        if (_isInitializing || state is AuthInitial || state is AuthLoading) {
          return const SplashScreen();
        }

        // PRIORITY: Handle authenticated users first (most common case)
        if (state is AuthAuthenticated ||
            state is FanRegistrationComplete ||
            state is PaymentCompleted ||
            state is RegistrationCompleted) {
          return const HomeScreen();
        }

        // Handle specific auth states for non-authenticated users
        if (state is EmailVerificationSent ||
            state is PollingEmailVerification) {
          return EmailVerificationScreen(
            email: state is EmailVerificationSent
                ? state.email
                : state is PollingEmailVerification
                    ? state.email
                    : '',
            uid: state is EmailVerificationSent
                ? state.uid
                : state is PollingEmailVerification
                    ? state.uid
                    : '',
          );
        }

        if (state is PlayerAccountCreated) {
          return PlayerPaymentScreen(
            user: state.user,
            paymentId: state.paymentId,
          );
        }

        if (state is PlayerPaymentRequired) {
          return PlayerPaymentScreen(
            user: state.user,
            paymentId: state.paymentId,
            paymentDeadline: state.paymentDeadline,
          );
        }

        if (state is RegistrationDraftSaved) {
          // Show appropriate registration screen
          if (state.draft.draftType == 'player' &&
              state.draft.communityId == null) {
            // Player needs to select community
            Navigator.of(context).pushReplacementNamed(
              RouteConfig.selectCommunityOptimized,
              arguments: {
                'fullName': state.draft.fullName,
                'email': state.draft.email,
                'phoneNumber': state.draft.phoneNumber,
                'password': state.draft.password,
              },
            );
          }
          return const SplashScreen(); // Temporary while navigating
        }

        if (state is EmailVerified) {
          // Automatically proceed to create Firestore user
          context.read<AuthBloc>().add(CreateFirestoreUserEvent(
                uid: state.uid,
                draft: state.draft,
              ));
          return const SplashScreen();
        }

        if (state is CommunitiesLoading || state is CommunitiesLoaded) {
          // Show community selection screen
          return const SplashScreen(); // This will be handled by route navigation
        }

        // Default to login screen for unauthenticated users or errors
        return const LoginScreen();
      },
    );
  }
}
