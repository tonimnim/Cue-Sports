import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';

class EmailVerificationWaitingScreen extends StatefulWidget {
  static const String routeName = '/email-verification-waiting';

  const EmailVerificationWaitingScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends State<EmailVerificationWaitingScreen> {
  String? email;
  String? fullName;
  String? userType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      email = args['email'] as String?;
      fullName = args['fullName'] as String?;
      userType = args['userType'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailVerificationCompleted) {
            // Show success message and handle navigation based on user type
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PlayerAccountCreated) {
            // Player needs to complete payment
            Navigator.pushReplacementNamed(
              context,
              '/payment',
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
              },
            );
          } else if (state is AuthAuthenticated) {
            // User is fully authenticated (fan or player with completed payment)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is VerificationEmailResent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Email address
              if (email != null) ...[
                Text(
                  'We sent a verification link to:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    email!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Instructions
              Text(
                'Please check your email and click the verification link to complete your ${userType ?? 'account'} registration.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Additional instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Important:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Check your spam/junk folder if you don\'t see the email\n'
                      '• The verification link expires in 24 hours\n'
                      '• Click the link on the same device where possible',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Resend button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: email != null
                      ? () {
                          context.read<AuthBloc>().add(
                                ResendPendingVerificationEmailEvent(
                                    email: email!),
                              );
                        }
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resend Verification Email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Change email or cancel
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text('Use Different Email'),
                    ),
                  ),
                  const Text('|'),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text('Back to Login'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
