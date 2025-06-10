import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/utils/phone_validator.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';
import 'package:pool_billiard_app/features/auth/presentation/pages/sms_verification_screen.dart';
import 'package:pool_billiard_app/features/auth/presentation/community_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPlayer = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _handleRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Use the new pending registration system with uniqueness checks
    context.read<AuthBloc>().add(
          CreatePendingRegistrationEvent(
            fullName: fullName,
            email: email,
            phoneNumber: phone,
            password: password,
            userType: _isPlayer ? 'player' : 'fan',
            // For players, these will be handled in community selection
            communityId: null,
            paymentId: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SmsVerificationSent) {
            // Navigate to SMS verification screen with new state
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SmsVerificationScreen(
                  phoneNumber: state.phoneNumber,
                  fullName: state.fullName,
                ),
              ),
            );
          } else if (state is RegistrationDraftSaved) {
            // For players - navigate to community selection
            if (state.draft.draftType == 'player') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CommunitySelectionScreen(
                    email: state.draft.email,
                    isPlayer: true,
                  ),
                ),
              );
            }
          } else if (state is EmailVerificationCompleted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is VerificationEmailResent) {
            // Show resend success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.accentColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is FanRegistrationComplete) {
            // Fan registration completed successfully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Welcome!'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else if (state is PlayerAccountCreated) {
            // Player account created, redirect to payment
            Navigator.pushReplacementNamed(
              context,
              '/payment',
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
              },
            );
          } else if (state is AuthAuthenticated) {
            // User is now authenticated, go to home
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Main registration form - always visible for instant loading
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Show progress message during loading
                      if (isLoading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.accentColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state is AuthLoading
                                    ? state.message
                                    : (_isPlayer
                                        ? 'Setting up your player account...'
                                        : 'Creating your fan account...'),
                                style: AppTheme.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This should only take a few seconds',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // User type selection
                      _buildUserTypeSelection(),
                      const SizedBox(height: 24),

                      // Registration form
                      _buildFullNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPhoneField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 24),

                      // Register button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleRegistration,
                        child: isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_isPlayer
                                      ? 'Setting up...'
                                      : 'Creating Account...'),
                                ],
                              )
                            : Text(_isPlayer ? 'Continue' : 'Register'),
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style:
                                AppTheme.bodyStyle.copyWith(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  },
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Account Type',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Fan', style: AppTheme.bodyStyle),
              subtitle: Text(
                'Follow tournaments and connect with players',
                style: AppTheme.bodyStyle
                    .copyWith(fontSize: 14, color: Colors.grey),
              ),
              leading: Radio<bool>(
                value: false,
                groupValue: _isPlayer,
                activeColor: AppTheme.accentColor,
                onChanged: (value) {
                  setState(() {
                    _isPlayer = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Player', style: AppTheme.bodyStyle),
              subtitle: Text(
                'Participate in tournaments and track stats',
                style: AppTheme.bodyStyle
                    .copyWith(fontSize: 14, color: Colors.grey),
              ),
              leading: Radio<bool>(
                value: true,
                groupValue: _isPlayer,
                activeColor: AppTheme.accentColor,
                onChanged: (value) {
                  setState(() {
                    _isPlayer = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: Icon(Icons.person),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Full name is required';
        }
        if (value.trim().split(' ').length < 2) {
          return 'Please enter both first and last name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
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
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Confirm your password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: _toggleConfirmPasswordVisibility,
        ),
      ),
      obscureText: _obscureConfirmPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
