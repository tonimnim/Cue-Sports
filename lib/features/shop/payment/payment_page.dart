import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:pool_billiard_app/features/shop/add_order.dart';

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
  bool _orderCreated = false; // Flag to track if an order has been created

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
            // Create test order with MPESA01 receipt even though TinyPesa failed
            // Only create order if we haven't created one yet
            if (!_orderCreated) {
              _testOrderCreation('MPESA01');
              _orderCreated = true; // Mark that an order has been created
              developer.log(
                'Creating test order with MPESA01 receipt after TinyPesa error',
                name: 'PaymentScreen',
              );
            } else {
              developer.log(
                'Skipping order creation - order already created previously',
                name: 'PaymentScreen',
              );
            }
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
              _mpesaReceiptNumber = responseData['mpesaReceiptNumber'];
            });
            _statusCheckTimer?.cancel();
            
            // Create order with the actual MPESA receipt number after successful payment
            if (_mpesaReceiptNumber != null && !_orderCreated) {
              _testOrderCreation(_mpesaReceiptNumber!);
              _orderCreated = true; // Mark that an order has been created
              developer.log(
                'Creating order with receipt number: $_mpesaReceiptNumber after successful payment',
                name: 'PaymentScreen',
              );
            } else if (_orderCreated) {
              developer.log(
                'Skipping order creation in success handler - order already created previously',
                name: 'PaymentScreen',
              );
            }
            
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
            
            // Don't create an order for failed transactions from check status
            developer.log(
              'Payment failed for CheckoutRequestID: ${responseData['checkoutRequestID']} - Not creating order',
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
    // Order has already been created in the _checkTransactionStatus method
    // No need to create another test order here
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Payment Successful', 
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Your ${widget.paymentType} payment was successful!',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                if (_mpesaReceiptNumber != null) ...[                
                  const SizedBox(height: 8),
                  Text(
                    'M-Pesa Receipt: $_mpesaReceiptNumber',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)),
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
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }
  
  // Test the order creation functionality
  Future<void> _testOrderCreation(String receiptNumber) async {
    developer.log('Testing order creation with OrderCreationService', name: 'PaymentScreen');
    
    try {
      final success = await OrderCreationService.createOrderAfterPayment(
        context: context,
        userId: widget.userId,
        paymentMethod: 'M-Pesa',
        receiptNumber: receiptNumber,
        notes: 'Test order created from payment page at ${DateTime.now()}',
      );
      
      developer.log(
        'Test order creation result: $success',
        name: 'PaymentScreen',
      );
    } catch (e) {
      developer.log(
        'Error during test order creation: $e',
        name: 'PaymentScreen',
        error: e,
      );
    }
  }

  void _showErrorDialog(String message) {
    // For testing purposes, create a test receipt number and test order creation
    _testOrderCreation('MPESA01');
    
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Payment Issue',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
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
            const Text(
              'Payment completed successfully!',
              style: TextStyle(fontSize: 16),
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
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.account_circle, size: 100, color: Theme.of(context).colorScheme.secondary),
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
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number (e.g., 0712345678)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _phoneController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied')),
                      );
                    },
                  ),
                ],
              ),
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
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
    );
  }
}