class PasswordValidator {
  static const int minLength = 6;
  static const int maxLength = 128;

  /// Validates password - only requires minimum 6 characters for MVP
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }

    if (password.length > maxLength) {
      return 'Password cannot exceed $maxLength characters';
    }

    return null; // Password is valid
  }

  /// Checks if passwords match for confirmation
  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Gets password strength score (0-5) - simplified for MVP
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return score;
  }

  /// Gets password strength description
  static String getPasswordStrengthText(String password) {
    final strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Fair';
      case 4:
      case 5:
        return 'Good';
      case 6:
        return 'Strong';
      default:
        return 'Weak';
    }
  }
}
