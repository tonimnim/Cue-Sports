import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';

class SmsVerificationScreen extends StatefulWidget {
  static const String routeName = '/sms-verification';

  final String phoneNumber;
  final String fullName;

  const SmsVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.fullName,
  }) : super(key: key);

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _verificationTimeout; // Add timeout protection

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _startVerificationTimeout(); // Start timeout protection
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 120); // 2 minutes

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startVerificationTimeout() {
    // Prevent infinite loading - timeout after 30 seconds
    _verificationTimeout?.cancel();
    _verificationTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification timed out. Please try again.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _startVerificationTimeout(); // Restart timeout protection

    context.read<AuthBloc>().add(
          VerifySmsCodeEvent(
            phoneNumber: widget.phoneNumber,
            verificationCode: _codeController.text.trim(),
          ),
        );
  }

  void _resendCode() {
    if (_resendCountdown > 0) return;

    context.read<AuthBloc>().add(
          ResendSmsCodeEvent(phoneNumber: widget.phoneNumber),
        );

    _startResendCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    _verificationTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Cancel timeout and reset loading on any state change
          _verificationTimeout?.cancel();
          setState(() => _isLoading = false);

          if (state is SmsVerificationInProgress) {
            // Keep loading state for verification in progress
            setState(() => _isLoading = true);
            _startVerificationTimeout(); // Restart timeout protection
          } else if (state is SmsVerificationFailed) {
            // Handle SMS verification failure
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is SmsVerificationSent) {
            // Handle SMS code resent
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is RegistrationCompleted) {
            // Registration successful - navigate immediately based on user type
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Welcome to Cue Sports! Registration completed successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            // Fast navigation based on user type
            _navigateToUserHome(context, state.user);
          } else if (state is AuthAuthenticated) {
            // Alternative success state - also navigate
            _navigateToUserHome(context, state.user);
          } else if (state is PlayerAccountCreated) {
            // Player created but needs payment
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Registration completed! Please complete payment.'),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to payment screen
            Navigator.of(context).pushReplacementNamed(
              '/payment-simulation',
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
                'paymentDeadline':
                    state.user.createdAt.add(const Duration(days: 2)),
              },
            );
          } else if (state is PlayerPaymentRequired) {
            // Player registration completed but payment required
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Registration completed! Please complete payment.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to payment screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/payment-simulation',
              (route) => false,
              arguments: {
                'user': state.user,
                'paymentId': state.paymentId,
                'paymentDeadline': state.paymentDeadline,
              },
            );
          }
        },
        builder: (context, state) {
          // Show loading overlay for better UX
          final isLoading = state is AuthLoading || _isLoading;

          return Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // SMS icon
                        Icon(
                          Icons.sms_outlined,
                          size: 80,
                          color: Colors.blue[600],
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Verify Your Phone Number',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'We\'ve sent a 6-digit verification code to\n${widget.phoneNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Verification code input
                        TextFormField(
                          controller: _codeController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            hintText: 'Enter 6-digit code',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            fillColor: isLoading ? Colors.grey[100] : null,
                            filled: isLoading,
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter verification code';
                            }
                            if (value.length != 6) {
                              return 'Code must be 6 digits';
                            }
                            if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                              return 'Code must contain only numbers';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Verify button
                        ElevatedButton(
                          onPressed: isLoading ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Verify Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Resend code section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Didn\'t receive the code? ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: (_resendCountdown > 0 || isLoading)
                                  ? null
                                  : _resendCode,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _resendCountdown > 0
                                    ? 'Resend in ${_resendCountdown}s'
                                    : 'Resend Code',
                                style: TextStyle(
                                  color: (_resendCountdown > 0 || isLoading)
                                      ? Colors.grey
                                      : Colors.blue[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Help text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'The verification code is valid for 10 minutes. You have 3 attempts to enter the correct code.',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading overlay for better performance
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Verifying...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Fast navigation to user's home based on user type
  void _navigateToUserHome(BuildContext context, User user) {
    // Immediate navigation without delays for production performance
    if (user.userType == 'player') {
      if (user.paymentStatus == false) {
        // Player needs to complete payment
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/payment-simulation',
          (route) => false,
          arguments: {
            'user': user,
            'paymentId': user.playerPaymentId ?? '',
            'paymentDeadline': user.createdAt.add(const Duration(days: 2)),
          },
        );
      } else {
        // Player with completed payment goes to home
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: {'user': user},
        );
      }
    } else {
      // Fan goes directly to home
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'user': user},
      );
    }
  }
}
