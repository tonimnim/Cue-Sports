import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';

/// Payment state with proper null safety
class PaymentState extends Equatable {
  final PaymentStatus status;
  final Payment? currentPayment;
  final List<Payment> paymentHistory;
  final String? errorMessage;
  final bool isLoading;
  final bool isPolling;
  final int pollAttempts;
  final DateTime? lastPollTime;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.currentPayment,
    this.paymentHistory = const [],
    this.errorMessage,
    this.isLoading = false,
    this.isPolling = false,
    this.pollAttempts = 0,
    this.lastPollTime,
  });

  /// Factory constructor for initial state
  factory PaymentState.initial() => const PaymentState();

  /// Create a copy with updated fields
  PaymentState copyWith({
    PaymentStatus? status,
    Payment? currentPayment,
    List<Payment>? paymentHistory,
    String? errorMessage,
    bool? isLoading,
    bool? isPolling,
    int? pollAttempts,
    DateTime? lastPollTime,
    bool clearError = false,
  }) {
    return PaymentState(
      status: status ?? this.status,
      currentPayment: currentPayment ?? this.currentPayment,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isPolling: isPolling ?? this.isPolling,
      pollAttempts: pollAttempts ?? this.pollAttempts,
      lastPollTime: lastPollTime ?? this.lastPollTime,
    );
  }

  /// Check if payment is in progress
  bool get isPaymentInProgress {
    return status == PaymentStatus.pending ||
        status == PaymentStatus.processing ||
        isPolling;
  }

  /// Check if can retry payment
  bool get canRetry {
    return status == PaymentStatus.failed || status == PaymentStatus.timeout;
  }

  /// Get status message for UI
  String get statusMessage {
    switch (status) {
      case PaymentStatus.initial:
        return 'Ready to process payment';
      case PaymentStatus.pending:
        return 'Waiting for M-Pesa prompt...';
      case PaymentStatus.processing:
        return 'Processing payment...';
      case PaymentStatus.success:
        return 'Payment successful!';
      case PaymentStatus.failed:
        return errorMessage ?? 'Payment failed';
      case PaymentStatus.cancelled:
        return 'Payment cancelled';
      case PaymentStatus.timeout:
        return 'Payment timed out';
    }
  }

  @override
  List<Object?> get props => [
        status,
        currentPayment,
        paymentHistory,
        errorMessage,
        isLoading,
        isPolling,
        pollAttempts,
        lastPollTime,
      ];
}

/// Initial payment state
class PaymentInitial extends PaymentState {}

/// Loading state during payment operations
class PaymentLoading extends PaymentState {}

/// State when payment is initiated successfully
class PaymentInitiated extends PaymentState {
  final Payment payment;

  const PaymentInitiated(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment is pending confirmation
class PaymentPending extends PaymentState {
  final Payment payment;

  const PaymentPending(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment is completed successfully
class PaymentSuccess extends PaymentState {
  final Payment payment;

  const PaymentSuccess(this.payment);

  @override
  List<Object> get props => [payment];
}

/// State when payment fails
class PaymentFailure extends PaymentState {
  final String message;

  const PaymentFailure(this.message);

  @override
  List<Object> get props => [message];
}
