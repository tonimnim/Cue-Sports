import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

/// Text-only button for secondary actions
/// 
/// Used for "Forgot Password?" and registration links
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool underlined;
  
  const AppTextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.underlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppTheme.accentColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          decoration: underlined ? TextDecoration.underline : null,
        ),
      ),
    );
  }
}
