import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _PlayerPaymentScreenState extends State<PlayerPaymentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _receiptController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPaymentVerifying = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _receiptController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.paymentDeadline ?? widget.user.createdAt.add(const Duration(days: 2));
    final timeRemaining = deadline.difference(DateTime.now());
    final isExpiringSoon = timeRemaining.inHours < 24;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PaymentCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Payment verified! Welcome to Pool Billiards!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigation will be handled by main app
          } else if (state is AuthError) {
            setState(() => _isPaymentVerifying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PaymentVerifying) {
            setState(() => _isPaymentVerifying = true);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 20),
                
                // Deadline warning
                if (isExpiringSoon) _buildDeadlineWarning(timeRemaining),
                
                const SizedBox(height: 20),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Payment icon
                        _buildPaymentIcon(),
                        
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          'Complete Your Registration',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        Text(
                          'Pay the registration fee to activate your player account',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFFE0E1DD),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Payment details card
                        _buildPaymentDetailsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Instructions card
                        _buildInstructionsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Receipt input
                        _buildReceiptInput(),
                        
                        const SizedBox(height: 32),
                        
                        // Verify payment button
                        _buildVerifyButton(),
                        
                        const SizedBox(height: 16),
                        
                        // Skip for now button
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
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Spacer(),
        Text(
          'Payment Required',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildDeadlineWarning(Duration timeRemaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.red.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment deadline approaching!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Time remaining: ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF8BC34A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.payment,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B263B).withOpacity(0.8),
            const Color(0xFF415A77).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Payment Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildPaymentRow('Amount:', 'KSh 500'),
          _buildPaymentRow('Till Number:', '247247'),
          _buildPaymentRow('Reference:', widget.paymentId),
          _buildPaymentRow('Name:', widget.user.fullName),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFFE0E1DD),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF415A77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF71A9F7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF71A9F7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ..._buildInstructionSteps(),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionSteps() {
    final steps = [
      'Open your M-Pesa app or dial *334#',
      'Select "Pay Bill" option',
      'Enter Till Number: 247247',
      'Enter Amount: 500',
      'Enter Reference: ${widget.paymentId}',
      'Complete payment and get receipt',
      'Enter receipt number below',
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFE0E1DD),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReceiptInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'M-Pesa Receipt Number',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextFormField(
          controller: _receiptController,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., QEF4G5H6I7',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFE0E1DD).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFF1B263B).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF415A77),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF415A77),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 2,
              ),
            ),
            prefixIcon: const Icon(
              Icons.receipt_long,
              color: Color(0xFF4CAF50),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Enter the receipt number from your M-Pesa payment confirmation SMS',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFE0E1DD).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPaymentVerifying || _receiptController.text.trim().isEmpty
            ? null
            : () {
                context.read<AuthBloc>().add(
                  VerifyPaymentEvent(
                    paymentId: widget.paymentId,
                    userId: widget.user.id,
                    mpesaReceiptNumber: _receiptController.text.trim(),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
            : Text(
                'Verify Payment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
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
          );
        },
        child: Text(
          'I\'ll pay later (2 days remaining)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFE0E1DD).withOpacity(0.7),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
} 