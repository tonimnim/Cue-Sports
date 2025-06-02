import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/core/utils/phone_validator.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'package:pool_billiard_app/widget/buttons/text_button.dart';
import 'package:pool_billiard_app/widget/display/app_logo.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/widget/inputs/password_text_field.dart';
import 'package:pool_billiard_app/widget/inputs/phone_text_field.dart';

/// Login screen for Kenya Pool Billiards app
///
/// First screen users see after splash screen if not authenticated
class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Format phone number to standard format
    final formattedPhone = PhoneValidator.formatKenyanNumber(phone);
    if (formattedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number format')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          LoginEvent(
            phoneNumber: formattedPhone,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthAuthenticated) {
            // Check if player needs to complete payment
            if (state.user.userType == 'player' &&
                state.user.paymentStatus == false) {
              // Navigate to player payment screen
              Navigator.pushReplacementNamed(
                context,
                '/player-payment',
                arguments: {
                  'user': state.user,
                  'paymentId':
                      state.user.playerPaymentId ?? 'PENDING_${state.user.id}',
                  'paymentDeadline':
                      state.user.createdAt.add(const Duration(days: 2)),
                },
              );
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else if (state is PlayerPaymentRequired) {
            // Navigate to player payment screen for unpaid players
            Navigator.pushReplacementNamed(
              context,
              '/player-payment',
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
                'paymentDeadline': state.paymentDeadline,
              },
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: LoadingIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and welcome text
                  const SizedBox(height: 32),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Phone number field
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return PhoneValidator.getErrorMessage(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
