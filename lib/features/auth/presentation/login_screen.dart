import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/core/utils/phone_validator.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'package:pool_billiard_app/widget/buttons/text_button.dart';
import 'package:pool_billiard_app/widget/display/app_logo.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/widget/inputs/password_text_field.dart';
import 'package:pool_billiard_app/widget/inputs/phone_text_field.dart';
import 'package:pool_billiard_app/constants/asset_paths.dart';

/// Login screen for Kenya Pool Billiards app
///
/// Optimized for instant loading after logout with minimal delays
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Remove back button for cleaner UX after logout
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Handle authentication errors with user feedback
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Handle successful authentication - IMMEDIATE navigation
          else if (state is AuthAuthenticated) {
            // Clear any previous navigation stack and go directly to home
            // AuthWrapper will handle the routing, so we just need to pop any overlays
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Let AuthWrapper handle the navigation to home screen
          }
          // Handle player payment requirement
          else if (state is PlayerPaymentRequired) {
            // AuthWrapper will handle navigation to payment screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          // Show loading overlay instead of replacing entire screen for better UX
          return Stack(
            children: [
              // Main login form - always visible for instant loading
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and welcome text
                      const SizedBox(height: 32),
                      SvgPicture.asset(
                        AssetPaths.logo,
                        height: 200,
                        width: 200,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back!',
                        style: AppTheme.headingStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Phone number field
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '0712345678',
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
                        onPressed: state is AuthLoading ? null : _handleLogin,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style:
                                AppTheme.bodyStyle.copyWith(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/register');
                            },
                            child: const Text('Create Account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay - only show when absolutely necessary
              if (state is AuthLoading &&
                  !state.message.contains('Signing out'))
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: LoadingIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
