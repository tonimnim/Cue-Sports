import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pool_billiard_app/widget/inputs/app_text_field.dart';

/// Specialized text field for Kenyan phone numbers
/// 
/// Formats input as Kenyan phone number and provides validation
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final String? errorText;
  
  const PhoneTextField({
    Key? key,
    this.controller,
    this.hintText = 'Phone Number',
    this.labelText,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone),
      validator: validator ?? _validateKenyanPhone,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      errorText: errorText,
    );
  }

  /// Validates Kenyan phone number format
  /// 
  /// Valid formats: 07XXXXXXXX, 01XXXXXXXX, or +254XXXXXXXXX
  String? _validateKenyanPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Check Kenyan format (07XXXXXXXX, 01XXXXXXXX or +254XXXXXXXXX)
    if (digitsOnly.length < 9 || digitsOnly.length > 12) {
      return 'Please enter a valid Kenyan phone number';
    }
    
    // Check prefix
    if (!digitsOnly.startsWith('07') && 
        !digitsOnly.startsWith('01') && 
        !digitsOnly.startsWith('254') && 
        !digitsOnly.startsWith('+254')) {
      return 'Please enter a valid Kenyan phone number';
    }
    
    return null;
  }
}
