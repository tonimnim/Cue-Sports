import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import '../direct_implementation/tournament_service.dart';

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
  final TournamentService _tournamentService = TournamentService(); // Service for tournament operations
  PaymentStatus _paymentStatus = PaymentStatus.initial;
  bool _isLoading = false;
  Timer? _statusCheckTimer;
  String? _checkoutRequestID;
  String _errorMessage = '';
  String? _mpesaReceiptNumber;
  String? _txnUnique; // Store the transaction unique identifier
  bool _registrationCompleted = false; // Flag to track if tournament registration is completed

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

            // SCENARIO 2: Register user when initial payment API fails
            if (widget.paymentType == 'tournament') {
              developer.log(
                'TOURNAMENT-PAYMENT: Payment initialization failed but registering user for tournament anyway',
                name: 'PaymentScreen',
              );

              try {
                // Register the user for the tournament directly
                final success = await _tournamentService.registerUserForTournament(
                  widget.typeId, // tournament_id
                  widget.userId, // user_id
                );

                if (success) {
                  developer.log(
                    'TOURNAMENT-PAYMENT: Successfully registered user ${widget.userId} for tournament ${widget.typeId}',
                    name: 'PaymentScreen',
                  );

                  // Mark registration as completed
                  _registrationCompleted = true;

                  // Show a special success dialog indicating the user is now registered
                  _showSuccessDialog(isAlreadyRegistered: true);
                  return; // Return early after showing dialog
                } else {
                  developer.log(
                    'TOURNAMENT-PAYMENT: Failed to register user ${widget.userId} for tournament ${widget.typeId}',
                    name: 'PaymentScreen',
                  );
                }
              } catch (e) {
                developer.log(
                  'TOURNAMENT-PAYMENT: Error registering user for tournament: $e',
                  name: 'PaymentScreen',
                );
              }
            }

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

      developer.log(
        'Checking transaction status for txn_unique: $_txnUnique',
        name: 'PaymentScreen',
      );

      // Send request to check transaction status
      final response = await http.post(
        Uri.parse('https://seroxideentertainment.co.ke/pool/check_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      developer.log(
        'Status check response: Status=${response.statusCode}, Body=${response.body}',
        name: 'PaymentScreen',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          setState(() {
            _paymentStatus = PaymentStatus.success;
            _checkoutRequestID = responseData['checkoutRequestID'];
            _mpesaReceiptNumber = responseData['mpesaReceiptNumber'] ?? null;
          });
          _statusCheckTimer?.cancel();

          // SCENARIO 1: Register user for tournament after successful payment
          if (widget.paymentType == 'tournament' && !_registrationCompleted) {
            developer.log(
              'TOURNAMENT-PAYMENT: Registering user ${widget.userId} for tournament ${widget.typeId} after successful payment',
              name: 'PaymentScreen',
            );

            try {
              final success = await _tournamentService.registerUserForTournament(
                widget.typeId, // tournament_id
                widget.userId, // user_id
              );

              if (success) {
                _registrationCompleted = true;
                developer.log(
                  'TOURNAMENT-PAYMENT: Successfully registered user after payment',
                  name: 'PaymentScreen',
                );
              } else {
                developer.log(
                  'TOURNAMENT-PAYMENT: Failed to register user after payment',
                  name: 'PaymentScreen',
                );
              }
            } catch (e) {
              developer.log(
                'TOURNAMENT-PAYMENT: Error registering user after payment: $e',
                name: 'PaymentScreen',
                error: e,
              );
            }
          }

          // Show success dialog
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
        } else if (responseData['status'] == 'pending') {
          developer.log(
            'Transaction still pending for txn_unique: $_txnUnique',
            name: 'PaymentScreen',
          );
          // Continue checking status in next interval
        } else {
          // Unknown status
          setState(() {
            _paymentStatus = PaymentStatus.failed;
            _errorMessage = 'Unknown payment status received';
          });
          _statusCheckTimer?.cancel();
          _showErrorDialog(_errorMessage);
          developer.log(
            'Unknown status received - Message: $_errorMessage',
            name: 'PaymentScreen',
          );
        }
      } else {
        // HTTP error during status check
        _showErrorDialog('Failed to check payment status. Please try again.');
      }
    } catch (e) {
      developer.log(
        'Error checking transaction status: $e',
        name: 'PaymentScreen',
        error: e,
      );
    }
  }

  void _startStatusCheck() {
    // First cancel any existing timer
    _statusCheckTimer?.cancel();

    if (_txnUnique == null) {
      setState(() {
        _paymentStatus = PaymentStatus.failed;
        _errorMessage = 'No transaction unique identifier available';
      });
      _showErrorDialog(_errorMessage);
      return;
    }

    // Check status immediately
    _checkTransactionStatus();

    // Then set up periodic checks
    // Check status every 5 seconds for up to 60 seconds (12 attempts)
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Track the number of checks
      if (timer.tick >= 12) {
        // After 60 seconds, stop checking and show timeout message
        timer.cancel();
        if (_paymentStatus == PaymentStatus.pending) {
          setState(() {
            _paymentStatus = PaymentStatus.failed;
            _errorMessage = 'Payment timed out. Please try again.';
          });
          _showErrorDialog(_errorMessage);
          developer.log(
            'Payment timed out after 60 seconds for txn_unique: $_txnUnique',
            name: 'PaymentScreen',
          );
        }
        return;
      }

      // Check status
      _checkTransactionStatus();
    });
  }

  void _showSuccessDialog({bool isAlreadyRegistered = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Success',
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              isAlreadyRegistered
                  ? 'You\'re now registered for the tournament!'
                  : 'Your ${widget.paymentType} payment was successful!',
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (widget.paymentType == 'tournament') 
              const Text(
                'You are now registered for the tournament.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            if (widget.paymentType == 'tournament') 
              const SizedBox(height: 8),
            if (_mpesaReceiptNumber != null && !isAlreadyRegistered) 
              const SizedBox(height: 8),
            if (_mpesaReceiptNumber != null && !isAlreadyRegistered) 
              Text(
                'M-Pesa Receipt: $_mpesaReceiptNumber',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(true); // Return success to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // We don't need a helper method anymore as we only register in two specific scenarios

  void _showErrorDialog(String message) {
    // Do not register for tournaments here - we only want to register in two specific scenarios
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Payment Issue',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset payment status and try again
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
      case PaymentStatus.pending:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Waiting for payment...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        );
      case PaymentStatus.success:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 8),
            const Text('Payment successful!',
                style: TextStyle(color: Colors.green)),
            if (_mpesaReceiptNumber != null)
              const SizedBox(height: 8),
            if (_mpesaReceiptNumber != null)
              Text(
                'M-Pesa Receipt: $_mpesaReceiptNumber',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        );
      case PaymentStatus.failed:
        return Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Payment failed. Please try again.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case PaymentStatus.initial:
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          '${widget.paymentType[0].toUpperCase()}${widget.paymentType.substring(1)} Payment',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const SizedBox(height: 32),
            Icon(Icons.account_circle, size: 100, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 32),
            Text(
              '${widget.paymentType[0].toUpperCase()}${widget.paymentType.substring(1)} Payment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KES ${widget.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number (e.g., 0712345678)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
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
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ElevatedButton(
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
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
