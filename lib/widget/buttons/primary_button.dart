import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

/// Primary action button for the Kenya Pool Billiards app
/// 
/// Features yellow background with customizable text and loading state
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;
  
  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: AppTheme.textDark,
          disabledBackgroundColor: AppTheme.accentColor.withValues(alpha: 153), // 0.6 opacity (255 * 0.6 = 153)
          disabledForegroundColor: AppTheme.textDark.withValues(alpha: 153), // 0.6 opacity (255 * 0.6 = 153)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textDark),
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppTheme.buttonTextStyle,
              ),
      ),
    );
  }
}
