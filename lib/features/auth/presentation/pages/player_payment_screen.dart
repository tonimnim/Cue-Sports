import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Player payment screen for completing registration
class PlayerPaymentScreen extends StatefulWidget {
  final User user;
  final String paymentId;
  final DateTime? paymentDeadline;

  const PlayerPaymentScreen({
    super.key,
    required this.user,
    required this.paymentId,
    this.paymentDeadline,
  });

  @override
  State<PlayerPaymentScreen> createState() => _PlayerPaymentScreenState();
}

class _PlayerPaymentScreenState extends State<PlayerPaymentScreen> {
  bool _isPaymentVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PaymentCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    '🎉 Payment verified! Welcome to Pool Billiards!'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate to home page with proper token management
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: {'user': widget.user},
            );
          } else if (state is AuthError) {
            setState(() => _isPaymentVerifying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthLoading) {
            setState(() => _isPaymentVerifying = true);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with back button
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // App logo/icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sports_basketball,
                              size: 50,
                              color: AppTheme.accentColor,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title
                          Text(
                            'Become A Club Player By\nPaying 500 Ksh',
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 28,
                              color: AppTheme.accentColor,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Mobile number input
                          _buildMobileNumberInput(),

                          const SizedBox(height: 40),

                          // Pay button
                          _buildPayButton(),

                          const SizedBox(height: 20),

                          // Skip button
                          _buildSkipButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textLight,
            size: 24,
          ),
        ),
        const Spacer(),
        Text(
          'Back',
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 16,
            color: AppTheme.textLight,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildMobileNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            initialValue: widget.user.phoneNumber,
            enabled: false, // Pre-filled and disabled
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textLight,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: Icon(
                Icons.phone,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isPaymentVerifying ? null : _handleTestPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPaymentVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textDark),
                ),
              )
            : Text(
                'Pay(Ksh 500)',
                style: AppTheme.buttonTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
      ),
    );
  }

  /// Handle test payment - auto-succeed for testing purposes
  void _handleTestPayment() {
    setState(() => _isPaymentVerifying = true);

    // Debug logging to check user data
    print('DEBUG: Full User Object: ${widget.user.toString()}');
    print('DEBUG: User ID: "${widget.user.id}"');
    print('DEBUG: User Email: "${widget.user.email}"');
    print('DEBUG: User Full Name: "${widget.user.fullName}"');
    print('DEBUG: User Phone: "${widget.user.phoneNumber}"');
    print('DEBUG: Payment ID: "${widget.paymentId}"');

    // Get user ID from Firebase Auth as fallback if user.id is empty
    String userId = widget.user.id;
    if (userId.isEmpty) {
      // Try to get user ID from Firebase Auth current user
      final firebaseUser = context.read<AuthBloc>().firebaseAuth.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
        print('DEBUG: Using Firebase Auth UID as fallback: "$userId"');
      }
    }

    // Validate user ID before proceeding
    if (userId.isEmpty) {
      setState(() => _isPaymentVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Error: No valid user ID found. Please try logging in again.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Simulate payment processing delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        print('DEBUG: Triggering payment verification for user: "$userId"');

        // Trigger payment verification with success
        context.read<AuthBloc>().add(
              VerifyPaymentEvent(
                paymentId: widget.paymentId,
                userId: userId, // Use the validated userId
                mpesaReceiptNumber:
                    'TEST${DateTime.now().millisecondsSinceEpoch}', // Generate test receipt
              ),
            );
      }
    });
  }

  Widget _buildSkipButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () {
          // Save current state and go to home
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
            arguments: {'user': widget.user},
          );
        },
        child: Text(
          'I\'ll pay later (2 days remaining)',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 14,
            color: AppTheme.textLight.withOpacity(0.7),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
