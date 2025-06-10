import 'package:flutter/material.dart';
import '../../../../core/config/theme.dart';
import '../../domain/entities/payment.dart';

/// Widget to display payment status with animation
class PaymentStatusIndicator extends StatefulWidget {
  final PaymentStatus status;
  final String message;

  const PaymentStatusIndicator({
    Key? key,
    required this.status,
    required this.message,
  }) : super(key: key);

  @override
  State<PaymentStatusIndicator> createState() => _PaymentStatusIndicatorState();
}

class _PaymentStatusIndicatorState extends State<PaymentStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.status == PaymentStatus.pending ||
        widget.status == PaymentStatus.processing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PaymentStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status == PaymentStatus.pending ||
          widget.status == PaymentStatus.processing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case PaymentStatus.initial:
        return Icons.payment;
      case PaymentStatus.pending:
        return Icons.phone_android;
      case PaymentStatus.processing:
        return Icons.sync;
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.timeout:
        return Icons.timer_off;
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case PaymentStatus.initial:
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return AppTheme.accentColor;
      case PaymentStatus.success:
        return AppTheme.successColor;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.timeout:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: AppTheme.bodyLargeStyle,
            textAlign: TextAlign.center,
          ),
          if (widget.status == PaymentStatus.pending) ...[
            const SizedBox(height: 8),
            Text(
              'Please enter your M-Pesa PIN on your phone',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
