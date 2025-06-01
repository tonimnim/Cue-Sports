import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/usecases/check_payment_status.dart';
import '../../domain/usecases/initiate_payment.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// BLoC for handling payment-related events and states
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final InitiatePayment initiatePayment;
  final CheckPaymentStatus checkPaymentStatus;
  final LoggerService logger;
  Timer? _statusCheckTimer;

  PaymentBloc({
    required this.initiatePayment,
    required this.checkPaymentStatus,
    required this.logger,
  }) : super(PaymentInitial()) {
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<CheckPaymentStatusEvent>(_onCheckPaymentStatus);
    on<ResetPaymentEvent>(_onResetPayment);
  }

  /// Handle payment initiation
  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    try {
      logger.i('🔄 Initiating payment for user: ${event.userId}');

      final result = await initiatePayment(
        InitiatePaymentParams(
          userId: event.userId,
          paymentType: event.paymentType,
          typeId: event.typeId,
          phoneNumber: event.phoneNumber,
          amount: event.amount,
        ),
      );

      result.fold(
        (failure) {
          logger.e('❌ Payment initiation failed: ${failure.message}');
          emit(PaymentFailure(failure.message));
        },
        (payment) {
          logger.i('✅ Payment initiated: ${payment.id}');
          emit(PaymentInitiated(payment));
          _startStatusCheck(payment.id);
        },
      );
    } catch (e) {
      logger.e('🔥 Exception during payment initiation', e);
      emit(PaymentFailure('Payment initiation failed: $e'));
    }
  }

  /// Handle payment status check
  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatusEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      logger.i('🔄 Checking payment status: ${event.paymentId}');

      final result = await checkPaymentStatus(
        CheckPaymentStatusParams(paymentId: event.paymentId),
      );

      result.fold(
        (failure) {
          logger.e('❌ Payment status check failed: ${failure.message}');
          emit(PaymentFailure(failure.message));
        },
        (payment) {
          logger.i('✅ Payment status: ${payment.status}');
          switch (payment.status.toLowerCase()) {
            case 'pending':
              emit(PaymentPending(payment));
              break;
            case 'completed':
              _statusCheckTimer?.cancel();
              emit(PaymentSuccess(payment));
              break;
            case 'failed':
              _statusCheckTimer?.cancel();
              emit(PaymentFailure('Payment failed'));
              break;
            default:
              emit(PaymentFailure('Unknown payment status: ${payment.status}'));
          }
        },
      );
    } catch (e) {
      logger.e('🔥 Exception during payment status check', e);
      emit(PaymentFailure('Payment status check failed: $e'));
    }
  }

  /// Start periodic payment status check
  void _startStatusCheck(String paymentId) {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => add(CheckPaymentStatusEvent(paymentId: paymentId)),
    );

    // Stop checking after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      _statusCheckTimer?.cancel();
    });
  }

  /// Handle payment reset
  void _onResetPayment(ResetPaymentEvent event, Emitter<PaymentState> emit) {
    _statusCheckTimer?.cancel();
    emit(PaymentInitial());
  }

  @override
  Future<void> close() {
    _statusCheckTimer?.cancel();
    return super.close();
  }
} 