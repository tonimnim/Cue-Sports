import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Email verification screen with real-time polling status
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String uid;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.uid,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Email icon pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Loading rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Stop polling when user goes back
        context.read<AuthBloc>().add(StopEmailVerificationPollingEvent());
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is EmailVerified) {
              // Verification successful - navigation will be handled by main app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Email verified! Completing registration...'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: 60),
                      
                      // Main content
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Email icon with animation
                            _buildEmailIcon(),
                            
                            const SizedBox(height: 40),
                            
                            // Title
                            Text(
                              'Check Your Email',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email address
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B263B).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF415A77),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF71A9F7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Instructions
                            Text(
                              'We\'ve sent a verification link to your email address. Please click the link to continue with your registration.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFFE0E1DD),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Status indicator
                            _buildStatusIndicator(state),
                            
                            const SizedBox(height: 40),
                            
                            // Action buttons
                            _buildActionButtons(state),
                          ],
                        ),
                      ),
                      
                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.read<AuthBloc>().add(StopEmailVerificationPollingEvent());
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Spacer(),
        Text(
          'Email Verification',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40), // Balance the back button
      ],
    );
  }

  Widget _buildEmailIcon() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4DABF7),
              Color(0xFF71A9F7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DABF7).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.mail_outline_rounded,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AuthState state) {
    if (state is PollingEmailVerification) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B263B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF415A77),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(
                    Icons.refresh,
                    color: Color(0xFF71A9F7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Checking for verification...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF71A9F7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Attempt ${state.attemptCount}/120',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFE0E1DD).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: state.attemptCount / 120,
              backgroundColor: const Color(0xFF415A77).withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF71A9F7)),
            ),
          ],
        ),
      );
    } else if (state is EmailVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Email verified successfully!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (state is AuthError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(AuthState state) {
    return Column(
      children: [
        // Resend email button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: state is PollingEmailVerification
                ? () => context.read<AuthBloc>().add(
                      ResendVerificationEmailEvent(uid: widget.uid),
                    )
                : null,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              'Resend Verification Email',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF415A77),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              context.read<AuthBloc>().add(StopEmailVerificationPollingEvent());
              context.read<AuthBloc>().add(ClearRegistrationDraftEvent());
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Cancel Registration',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE0E1DD),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF415A77),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(
          color: Color(0xFF415A77),
          thickness: 1,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFF71A9F7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Check your spam folder if you don\'t see the email within a few minutes.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFE0E1DD).withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 