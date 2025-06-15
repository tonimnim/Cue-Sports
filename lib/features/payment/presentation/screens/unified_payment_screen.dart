import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/payment_status_indicator.dart';

/// Unified payment screen for all payment types
class UnifiedPaymentScreen extends StatefulWidget {
  final PaymentType paymentType;
  final String typeId;
  final String userId;
  final double amount;
  final String? prefillPhoneNumber;
  final Map<String, dynamic>? metadata;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const UnifiedPaymentScreen({
    Key? key,
    required this.paymentType,
    required this.typeId,
    required this.userId,
    required this.amount,
    this.prefillPhoneNumber,
    this.metadata,
    this.onSuccess,
    this.onFailure,
  }) : super(key: key);

  @override
  State<UnifiedPaymentScreen> createState() => _UnifiedPaymentScreenState();
}

class _UnifiedPaymentScreenState extends State<UnifiedPaymentScreen>
    with WidgetsBindingObserver {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final LoggerService _logger = di.sl<LoggerService>();
  final _formKey = GlobalKey<FormState>();

  late final PaymentBloc _paymentBloc;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize payment bloc
    _paymentBloc = context.read<PaymentBloc>();

    // Set prefill phone number
    if (widget.prefillPhoneNumber?.isNotEmpty ?? false) {
      _phoneController.text = widget.prefillPhoneNumber!;
    }

    _logger
        .i('UnifiedPaymentScreen initialized for ${widget.paymentType.name}');
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes during payment
    if (state == AppLifecycleState.paused) {
      _logger.i('App paused during payment');
    } else if (state == AppLifecycleState.resumed) {
      _logger.i('App resumed during payment');
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }

    // Remove spaces and validate format
    final cleaned = value.replaceAll(' ', '');

    // Check if it's a valid Kenyan number
    if (!RegExp(r'^(0|254)?[17]\d{8}$').hasMatch(cleaned)) {
      return 'Enter a valid Kenyan phone number';
    }

    return null;
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Convert to international format
    if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254')) {
      return cleaned;
    } else if (cleaned.length == 9) {
      return '254$cleaned';
    }

    return cleaned;
  }

  Future<void> _initiatePayment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final phoneNumber = _formatPhoneNumber(_phoneController.text);

    _paymentBloc.add(InitiatePaymentEvent(
      paymentType: widget.paymentType,
      typeId: widget.typeId,
      userId: widget.userId,
      amount: widget.amount,
      phoneNumber: phoneNumber,
      metadata: widget.metadata,
    ));
  }

  void _handlePaymentSuccess() {
    if (_isDisposed) return;

    _logger.i('Payment successful for ${widget.paymentType.name}');

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Payment Successful',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSuccessMessage(),
              style: const TextStyle(color: Colors.white70),
            ),
            if (_paymentBloc.state.currentPayment?.mpesaReceiptNumber !=
                null) ...[
              const SizedBox(height: 12),
              Text(
                'Receipt: ${_paymentBloc.state.currentPayment!.mpesaReceiptNumber}',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return success
              widget.onSuccess?.call();
            },
            child: Text(
              'Continue',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentFailure(String error) {
    if (_isDisposed) return;

    _logger.e('Payment failed: $error');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Payment Failed',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          error,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_paymentBloc.state.currentPayment != null) {
                _paymentBloc.add(RetryPaymentEvent(
                  payment: _paymentBloc.state.currentPayment!,
                ));
              }
            },
            child: Text(
              'Retry',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessMessage() {
    switch (widget.paymentType) {
      case PaymentType.registration:
        return 'Your registration payment has been processed successfully. Welcome to the community!';
      case PaymentType.tournament:
        return 'You have been successfully registered for the tournament. Good luck!';
      case PaymentType.merchandise:
        return 'Your order has been placed successfully. Thank you for your purchase!';
    }
  }

  String _getPaymentDescription() {
    switch (widget.paymentType) {
      case PaymentType.registration:
        return 'Player Registration Fee';
      case PaymentType.tournament:
        return 'Tournament Entry Fee';
      case PaymentType.merchandise:
        return 'Shop Purchase';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during payment
        if (_paymentBloc.state.isPaymentInProgress) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text(
                'Cancel Payment?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to cancel the ongoing payment?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text('No', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    _paymentBloc.add(const CancelPaymentEvent());
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child:
                      Text('Yes', style: TextStyle(color: AppTheme.errorColor)),
                ),
              ],
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Payment',
            style: AppTheme.h2Style,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (!_paymentBloc.state.isPaymentInProgress) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: BlocConsumer<PaymentBloc, PaymentState>(
          bloc: _paymentBloc,
          listener: (context, state) {
            if (state.status == PaymentStatus.success) {
              _handlePaymentSuccess();
            } else if (state.status == PaymentStatus.failed &&
                state.errorMessage != null) {
              _handlePaymentFailure(state.errorMessage!);
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Payment details card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentDescription(),
                            style: AppTheme.h3Style,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'KSh ${widget.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone number input
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'M-Pesa Phone Number',
                            style: AppTheme.bodyLargeStyle,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            enabled: !state.isPaymentInProgress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '07XX XXX XXX',
                              prefixIcon: const Icon(Icons.phone,
                                  color: Colors.white54),
                              filled: true,
                              fillColor: AppTheme.cardColor,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                            validator: _validatePhoneNumber,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Payment status indicator
                    if (state.isPaymentInProgress) ...[
                      PaymentStatusIndicator(
                        status: state.status,
                        message: state.statusMessage,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action buttons
                    if (!state.isPaymentInProgress) ...[
                      ElevatedButton(
                        onPressed: state.isLoading ? null : _initiatePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Text(
                                'Pay Now',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () =>
                            _paymentBloc.add(const CancelPaymentEvent()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Cancel Payment',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Security notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.infoColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security,
                              color: AppTheme.infoColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your payment is secured by M-Pesa',
                              style: TextStyle(
                                color: AppTheme.infoColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
