import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/logger_service.dart';
import '../../../core/di/injection_container.dart' as di;

/// Service for handling TinyPesa M-Pesa payment integration
class TinyPesaService {
  final LoggerService _logger = di.sl<LoggerService>();

  // API endpoints
  static const String _baseUrl = 'https://seroxideentertainment.co.ke/pool';
  static const String _initiateEndpoint = '$_baseUrl/tinypesa.php';
  static const String _checkStatusEndpoint = '$_baseUrl/check_transaction.php';

  /// Initiate M-Pesa STK Push payment
  Future<TinyPesaResponse> initiatePayment({
    required String paymentType,
    required String typeId,
    required String userId,
    required String phoneNumber,
    required double amount,
    required String transactionId,
  }) async {
    try {
      _logger.i('Initiating TinyPesa payment: $transactionId');

      // Format phone number
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.replaceFirst('0', '254');
      }

      // Create payload
      final payload = {
        'payment_type': paymentType,
        'type_id': typeId,
        'user_id': userId,
        'phone_number': formattedPhone,
        'amount': amount.toString(),
        'txn_unique': transactionId,
      };

      _logger.d('TinyPesa request payload: ${jsonEncode(payload)}');

      // Send request
      final response = await http
          .post(
        Uri.parse(_initiateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment initiation timeout');
        },
      );

      _logger.d('TinyPesa response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          return TinyPesaResponse(
            success: true,
            checkoutRequestId: responseData['checkoutRequestID'],
            message:
                responseData['message'] ?? 'Payment initiated successfully',
          );
        } else {
          return TinyPesaResponse(
            success: false,
            message: responseData['message'] ?? 'Payment initiation failed',
            errorCode: responseData['errorCode'],
          );
        }
      } else {
        return TinyPesaResponse(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
          errorCode: 'HTTP_ERROR',
        );
      }
    } catch (e) {
      _logger.e('TinyPesa initiation error: $e');
      return TinyPesaResponse(
        success: false,
        message: e.toString(),
        errorCode: 'EXCEPTION',
      );
    }
  }

  /// Check payment status
  Future<PaymentStatusResponse> checkPaymentStatus(String transactionId) async {
    try {
      _logger.d('Checking payment status for: $transactionId');

      final payload = {'txn_unique': transactionId};

      final response = await http
          .post(
        Uri.parse(_checkStatusEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Status check timeout');
        },
      );

      _logger.d(
          'Status check response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return PaymentStatusResponse(
          status: _parseStatus(responseData['status']),
          checkoutRequestId: responseData['checkoutRequestID'],
          mpesaReceiptNumber: responseData['mpesaReceiptNumber'],
          message: responseData['message'],
        );
      } else {
        return PaymentStatusResponse(
          status: PaymentStatusType.error,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Status check error: $e');
      return PaymentStatusResponse(
        status: PaymentStatusType.error,
        message: e.toString(),
      );
    }
  }

  PaymentStatusType _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'completed':
        return PaymentStatusType.success;
      case 'failed':
        return PaymentStatusType.failed;
      case 'pending':
        return PaymentStatusType.pending;
      default:
        return PaymentStatusType.unknown;
    }
  }
}

/// Response from TinyPesa payment initiation
class TinyPesaResponse {
  final bool success;
  final String? checkoutRequestId;
  final String message;
  final String? errorCode;

  TinyPesaResponse({
    required this.success,
    this.checkoutRequestId,
    required this.message,
    this.errorCode,
  });
}

/// Payment status check response
class PaymentStatusResponse {
  final PaymentStatusType status;
  final String? checkoutRequestId;
  final String? mpesaReceiptNumber;
  final String? message;

  PaymentStatusResponse({
    required this.status,
    this.checkoutRequestId,
    this.mpesaReceiptNumber,
    this.message,
  });
}

/// Payment status types
enum PaymentStatusType { pending, success, failed, unknown, error }

/// Mock implementation for testing
class MockTinyPesaService extends TinyPesaService {
  final bool shouldSucceed;
  final Duration? delay;

  MockTinyPesaService({
    this.shouldSucceed = true,
    this.delay = const Duration(seconds: 3),
  });

  @override
  Future<TinyPesaResponse> initiatePayment({
    required String paymentType,
    required String typeId,
    required String userId,
    required String phoneNumber,
    required double amount,
    required String transactionId,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (shouldSucceed) {
      return TinyPesaResponse(
        success: true,
        checkoutRequestId:
            'MOCK_CHECKOUT_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Mock payment initiated',
      );
    } else {
      return TinyPesaResponse(
        success: false,
        message: 'Mock payment failed',
        errorCode: 'MOCK_ERROR',
      );
    }
  }

  @override
  Future<PaymentStatusResponse> checkPaymentStatus(String transactionId) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (shouldSucceed) {
      return PaymentStatusResponse(
        status: PaymentStatusType.success,
        checkoutRequestId: 'MOCK_CHECKOUT_123',
        mpesaReceiptNumber:
            'MOCK_RECEIPT_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Mock payment successful',
      );
    } else {
      return PaymentStatusResponse(
        status: PaymentStatusType.failed,
        message: 'Mock payment failed',
      );
    }
  }
}
