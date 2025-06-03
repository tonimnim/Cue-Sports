import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/utils/password_validator.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class EnhancedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool showStrengthIndicator;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onChanged;

  const EnhancedPasswordField({
    Key? key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.showStrengthIndicator = true,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  State<EnhancedPasswordField> createState() => _EnhancedPasswordFieldState();
}

class _EnhancedPasswordFieldState extends State<EnhancedPasswordField>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _strengthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _strengthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    widget.controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    // Proper cleanup to prevent memory leaks
    widget.controller.removeListener(_onPasswordChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (widget.showStrengthIndicator) {
      final strength =
          PasswordValidator.getPasswordStrength(widget.controller.text);
      final targetValue = strength / 5.0; // Convert to 0-1 range
      _animationController.animateTo(targetValue);
    }
    widget.onChanged?.call();
    if (mounted) {
      setState(() {}); // Only rebuild if widget is still mounted
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppTheme.errorColor;
      case 2:
        return AppTheme.warningColor;
      case 3:
        return const Color(0xFFFFB300); // Amber
      case 4:
        return AppTheme.successColor;
      case 5:
        return AppTheme.accentColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.controller.text;
    final strength =
        password.isEmpty ? 0 : PasswordValidator.getPasswordStrength(password);
    final strengthText = password.isEmpty
        ? ''
        : PasswordValidator.getPasswordStrengthText(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password Field
        TextFormField(
          controller: widget.controller,
          obscureText: _obscurePassword,
          validator: widget.validator,
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textLight,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            hintStyle: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textLight.withOpacity(0.5),
            ),
            labelStyle: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textLight.withOpacity(0.8),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppTheme.textLight.withOpacity(0.7),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Password strength icon (for visual feedback)
                if (widget.showStrengthIndicator && password.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      strength >= 4 ? Icons.check_circle : Icons.info_outline,
                      color: _getStrengthColor(strength),
                      size: 20,
                    ),
                  ),
                // Toggle visibility button
                IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.textLight.withOpacity(0.7),
                  ),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }
                  },
                ),
              ],
            ),
            filled: true,
            fillColor: AppTheme.formBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.textLight.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.accentColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),

        // Password Strength Indicator
        if (widget.showStrengthIndicator && password.isNotEmpty) ...[
          const SizedBox(height: 12),

          // Strength Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppTheme.textLight.withOpacity(0.1),
            ),
            child: AnimatedBuilder(
              animation: _strengthAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _strengthAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _getStrengthColor(strength),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Strength Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength: $strengthText',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: _getStrengthColor(strength),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (strength < 4)
                Text(
                  '${5 - strength} requirements missing',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.textLight.withOpacity(0.6),
                  ),
                ),
            ],
          ),

          // Password Requirements (show when password is weak)
          if (strength < 4) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.formBackground.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textLight.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement(
                      'At least 8 characters', password.length >= 8),
                  _buildRequirement('One uppercase letter',
                      RegExp(r'[A-Z]').hasMatch(password)),
                  _buildRequirement('One lowercase letter',
                      RegExp(r'[a-z]').hasMatch(password)),
                  _buildRequirement(
                      'One number', RegExp(r'[0-9]').hasMatch(password)),
                  _buildRequirement('One special character',
                      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met
                ? AppTheme.successColor
                : AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: met
                    ? AppTheme.successColor
                    : AppTheme.textLight.withOpacity(0.7),
                fontWeight: met ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
