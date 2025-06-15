import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/payment.dart';
import '../../services/tinypesa_service.dart';
import '../../services/payment_callback_service.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// Production-ready payment bloc with proper error handling and memory management
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final TinyPesaService _tinyPesaService;
  final LoggerService _logger = di.sl<LoggerService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShopBloc? shopBloc;

  // Timers and subscriptions for proper cleanup
  Timer? _pollTimer;
  StreamSubscription? _paymentSubscription;

  // Constants for polling
  static const int _maxPollAttempts = 12; // 60 seconds total
  static const Duration _pollInterval = Duration(seconds: 5);

  PaymentBloc({
    TinyPesaService? tinyPesaService,
    this.shopBloc,
  })  : _tinyPesaService = tinyPesaService ?? TinyPesaService(),
        super(PaymentState.initial()) {
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<CheckPaymentStatusEvent>(_onCheckPaymentStatus);
    on<PaymentStatusUpdatedEvent>(_onPaymentStatusUpdated);
    on<RetryPaymentEvent>(_onRetryPayment);
    on<CancelPaymentEvent>(_onCancelPayment);
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<ResetPaymentStateEvent>(_onResetPaymentState);
  }

  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Cancel any existing operations
      _cancelPolling();

      emit(state.copyWith(
        isLoading: true,
        status: PaymentStatus.initial,
        clearError: true,
      ));

      // Validate inputs
      if (event.userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }
      if (event.amount <= 0) {
        throw ArgumentError('Amount must be greater than zero');
      }
      if (event.phoneNumber.isEmpty) {
        throw ArgumentError('Phone number cannot be empty');
      }

      // Generate unique transaction ID
      final transactionId =
          '${event.userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create payment entity
      final payment = Payment(
        id: 'payment_$transactionId',
        userId: event.userId,
        type: event.paymentType,
        typeId: event.typeId,
        amount: event.amount,
        phoneNumber: event.phoneNumber,
        status: PaymentStatus.pending,
        transactionId: transactionId,
        createdAt: DateTime.now(),
        metadata: event.metadata,
      );

      emit(state.copyWith(
        currentPayment: payment,
        status: PaymentStatus.pending,
      ));

      // Initiate payment with TinyPesa
      final response = await _tinyPesaService.initiatePayment(
        paymentType: event.paymentType.name,
        typeId: event.typeId,
        userId: event.userId,
        phoneNumber: event.phoneNumber,
        amount: event.amount,
        transactionId: transactionId,
      );

      if (response.success && response.checkoutRequestId != null) {
        // Update payment with checkout request ID
        final updatedPayment = payment.copyWith(
          checkoutRequestId: response.checkoutRequestId,
          status: PaymentStatus.processing,
        );

        emit(state.copyWith(
          currentPayment: updatedPayment,
          status: PaymentStatus.processing,
          isLoading: false,
          isPolling: true,
        ));

        // Start polling for status
        _startPolling(transactionId);
      } else {
        // Payment initiation failed
        // Format error message to include 'TinyPesa API error' prefix
        final errorMessage = 'TinyPesa API error: ${response.message}';
        
        // Mark payment as failed instead of treating it as success
        final failedPayment = payment.copyWith(
          status: PaymentStatus.failed,
          errorMessage: errorMessage,
          updatedAt: DateTime.now(),
        );

        emit(state.copyWith(
          currentPayment: failedPayment,
          status: PaymentStatus.failed,
          errorMessage: errorMessage,
          isLoading: false,
        ));

        _logger.w('TinyPesa API error occurred: $errorMessage');
        
        // Call failure callback
        await _handlePaymentCallback(failedPayment, false);
      }
    } catch (e, stackTrace) {
      _logger.w('Payment initiation error: $e\n$stackTrace');
      
      // Format error message to include 'TinyPesa API error' prefix
      final errorMessage = 'TinyPesa API error: ${e.toString()}';
      
      // Mark payment as failed
      final failedPayment = state.currentPayment?.copyWith(
        status: PaymentStatus.failed,
        errorMessage: errorMessage,
        updatedAt: DateTime.now(),
      );

      emit(state.copyWith(
        currentPayment: failedPayment,
        status: PaymentStatus.failed,
        errorMessage: errorMessage,
        isLoading: false,
      ));
      
      // Call failure callback if we have a payment
      if (failedPayment != null) {
        await _handlePaymentCallback(failedPayment, false);
      }
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatusEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final response =
          await _tinyPesaService.checkPaymentStatus(event.transactionId);

      if (state.currentPayment == null) {
        _logger.w('No current payment found for status check');
        return;
      }

      Payment updatedPayment;

      switch (response.status) {
        case PaymentStatusType.success:
          updatedPayment = state.currentPayment!.copyWith(
            status: PaymentStatus.success,
            mpesaReceiptNumber: response.mpesaReceiptNumber,
            updatedAt: DateTime.now(),
          );

          emit(state.copyWith(
            currentPayment: updatedPayment,
            status: PaymentStatus.success,
            isPolling: false,
          ));

          _cancelPolling();
          await _handlePaymentCallback(updatedPayment, true);
          break;

        case PaymentStatusType.failed:
          updatedPayment = state.currentPayment!.copyWith(
            status: PaymentStatus.failed,
            errorMessage: response.message,
            updatedAt: DateTime.now(),
          );

          emit(state.copyWith(
            currentPayment: updatedPayment,
            status: PaymentStatus.failed,
            errorMessage: response.message,
            isPolling: false,
          ));

          _cancelPolling();
          await _handlePaymentCallback(updatedPayment, false);
          break;

        case PaymentStatusType.pending:
          // Still pending, continue polling
          emit(state.copyWith(
            pollAttempts: state.pollAttempts + 1,
            lastPollTime: DateTime.now(),
          ));

          // Check if we've exceeded max attempts
          if (state.pollAttempts >= _maxPollAttempts) {
            updatedPayment = state.currentPayment!.copyWith(
              status: PaymentStatus.timeout,
              errorMessage: 'Payment verification timed out',
              updatedAt: DateTime.now(),
            );

            emit(state.copyWith(
              currentPayment: updatedPayment,
              status: PaymentStatus.timeout,
              errorMessage: 'Payment verification timed out',
              isPolling: false,
            ));

            _cancelPolling();
            await _handlePaymentCallback(updatedPayment, false);
          }
          break;

        default:
          _logger.w('Unknown payment status: ${response.status}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error checking payment status: $e\n$stackTrace');

      // Don't stop polling on error, might be temporary
      if (state.pollAttempts >= _maxPollAttempts) {
        _cancelPolling();
        emit(state.copyWith(
          status: PaymentStatus.failed,
          errorMessage: 'Failed to verify payment status',
          isPolling: false,
        ));
      }
    }
  }

  Future<void> _onPaymentStatusUpdated(
    PaymentStatusUpdatedEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(
      currentPayment: event.payment,
      status: event.payment.status,
    ));
  }

  Future<void> _onRetryPayment(
    RetryPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    if (!state.canRetry) {
      _logger.w('Cannot retry payment in current state: ${state.status}');
      return;
    }

    // Create new payment event from the failed payment
    add(InitiatePaymentEvent(
      paymentType: event.payment.type,
      typeId: event.payment.typeId,
      userId: event.payment.userId,
      amount: event.payment.amount,
      phoneNumber: event.payment.phoneNumber,
      metadata: event.payment.metadata,
    ));
  }

  Future<void> _onCancelPayment(
    CancelPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    _cancelPolling();

    if (state.currentPayment != null && state.isPaymentInProgress) {
      final cancelledPayment = state.currentPayment!.copyWith(
        status: PaymentStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      emit(state.copyWith(
        currentPayment: cancelledPayment,
        status: PaymentStatus.cancelled,
        isPolling: false,
      ));

      // Call cancelled callback
      final callbackService =
          PaymentCallbackFactory.create(cancelledPayment.type);
      await callbackService.onPaymentCancelled(cancelledPayment);
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      Query query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: event.userId)
          .orderBy('createdAt', descending: true);

      if (event.filterByType != null) {
        query = query.where('type', isEqualTo: event.filterByType!.name);
      }

      final snapshot = await query.limit(50).get();

      final payments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Payment(
          id: doc.id,
          userId: data['userId'] ?? '',
          type: PaymentType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => PaymentType.merchandise,
          ),
          typeId: data['typeId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          phoneNumber: data['phoneNumber'] ?? '',
          status: PaymentStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => PaymentStatus.failed,
          ),
          mpesaReceiptNumber: data['mpesaReceiptNumber'],
          checkoutRequestId: data['checkoutRequestId'],
          transactionId: data['transactionId'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
          metadata: data['metadata'],
          errorMessage: data['errorMessage'],
        );
      }).toList();

      emit(state.copyWith(
        paymentHistory: payments,
        isLoading: false,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error loading payment history: $e\n$stackTrace');
      emit(state.copyWith(
        errorMessage: 'Failed to load payment history',
        isLoading: false,
      ));
    }
  }

  Future<void> _onResetPaymentState(
    ResetPaymentStateEvent event,
    Emitter<PaymentState> emit,
  ) async {
    _cancelPolling();
    emit(PaymentState.initial());
  }

  /// Start polling for payment status
  void _startPolling(String transactionId) {
    _cancelPolling(); // Cancel any existing polling

    _pollTimer = Timer.periodic(_pollInterval, (timer) {
      if (!isClosed) {
        add(CheckPaymentStatusEvent(transactionId: transactionId));
      } else {
        timer.cancel();
      }
    });
  }

  /// Cancel polling timer
  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Handle payment callbacks based on payment type
  Future<void> _handlePaymentCallback(Payment payment, bool success) async {
    try {
      // Save payment to Firestore
      await _firestore.collection('payments').doc(payment.id).set({
        'userId': payment.userId,
        'type': payment.type.name,
        'typeId': payment.typeId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': payment.status.name,
        'mpesaReceiptNumber': payment.mpesaReceiptNumber,
        'checkoutRequestId': payment.checkoutRequestId,
        'transactionId': payment.transactionId,
        'createdAt': payment.createdAt,
        'updatedAt': payment.updatedAt ?? DateTime.now(),
        'metadata': payment.metadata,
        'errorMessage': payment.errorMessage,
      });

      // Get appropriate callback service
      final callbackService = PaymentCallbackFactory.create(payment.type, shopBloc: shopBloc);

      if (success) {
        await callbackService.onPaymentSuccess(payment);
      } else {
        await callbackService.onPaymentFailed(payment);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling payment callback: $e\n$stackTrace');
    }
  }

  @override
  Future<void> close() {
    _cancelPolling();
    _paymentSubscription?.cancel();
    return super.close();
  }
}
