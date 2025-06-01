import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

/// Loading indicator for asynchronous operations
/// 
/// Displays a circular progress indicator with Kenya Pool Billiards styling
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  
  const LoadingIndicator({
    Key? key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppTheme.accentColor),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
