/// Utility class for validating and formatting Kenyan phone numbers
class PhoneValidator {
  static const String _safaricomPrefix = '07';
  static const String _airtelPrefix = '01';
  static const String _telkomPrefix = '05';

  /// Validate a Kenyan phone number
  /// Returns true if the number is valid
  static bool isValidKenyanNumber(String phone) {
    // Remove any whitespace and special characters
    final cleanNumber = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if number starts with +254 or 0
    String normalizedNumber = cleanNumber;
    if (cleanNumber.startsWith('+254')) {
      normalizedNumber = '0${cleanNumber.substring(4)}';
    }
    
    // Check if number is 10 digits and starts with valid prefix
    if (normalizedNumber.length != 10) return false;
    
    return normalizedNumber.startsWith(_safaricomPrefix) ||
           normalizedNumber.startsWith(_airtelPrefix) ||
           normalizedNumber.startsWith(_telkomPrefix);
  }

  /// Format a phone number to standard format
  /// Returns null if number is invalid
  static String? formatKenyanNumber(String phone) {
    if (!isValidKenyanNumber(phone)) return null;
    
    // Remove any whitespace and special characters
    final cleanNumber = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Convert to standard format starting with 0
    if (cleanNumber.startsWith('+254')) {
      return '0${cleanNumber.substring(4)}';
    }
    
    return cleanNumber;
  }

  /// Convert a phone number to international format (+254)
  /// Returns null if number is invalid
  static String? toInternationalFormat(String phone) {
    final formattedNumber = formatKenyanNumber(phone);
    if (formattedNumber == null) return null;
    
    return '+254${formattedNumber.substring(1)}';
  }

  /// Extract error message for invalid phone number
  static String? getErrorMessage(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    
    final cleanNumber = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanNumber.length != 10 && !cleanNumber.startsWith('+254')) {
      return 'Phone number must be 10 digits';
    }
    
    if (!isValidKenyanNumber(phone)) {
      return 'Please enter a valid Kenyan phone number';
    }
    
    return null;
  }
} 