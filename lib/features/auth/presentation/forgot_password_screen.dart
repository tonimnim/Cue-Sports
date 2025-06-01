import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'package:pool_billiard_app/widget/inputs/email_text_field.dart';

/// Screen for password reset functionality
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResetSent = false;
  // We don't need a separate _resetEmail field, we'll use _emailController.text

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dispatch forgot password event
    context.read<AuthBloc>().add(
          ForgotPasswordEvent(
            email: _emailController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Back',
          style: TextStyle(color: Colors.blue, fontSize: 16),
        ),
        titleSpacing: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PasswordResetSent) {
            // Navigate to verification code screen
            Navigator.of(context).pushNamed(
              '/verification-code',
              arguments: {'email': state.email},
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child:
                _isResetSent ? _buildSuccessView() : _buildResetForm(isLoading),
          );
        },
      ),
    );
  }

  Widget _buildResetForm(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // X Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 40),
                child: const Icon(
                  Icons.close,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),

            // Title
            const Text(
              'Enter your email address',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Instructions
            const Text(
              'We\'ll send a verification code to reset your password',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email input
            EmailTextField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                }
                // Basic email validation
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            PrimaryButton(
              text: 'Reset Password',
              onPressed: _submitForm,
              isLoading: isLoading,
            ),

            // Return to login link
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text(
                  'Return to login',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success icon
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),

          // Success message
          Text(
            'Reset link sent to ${_emailController.text}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please check your email for instructions to reset your password.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Return to login button
          PrimaryButton(
            text: 'Return to Login',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            isLoading: false,
          ),
          const SizedBox(height: 16),

          // Try again link
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isResetSent = false;
                });
              },
              child: const Text(
                'Try with different number',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
