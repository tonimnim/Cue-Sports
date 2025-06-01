import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:pool_billiard_app/widget/inputs/phone_text_field.dart';

enum PaymentStatus { initial, pending, success, failed }

class PaymentScreen extends StatefulWidget {
  final String paymentType; // registration, tournament, or merchandise
  final String typeId; // club_id, tournament_id, or product_id
  final String userId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.paymentType,
    required this.typeId,
    required this.userId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  PaymentStatus _paymentStatus = PaymentStatus.initial;
  bool _isLoading = false;
  Timer? _statusCheckTimer;
  String? _checkoutRequestID;
  String _errorMessage = '';
  String? _mpesaReceiptNumber;
  String? _txnUnique; // Store the transaction unique identifier

  @override
  void initState() {
    super.initState();
    // For testing, using sample data
    _phoneController.text = "0748023691"; // Remove in production
  }

  Future<void> _processPayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    // Generate txn_unique before proceeding
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _txnUnique = "${widget.userId}_$timestamp";
    developer.log(
      'Generated txn_unique: $_txnUnique for userId: ${widget.userId} at timestamp: $timestamp',
      name: 'PaymentScreen',
    );

    setState(() {
      _isLoading = true;
      _paymentStatus = PaymentStatus.initial;
      _errorMessage = '';
    });

    try {
      // Format phone number if needed
      String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.startsWith('0')) {
        // Convert to international format if starts with 0
        phoneNumber = phoneNumber.replaceFirst('0', '254');
      }

      if (_txnUnique == null) {
        throw Exception('txn_unique generation failed');
      }

      // Create JSON payload with txn_unique
      final Map<String, dynamic> payload = {
        'payment_type': widget.paymentType,
        'type_id': widget.typeId,
        'user_id': widget.userId,
        'phone_number': phoneNumber,
        'amount': widget.amount.toString(),
        'txn_unique': _txnUnique,
      };

      developer.log(
        'Initiating payment request with payload: ${jsonEncode(payload)}',
        name: 'PaymentScreen',
      );

      // Send JSON request to initiate payment
      final response = await http.post(
        Uri.parse('https://seroxideentertainment.co.ke/pool/tinypesa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      developer.log(
        'Payment initiation response: Status=${response.statusCode}, Body=${response.body}',
        name: 'PaymentScreen',
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'success') {
            // Extract checkout request ID
            _checkoutRequestID = responseData['checkoutRequestID'];

            setState(() {
              _paymentStatus = PaymentStatus.pending;
            });

            _startStatusCheck();
          } else {
            setState(() {
              _paymentStatus = PaymentStatus.failed;
              _errorMessage =
                  responseData['message'] ?? 'Failed to initiate payment';
            });
            _showErrorDialog(_errorMessage);
          }
        } catch (e) {
          setState(() {
            _paymentStatus = PaymentStatus.failed;
            _errorMessage = 'Error parsing payment initiation response: $e';
          });
          _showErrorDialog(_errorMessage);
          developer.log(
            'Error parsing payment initiation response: $e',
            name: 'PaymentScreen',
            error: e,
          );
        }
      } else {
        setState(() {
          _paymentStatus = PaymentStatus.failed;
          _errorMessage =
              'Payment initiation failed: ${response.statusCode} - ${response.body}';
        });
        _showErrorDialog(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _paymentStatus = PaymentStatus.failed;
        _errorMessage = 'Network error during payment initiation: $e';
      });
      developer.log(
        'Network error during payment initiation: $e',
        name: 'PaymentScreen',
        error: e,
      );
      _showErrorDialog(_errorMessage);
    }
  }

  Future<void> _checkTransactionStatus() async {
    if (_txnUnique == null) {
      developer.log(
        'No txn_unique available for status check',
        name: 'PaymentScreen',
      );
      return;
    }

    try {
      // Prepare the payload for status check with txn_unique
      final Map<String, dynamic> payload = {'txn_unique': _txnUnique};

      // Log the data being sent
      developer.log(
        'Sending status check request to check_transaction.php with payload: ${jsonEncode(payload)}',
        name: 'PaymentScreen',
      );

      // Send status check request
      final response = await http.post(
        Uri.parse(
          'https://seroxideentertainment.co.ke/pool/check_transaction.php',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Log the response received
      developer.log(
        'Received response from check_transaction.php: Status=${response.statusCode}, Body=${response.body}',
        name: 'PaymentScreen',
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);

          // Log the checkoutRequestID
          if (responseData['checkoutRequestID'] != null) {
            developer.log(
              'Checkout Request ID: ${responseData['checkoutRequestID']}',
              name: 'PaymentScreen',
            );
          }

          if (responseData['status'] == 'completed') {
            setState(() {
              _paymentStatus = PaymentStatus.success;
              _checkoutRequestID = responseData['checkoutRequestID'];
              _mpesaReceiptNumber = responseData['mpesaReceiptNumber'] ?? null;
            });
            _statusCheckTimer?.cancel();
            _showSuccessDialog();
            developer.log(
              'Payment completed successfully for CheckoutRequestID: $_checkoutRequestID',
              name: 'PaymentScreen',
            );
          } else if (responseData['status'] == 'failed') {
            setState(() {
              _paymentStatus = PaymentStatus.failed;
              _errorMessage = responseData['message'] ?? 'Payment failed';
            });
            _statusCheckTimer?.cancel();
            _showErrorDialog(_errorMessage);
            developer.log(
              'Payment failed for CheckoutRequestID: ${responseData['checkoutRequestID']} - Message: $_errorMessage',
              name: 'PaymentScreen',
            );
          } else if (responseData['status'] == 'pending') {
            developer.log(
              'Transaction still pending for txn_unique: $_txnUnique',
              name: 'PaymentScreen',
            );
            // Do nothing for pending state, keep UI as is with loading indicator
            // No dialog triggered
          } else {
            // Handle unexpected status values
            setState(() {
              _paymentStatus = PaymentStatus.failed;
              _errorMessage =
                  responseData['message'] ??
                  'Unknown error occurred during status check';
            });
            _statusCheckTimer?.cancel();
            _showErrorDialog(_errorMessage);
            developer.log(
              'Unknown status received - Message: $_errorMessage',
              name: 'PaymentScreen',
            );
          }
        } catch (e) {
          developer.log(
            'Error parsing status check response: $e',
            name: 'PaymentScreen',
            error: e,
          );
          // Continue polling in case of parsing error (might be a temporary issue)
        }
      } else {
        developer.log(
          'Status check failed with status code: ${response.statusCode}, Body: ${response.body}',
          name: 'PaymentScreen',
        );
        // Continue polling in case of HTTP error (might be a temporary server issue)
      }
    } catch (e) {
      developer.log(
        'Network error during status check: $e',
        name: 'PaymentScreen',
        error: e,
      );
      // Continue polling in case of network error
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (_txnUnique == null) {
        timer.cancel();
        setState(() {
          _paymentStatus = PaymentStatus.failed;
          _errorMessage = 'No transaction unique identifier available';
        });
        _showErrorDialog(_errorMessage);
        developer.log(
          'Status check stopped: No txn_unique available',
          name: 'PaymentScreen',
        );
        return;
      }

      await _checkTransactionStatus();

      // Stop checking after 60 seconds if still pending
      if (timer.tick >= 12) {
        // 12 ticks * 5 seconds = 60 seconds
        if (_paymentStatus == PaymentStatus.pending) {
          setState(() {
            _paymentStatus = PaymentStatus.failed;
            _errorMessage = 'Payment timed out. Please try again.';
          });
          timer.cancel();
          _showErrorDialog(_errorMessage);
          developer.log(
            'Payment timed out after 60 seconds for txn_unique: $_txnUnique',
            name: 'PaymentScreen',
          );
        }
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text('Your ${widget.paymentType} payment was successful!'),
                if (_mpesaReceiptNumber != null) ...[
                  const SizedBox(height: 8),
                  Text('M-Pesa Receipt: $_mpesaReceiptNumber'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Don't navigate to home immediately, let the bloc handle it
                  // based on payment verification
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Issue'),
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
                  setState(() {
                    _paymentStatus = PaymentStatus.initial;
                    _errorMessage = '';
                    _checkoutRequestID = null;
                    _mpesaReceiptNumber = null;
                    _txnUnique = null; // Reset txn_unique for new transaction
                  });
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
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatusWidget() {
    switch (_paymentStatus) {
      case PaymentStatus.initial:
        return const SizedBox.shrink();
      case PaymentStatus.pending:
        return Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enter your M-Pesa PIN to complete the transaction',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case PaymentStatus.success:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment completed successfully!',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_mpesaReceiptNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'M-Pesa Receipt: $_mpesaReceiptNumber',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      case PaymentStatus.failed:
        return Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Payment failed. Please try again.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.account_circle, size: 100, color: Colors.orange),
              const SizedBox(height: 32),
              Text(
                '${widget.paymentType[0].toUpperCase()}${widget.paymentType.substring(1)} Payment',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KES ${widget.amount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              PhoneTextField(
                controller: _phoneController,
                readOnly: true, // Use readOnly instead of enabled
                hintText: 'Enter phone number (e.g., 0712345678)',
              ),
              const SizedBox(height: 24),
              if (_paymentStatus != PaymentStatus.initial) ...[
                _buildStatusWidget(),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed:
                    _isLoading || _paymentStatus == PaymentStatus.pending
                        ? null
                        : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Pay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
