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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
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
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Become A Player By Paying\n500 Ksh',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Mobile number input
                _buildMobileNumberInput(),

                const SizedBox(height: 60),

                // Pay button
                _buildPayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.user.phoneNumber,
          enabled: false, // Pre-filled and disabled
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF40916C),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF40916C),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF52B788),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF40916C),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: const Icon(
              Icons.phone,
              color: Color(0xFF52B788),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _isPaymentVerifying ? null : _handleTestPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.registerButtonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      child: _isPaymentVerifying
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Pay(Ksh 500)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
}
