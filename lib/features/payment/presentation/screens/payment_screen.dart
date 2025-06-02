import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/widget/inputs/phone_text_field.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentType;
  final String typeId;
  final String userId;
  final double amount;
  final String prefillPhoneNumber; // Phone number from registration

  const PaymentScreen({
    super.key,
    required this.paymentType,
    required this.typeId,
    required this.userId,
    required this.amount,
    required this.prefillPhoneNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.prefillPhoneNumber;
  }

  void _processPayment() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    // Format phone number if needed
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.replaceFirst('0', '254');
    }

    // Dispatch payment event
    context.read<PaymentBloc>().add(
          InitiatePaymentEvent(
            userId: widget.userId,
            paymentType: widget.paymentType,
            typeId: widget.typeId,
            phoneNumber: phoneNumber,
            amount: widget.amount,
          ),
        );
  }

  void _showSuccessDialog(String? mpesaReceiptNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Kenya Pool Billiards Club!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your player account has been created successfully.',
              textAlign: TextAlign.center,
            ),
            if (mpesaReceiptNumber != null) ...[
              const SizedBox(height: 16),
              Text(
                'M-Pesa Receipt: $mpesaReceiptNumber',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Continue to Home'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentBloc>().add(ResetPaymentEvent());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
        centerTitle: true,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showSuccessDialog(state.payment.mpesaReceiptNumber);
          } else if (state is PaymentFailure) {
            _showErrorDialog(state.message);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment amount
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Registration Fee',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Phone number input
                PhoneTextField(
                  controller: _phoneController,
                  readOnly:
                      true, // Phone number is pre-filled from registration
                  hintText: 'M-Pesa Phone Number',
                ),
                const SizedBox(height: 16),

                // Payment instructions
                Text(
                  'You will receive an M-Pesa prompt on ${_phoneController.text}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Pay button
                ElevatedButton(
                  onPressed: state is PaymentLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: state is PaymentLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Pay Now'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
