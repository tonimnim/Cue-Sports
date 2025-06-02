import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';

class EmailVerificationHandler extends StatefulWidget {
  static const String routeName = '/verify-email';

  const EmailVerificationHandler({Key? key}) : super(key: key);

  @override
  State<EmailVerificationHandler> createState() =>
      _EmailVerificationHandlerState();
}

class _EmailVerificationHandlerState extends State<EmailVerificationHandler> {
  bool _isProcessing = true;
  String? _email;
  String? _verificationCode;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processVerificationLink();
  }

  void _processVerificationLink() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Extract parameters from arguments or URI
    if (args != null) {
      _email = args['email'] as String?;
      _verificationCode = args['code'] as String?;
    }

    // Validate parameters
    if (_email == null || _verificationCode == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Invalid verification link. Please try registering again.';
      });
      return;
    }

    // Trigger email verification
    context.read<AuthBloc>().add(
          VerifyEmailFromPendingEvent(
            email: _email!,
            verificationCode: _verificationCode!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailVerificationCompleted) {
            setState(() {
              _isProcessing = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate after a short delay to show the success message
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            });
          } else if (state is PlayerAccountCreated) {
            setState(() {
              _isProcessing = false;
            });

            // Navigate to payment page for players
            Navigator.pushReplacementNamed(
              context,
              '/payment',
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
              },
            );
          } else if (state is AuthAuthenticated) {
            setState(() {
              _isProcessing = false;
            });

            // Navigate to home for completed registrations
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else if (state is AuthError) {
            setState(() {
              _isProcessing = false;
              _errorMessage = state.message;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                // Processing state
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.blue.shade600,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verifying Your Email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please wait while we verify your email address and complete your registration...',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ] else if (_errorMessage != null) ...[
                // Error state
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verification Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons for error
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/register',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Register Again'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back to Login'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Success state (temporary, should navigate away quickly)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Email Verified!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your email has been verified successfully. Redirecting...',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  color: Colors.green.shade600,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
