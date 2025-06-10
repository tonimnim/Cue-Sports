import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
// Removed import for deleted add_order.dart - functionality moved to BLoC
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { initial, pending, success, failed }

class PaymentScreen extends StatefulWidget {
  final String paymentType; // registration, tournament, or merchandise
  final String typeId; // club_id, tournament_id, or product_id
  final String userId;
  final double amount;
  final String? prefillPhoneNumber; // Optional phone number to prefill

  const PaymentScreen({
    super.key,
    required this.paymentType,
    required this.typeId,
    required this.userId,
    required this.amount,
    this.prefillPhoneNumber,
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
    // Set phone number from widget if provided, otherwise use a default for testing
    if (widget.prefillPhoneNumber != null &&
        widget.prefillPhoneNumber!.isNotEmpty) {
      _phoneController.text = widget.prefillPhoneNumber!;
    } else {
      // Default for testing - should be removed in production
      _phoneController.text = "0712345678";
    }

    // Debug log to verify userId received by the PaymentScreen
    print('PaymentScreen initialized with userId: ${widget.userId}');
    print('PaymentScreen initialized with typeId: ${widget.typeId}');
    print('PaymentScreen initialized with paymentType: ${widget.paymentType}');
    print(
        'PaymentScreen initialized with phone number: ${_phoneController.text}');
    print(
        'PaymentScreen prefill phone number value: ${widget.prefillPhoneNumber}');
  }

  /// Retrieve user ID from Firestore using phone number
  Future<String?> _getUserIdFromPhoneNumber(String phoneNumber) async {
    try {
      print('Original phone number format: $phoneNumber');

      // Try different formats of the phone number to increase chances of finding a match
      List<String> phoneFormats = [];

      // Original format
      phoneFormats.add(phoneNumber);

      // With country code
      if (phoneNumber.startsWith('0')) {
        phoneFormats.add(phoneNumber.replaceFirst('0', '254'));
      }

      // Without country code
      if (phoneNumber.startsWith('254')) {
        phoneFormats.add(phoneNumber.replaceFirst('254', '0'));
      }

      print('Trying phone number formats: $phoneFormats');

      // Try each format
      for (String format in phoneFormats) {
        print('Searching for user with phone number: $format');

        // Query Firestore for a user with this phone number
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: format)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userId = querySnapshot.docs.first.id;
          print('Found user ID from phone number $format: $userId');
          return userId;
        }
      }

      // Try a broader query approach
      print(
          'No exact match found, checking if any user contains this phone number');

      // Try with multiple possible collection names
      List<String> possibleCollections = [
        'users',
        'Users',
        'user',
        'User',
        'Profiles',
        'profiles'
      ];

      for (String collectionName in possibleCollections) {
        print('Trying collection: $collectionName');

        try {
          final queryResult =
              await FirebaseFirestore.instance.collection(collectionName).get();

          print(
              'Collection $collectionName has ${queryResult.docs.length} documents');

          if (queryResult.docs.isNotEmpty) {
            // We found a collection with documents, use this one
            final allUsers = queryResult;
            print(
                'Using collection: $collectionName with ${allUsers.docs.length} users');

            // Process these users
            for (var doc in allUsers.docs) {
              final userData = doc.data();
              print('User data fields: ${userData.keys.toList()}');

              // Check if there's a phone number field with various possible names
              List<String> phoneFields = [
                'phoneNumber',
                'phone',
                'phone_number',
                'mobile',
                'contact'
              ];

              for (String field in phoneFields) {
                if (userData.containsKey(field)) {
                  final userPhone = userData[field]?.toString() ?? '';
                  print('Found phone field "$field" with value: $userPhone');

                  // Compare phone numbers
                  for (String format in phoneFormats) {
                    if (userPhone == format ||
                        (userPhone.isNotEmpty &&
                            format.isNotEmpty &&
                            userPhone.endsWith(
                                format.substring(max(0, format.length - 9))))) {
                      print('Found matching user ID: ${doc.id}');
                      return doc.id;
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Error checking collection $collectionName: $e');
        }
      }

      print('No user found in any collection with matching phone number');

      print('No user found with any phone number format');
      return null;
    } catch (e) {
      print('Error retrieving user ID from phone number: $e');
      return null;
    }
  }

  Future<void> _processPayment() async {
    print('Starting payment process...');
    print('Phone number from controller: ${_phoneController.text}');
    print('User ID from widget: ${widget.userId}');

    if (_phoneController.text.isEmpty) {
      print('Payment aborted: Empty phone number');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get phone number
    String phoneNumber = _phoneController.text.trim();

    // Get the user ID - either use the one provided or look it up by phone number
    String userId = widget.userId;

    // If userId is empty, try to retrieve it from Firestore using phone number
    if (userId.isEmpty) {
      print('User ID is empty, attempting to retrieve from phone number');
      final retrievedUserId = await _getUserIdFromPhoneNumber(phoneNumber);

      if (retrievedUserId != null && retrievedUserId.isNotEmpty) {
        userId = retrievedUserId;
        print('Successfully retrieved userId from phone number: $userId');
      } else {
        // Continue with guest_user instead of showing error
        userId = 'guest_user';
        print('Could not find user ID, using guest_user instead');
        developer.log(
          'Using guest_user as fallback since userId could not be retrieved',
          name: 'PaymentScreen',
        );
      }
    }

    // Generate txn_unique with the retrieved or provided user ID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _txnUnique = "${userId}_$timestamp";
    developer.log(
      'Generated txn_unique: $_txnUnique for userId: $userId at timestamp: $timestamp',
      name: 'PaymentScreen',
    );

    setState(() {
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

      // Create JSON payload with txn_unique - use the retrieved userId instead of widget.userId
      final Map<String, dynamic> payload = {
        'payment_type': widget.paymentType,
        'type_id': widget.typeId,
        'user_id': userId, // Use the retrieved or provided userId here
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
              _createOrder('MPESA01');
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

          if (responseData['status'] == 'completed' ||
              responseData['status'] == 'success') {
            setState(() {
              _paymentStatus = PaymentStatus.success;
              _checkoutRequestID = responseData['checkoutRequestID'];

              // Use actual receipt number from the response, don't default to MPESA01 here
              _mpesaReceiptNumber = responseData['mpesaReceiptNumber'];
            });
            _statusCheckTimer?.cancel();

            // Create order with the actual receipt number after successful payment
            if (!_orderCreated && _mpesaReceiptNumber != null) {
              bool orderSuccess = await _createOrder(_mpesaReceiptNumber!);
              _orderCreated = true; // Mark that an order has been created
              developer.log(
                'Creating order with actual receipt number: $_mpesaReceiptNumber after successful payment. Success: $orderSuccess',
                name: 'PaymentScreen',
              );

              // If order was created successfully, show success dialog to return to previous screen
              if (orderSuccess) {
                _showSuccessDialog();
              }
            } else if (!_orderCreated) {
              // If no receipt number, log but don't create order here
              developer.log(
                'No receipt number available from successful transaction',
                name: 'PaymentScreen',
              );
              // Show success dialog anyway
              _showSuccessDialog();
            } else {
              developer.log(
                'Skipping order creation in success handler - order already created previously',
                name: 'PaymentScreen',
              );
              // Show success dialog anyway
              _showSuccessDialog();
            }
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
              _errorMessage = responseData['message'] ??
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

  // Create an order with the provided receipt number (test or actual)
  Future<bool> _createOrder(String receiptNumber) async {
    try {
      print('Creating order with receipt number: $receiptNumber');

      // Get the user ID and phone number
      String userId = widget.userId;
      String phoneNumber = _phoneController.text.trim();

      // Get cart items from the typeId which is the cartId
      List<Map<String, dynamic>> cartItems = [];
      try {
        // Retrieve cart items from Firestore
        final cartDoc = await FirebaseFirestore.instance
            .collection('carts')
            .doc(widget.typeId)
            .get();

        if (cartDoc.exists && cartDoc.data() != null) {
          final data = cartDoc.data()!;
          if (data.containsKey('items') && data['items'] is List) {
            cartItems = List<Map<String, dynamic>>.from(
                (data['items'] as List).map((item) => {
                      'product_id': item['productId'] ?? '',
                      'quantity': (item['quantity'] is int)
                          ? item['quantity']
                          : int.tryParse(item['quantity'].toString()) ?? 1,
                      'price': (item['price'] is double)
                          ? item['price']
                          : double.tryParse(item['price'].toString()) ?? 0.0,
                      'product_name': item['name'] ?? 'Unknown Product',
                    }));
          }
        }

        developer.log(
          'Retrieved ${cartItems.length} cart items for order',
          name: 'PaymentScreen',
        );
      } catch (e) {
        developer.log(
          'Error retrieving cart items: $e',
          name: 'PaymentScreen',
          error: e,
        );
      }

      // Generate a unique order ID if not present
      String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      // Create order payload for API
      final Map<String, dynamic> orderPayload = {
        'user_id': userId,
        'phone_number': phoneNumber,
        'amount': widget.amount.toString(),
        'payment_type': widget.paymentType,
        'type_id': widget.typeId,
        'mpesa_receipt': receiptNumber,
        'transaction_date': DateTime.now().toIso8601String(),
        'txn_unique': _txnUnique,
        'items': cartItems,
        'order_id': orderId,
      };

      // Create a separate order document for Firestore with proper type handling
      // Ensure it includes all fields from the Order model plus additional required fields
      final Map<String, dynamic> firestoreOrder = {
        'user_id': userId,
        'phone_number': phoneNumber,
        'amount': double.tryParse(widget.amount.toString()) ?? 0.0,
        'payment_type': widget.paymentType,
        'type_id': widget.typeId,
        'mpesa_receipt': receiptNumber,
        'receiptNumber': receiptNumber, // Add this to match Order model
        'transaction_date': Timestamp.now(),
        'txn_unique': _txnUnique,
        'items': cartItems,
        'orderNumber': orderId, // Add this to match Order model
        'total': double.tryParse(widget.amount.toString()) ??
            0.0, // Add this to match Order model
        'status': 'pending', // Add default status to match Order model
        'paymentMethod': widget.paymentType, // Add this to match Order model
        'shippingAddress': phoneNumber, // Use phone as fallback if no address
        'cartItemIds':
            cartItems.map((item) => item['product_id'] ?? '').toList(),
        'createdAt': Timestamp.now(), // Add this to match Order model
        'updatedAt': Timestamp.now(), // Add this to match Order model
      };

      // Log the order being created
      developer.log(
        'Creating order with payload: ${jsonEncode(orderPayload)}',
        name: 'PaymentScreen',
      );

      // First, check if an order with this transaction ID already exists
      try {
        final existingOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('txn_unique', isEqualTo: _txnUnique)
            .get();

        if (existingOrders.docs.isNotEmpty) {
          developer.log(
            'Order with txn_unique $_txnUnique already exists. Skipping creation.',
            name: 'PaymentScreen',
          );
          return true; // Order already exists, consider it successful
        }

        // Set a document ID based on orderId or generate a new one
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .set(firestoreOrder);

        print('Order created successfully: $orderId');

        developer.log(
          'Order created successfully - ID: $orderId',
          name: 'PaymentScreen',
        );
      } catch (e) {
        developer.log(
          'Error saving order to Firestore: $e',
          name: 'PaymentScreen',
          error: e,
        );
        // Continue anyway to try the backend API
      }

      // Now also send order creation request to backend API
      final response = await http.post(
        Uri.parse('https://seroxideentertainment.co.ke/pool/create_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderPayload),
      );

      // Log the response
      developer.log(
        'Order creation response: Status=${response.statusCode}, Body=${response.body}',
        name: 'PaymentScreen',
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'success') {
            developer.log(
              'Order created successfully with ID: ${responseData['order_id']}',
              name: 'PaymentScreen',
            );

            // Set receipt number in state for display
            setState(() {
              _mpesaReceiptNumber = receiptNumber;
            });

            // Since we've already saved to Firestore, we can return true even if the API fails
            return true; // Order created successfully
          } else {
            developer.log(
              'Order creation API call failed: ${responseData['message']}',
              name: 'PaymentScreen',
            );
            // Return true anyway since we already saved to Firestore
            return true;
          }
        } catch (e) {
          developer.log(
            'Error parsing order creation response: $e',
            name: 'PaymentScreen',
            error: e,
          );
          // Return true anyway since we already saved to Firestore
          return true;
        }
      } else {
        developer.log(
          'Order creation failed with status code: ${response.statusCode}',
          name: 'PaymentScreen',
        );
        // Return true anyway since we already saved to Firestore
        return true;
      }
    } catch (e) {
      developer.log(
        'Error creating order: $e',
        name: 'PaymentScreen',
        error: e,
      );

      // Try to save a minimal order to Firestore even on error
      try {
        // Create a fallback order ID if one wasn't set
        String fallbackOrderId =
            'order_${DateTime.now().millisecondsSinceEpoch}';

        // Get cart items from the typeId which is the cartId
        List<Map<String, dynamic>> fallbackCartItems = [];
        try {
          // Retrieve cart items from Firestore
          final cartDoc = await FirebaseFirestore.instance
              .collection('carts')
              .doc(widget.typeId)
              .get();

          if (cartDoc.exists && cartDoc.data() != null) {
            final data = cartDoc.data()!;
            if (data.containsKey('items') && data['items'] is List) {
              fallbackCartItems = List<Map<String, dynamic>>.from(
                  (data['items'] as List).map((item) => {
                        'product_id': item['productId'] ?? '',
                        'quantity': (item['quantity'] is int)
                            ? item['quantity']
                            : int.tryParse(item['quantity'].toString()) ?? 1,
                        'price': (item['price'] is double)
                            ? item['price']
                            : double.tryParse(item['price'].toString()) ?? 0.0,
                        'product_name': item['name'] ?? 'Unknown Product',
                        'id': item['id'] ?? '',
                        'name': item['name'] ?? 'Unknown Product',
                        'imageUrl': item['imageUrl'] ?? ''
                      }));
            }
          }

          developer.log(
            'Retrieved ${fallbackCartItems.length} cart items for fallback order',
            name: 'PaymentScreen',
          );
        } catch (e) {
          developer.log(
            'Error retrieving cart items for fallback order: $e',
            name: 'PaymentScreen',
            error: e,
          );
        }

        // Create a complete order that matches the Order model plus additional required fields
        Map<String, dynamic> fallbackOrder = {
          'user_id': widget.userId.isEmpty ? 'guest_user' : widget.userId,
          'phone_number': _phoneController.text.trim(),
          'amount': double.tryParse(widget.amount.toString()) ?? 0.0,
          'mpesa_receipt': receiptNumber,
          'receiptNumber': receiptNumber, // Add this to match Order model
          'transaction_date': Timestamp.now(),
          'items': fallbackCartItems,
          'txn_unique': _txnUnique, // Add transaction ID to prevent duplicates
          'payment_type': widget.paymentType,
          'type_id': widget.typeId,
          'orderNumber': fallbackOrderId, // Add this to match Order model
          'total': double.tryParse(widget.amount.toString()) ??
              0.0, // Add this to match Order model
          'status': 'pending', // Add default status to match Order model
          'paymentMethod': widget.paymentType, // Add this to match Order model
          'shippingAddress': _phoneController.text
              .trim(), // Use phone as fallback if no address
          'cartItemIds':
              fallbackCartItems.map((item) => item['id'] ?? '').toList(),
          'createdAt': Timestamp.now(), // Add this to match Order model
          'updatedAt': Timestamp.now(), // Add this to match Order model
        };

        // Check if an order with this transaction ID already exists
        final existingOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('txn_unique', isEqualTo: _txnUnique)
            .get();

        if (existingOrders.docs.isNotEmpty) {
          developer.log(
            'Fallback order with txn_unique $_txnUnique already exists. Skipping creation.',
            name: 'PaymentScreen',
          );
          return true; // Order already exists, consider it successful
        }

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(fallbackOrderId)
            .set(fallbackOrder);

        // Print to both console and developer log for visibility
        print('===== FALLBACK ORDER CREATED =====');
        print('Order ID: $fallbackOrderId');
        print(
            'User ID: ${widget.userId.isEmpty ? "guest_user" : widget.userId}');
        print('Phone: ${_phoneController.text.trim()}');
        print('Receipt: $receiptNumber');
        print('Transaction ID: $_txnUnique');
        print('Cart Items: ${fallbackCartItems.length}');
        print('Total Amount: ${widget.amount}');
        print('==================================');

        developer.log(
          'FALLBACK ORDER CREATED - ID: $fallbackOrderId | User: ${widget.userId} | Receipt: $receiptNumber | TXN: $_txnUnique | Items: ${fallbackCartItems.length}',
          name: 'PaymentScreen',
        );

        return true; // We created at least a minimal order
      } catch (innerError) {
        developer.log(
          'Failed to create even fallback order: $innerError',
          name: 'PaymentScreen',
          error: innerError,
        );
        return false;
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    bool orderSuccess = false;

    // Order should already be created by this point
    // If not, ensure we create it with the receipt number
    if (!_orderCreated && _mpesaReceiptNumber != null) {
      orderSuccess = await _createOrder(_mpesaReceiptNumber!);
      _orderCreated = true;
    } else if (_orderCreated) {
      // Order was already created successfully
      orderSuccess = true;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog dismissal by tapping outside
      builder: (context) => AlertDialog(
        title: const Text(
          'Payment Successful',
          style: TextStyle(color: AppTheme.primaryColor),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: AppTheme.primaryColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment has been received successfully!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            if (_mpesaReceiptNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'M-Pesa Receipt: $_mpesaReceiptNumber',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
            if (orderSuccess) ...[
              const SizedBox(height: 8),
              Text(
                'Order has been created successfully!',
                style: TextStyle(color: AppTheme.successColor ?? Colors.green),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Order creation pending. Check orders page later.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Return success result to trigger cart clearing
              Navigator.of(context).pop(orderSuccess);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Test the order creation functionality - use only for development/testing
  Future<void> _testOrderCreation(String receiptNumber) async {
    // REMOVED: This method was causing duplicate orders
    // We now use _createOrder directly which is more reliable
    developer.log(
        'Test order creation called but skipped to prevent duplicates',
        name: 'PaymentScreen');
    return;
  }

  Future<void> _showErrorDialog(String message) async {
    bool orderSuccess = false;

    // Create test order with MPESA01 only if this is from the initial payment failure
    // and we haven't created an order yet
    if (!_orderCreated && _paymentStatus != PaymentStatus.pending) {
      // Create test order with MPESA01 only if this is from the initial payment failure
      // and we haven't created an order yet
      try {
        print('Checking for existing orders with transaction ID: $_txnUnique');
        final existingOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('txn_unique', isEqualTo: _txnUnique)
            .get();

        if (existingOrders.docs.isEmpty) {
          print(
              'No existing order found. Creating test order with receipt MPESA01...');
          orderSuccess = await _createOrder('MPESA01');
          _orderCreated = true;
          print('Test order creation result: $orderSuccess');
          developer.log(
              'Creating test order in error dialog with MPESA01. Success: $orderSuccess',
              name: 'PaymentScreen');
        } else {
          print('Found existing order with transaction ID: $_txnUnique');
          for (var doc in existingOrders.docs) {
            print('Existing order ID: ${doc.id}');
          }
          developer.log(
              'Test order already exists with txn_unique $_txnUnique. Skipping creation.',
              name: 'PaymentScreen');
          _orderCreated = true;
          orderSuccess = true;
        }
      } catch (e) {
        developer.log(
          'Error checking for existing orders: $e',
          name: 'PaymentScreen',
          error: e,
        );
        print(
            'Error while checking for existing orders. Creating test order anyway.');
        orderSuccess = await _createOrder('MPESA01');
        _orderCreated = true;
      }
    }

    // Simplify the error message if it's a network error
    if (message.contains('network') ||
        message.contains('SocketException') ||
        message.contains('timeout') ||
        message.contains('Connection')) {
      message =
          'A network error occurred. Please check your internet connection.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Issue',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: AppTheme.errorColor, size: 64),
            const SizedBox(height: 16),
            Text(message,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            if (orderSuccess) ...[
              const SizedBox(height: 16),
              Text(
                'However, a test order has been created with receipt number MPESA01.',
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can check your orders page.',
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // If we created a test order successfully, return true to clear the cart
              if (orderSuccess) {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(false);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Close'),
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter your M-Pesa PIN to complete the transaction',
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.onPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case PaymentStatus.success:
        return Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment completed successfully!',
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.onPrimary),
              textAlign: TextAlign.center,
            ),
            if (_mpesaReceiptNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'M-Pesa Receipt: $_mpesaReceiptNumber',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      case PaymentStatus.failed:
        // Return an empty widget for failed state - error will only show in dialog
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure status bar uses the app's background color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:
          AppTheme.backgroundColor, // Dark green background from AppTheme
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppTheme
            .backgroundColor, // Use the app's dark green background color
        elevation: 0,
      ),
      backgroundColor:
          AppTheme.backgroundColor, // Use the app's dark green background color
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_circle,
                    size: 80, color: AppTheme.backgroundColor),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${widget.paymentType[0].toUpperCase()}${widget.paymentType.substring(1)} Payment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(Edit if needed)',
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16), // Add horizontal margins
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryColor, // Use primary color background
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autocorrect: false,
                          // fillColor: AppTheme.primaryColor,
                          enableSuggestions: false,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter phone number (e.g., 0712345678)',
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _phoneController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Phone number copied'),
                              backgroundColor: AppTheme.infoColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_paymentStatus != PaymentStatus.initial) ...[
              _buildStatusWidget(),
              const SizedBox(height: 24),
            ],
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16), // Add horizontal margins
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _paymentStatus == PaymentStatus.pending
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.secondaryColor, // Use yellowish secondary color
                  foregroundColor:
                      Colors.black, // Black text on gold background
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white, // Use fixed white color for spinner
                          ),
                        ),
                      )
                    : const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Black text on gold background
                        ),
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
