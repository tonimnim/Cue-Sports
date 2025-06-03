import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/widget/display/enhanced_error_display.dart';
import 'package:pool_billiard_app/widget/display/themed_loading_indicator.dart';
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
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  Timer? _verificationTimeout;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _startVerificationTimeout();
  }

  @override
  void dispose() {
    // Critical: Proper cleanup to prevent memory leaks
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    _verificationTimeout?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 120); // 2 minutes

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        EnhancedErrorDisplay.showWarning(
          context,
          message: 'Verification timed out. Please try again.',
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  String get _verificationCode {
    return _codeControllers.map((controller) => controller.text).join();
  }

  void _verifyCode() {
    final code = _verificationCode;
    if (code.length != 6) {
      EnhancedErrorDisplay.showSnackBar(
        context,
        error: 'Please enter the complete 6-digit code',
        errorCode: 'incomplete_code',
      );
      return;
    }

    setState(() => _isLoading = true);
    _startVerificationTimeout(); // Restart timeout protection

    context.read<AuthBloc>().add(
          VerifySmsCodeEvent(
            phoneNumber: widget.phoneNumber,
            verificationCode: code,
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

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Verify Phone Number',
          style: AppTheme.headingStyle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textLight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Cancel timeout and reset loading on any state change
          _verificationTimeout?.cancel();
          if (mounted) {
            setState(() => _isLoading = false);
          }

          if (state is AuthError) {
            EnhancedErrorDisplay.showSnackBar(
              context,
              error: state.message,
              errorCode: 'sms_verification_error',
            );
          } else if (state is RegistrationCompleted) {
            // Registration successful - navigate immediately based on user type
            EnhancedErrorDisplay.showSuccess(
              context,
              message:
                  'Welcome to Cue Sports! Registration completed successfully!',
              duration: const Duration(seconds: 2),
            );

            // Fast navigation based on user type
            _navigateToUserHome(context, state.user);
          } else if (state is AuthAuthenticated) {
            // Alternative success state - also navigate
            _navigateToUserHome(context, state.user);
          } else if (state is PlayerAccountCreated) {
            // Player created but needs payment
            EnhancedErrorDisplay.showInfo(
              context,
              message: 'Registration completed! Please complete payment.',
              duration: const Duration(seconds: 2),
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
            EnhancedErrorDisplay.showWarning(
              context,
              message: 'Registration completed! Please complete payment.',
              duration: const Duration(seconds: 2),
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
          } else if (state is SmsCodeResent) {
            EnhancedErrorDisplay.showSuccess(
              context,
              message: 'Verification code resent successfully!',
              duration: const Duration(seconds: 2),
            );
          }
        },
        builder: (context, state) {
          // Show loading overlay for better UX
          final isLoading = state is AuthLoading || _isLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Phone icon in orange container
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.registerButtonColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.phone_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Verify Phone',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // 6 OTP input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 60,
                          child: TextFormField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFB7C5B6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.registerButtonColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                              counterText: '', // Hide character counter
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onCodeChanged(value, index),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    // Verify button
                    ElevatedButton(
                      onPressed: isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.registerButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: isLoading
                          ? const ThemedLoadingIndicator(
                              size: 24,
                              color: Colors.white,
                            )
                          : const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Resend code section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Didn\'t receive code? ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: (_resendCountdown > 0 || isLoading)
                              ? null
                              : _resendCode,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.registerButtonColor,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _resendCountdown > 0
                                ? 'Resend SMS (${_resendCountdown}s)'
                                : 'Resend SMS',
                            style: TextStyle(
                              color: (_resendCountdown > 0 || isLoading)
                                  ? Colors.white38
                                  : AppTheme.registerButtonColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
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
