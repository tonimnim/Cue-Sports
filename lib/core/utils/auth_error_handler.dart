import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  /// Convert Firebase Auth errors to user-friendly messages
  static String getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email or phone number. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new code.';
      case 'code-expired':
        return 'Verification code has expired. Please request a new one.';
      case 'session-expired':
        return 'Your session has expired. Please sign in again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized for this operation. Please contact support.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'missing-phone-number':
        return 'Phone number is required for SMS verification.';
      case 'invalid-app-credential':
        return 'Invalid app credentials. Please contact support.';
      default:
        return error.message ??
            'An unexpected error occurred. Please try again.';
    }
  }

  /// Get user-friendly error message for general auth errors
  static String getGeneralErrorMessage(String errorCode) {
    switch (errorCode.toLowerCase()) {
      case 'network_error':
        return 'Please check your internet connection and try again.';
      case 'server_error':
        return 'Server is temporarily unavailable. Please try again later.';
      case 'validation_error':
        return 'Please check your input and try again.';
      case 'timeout_error':
        return 'Request timed out. Please try again.';
      case 'permission_denied':
        return 'You don\'t have permission to perform this action.';
      case 'rate_limit_exceeded':
        return 'Too many requests. Please wait a moment and try again.';
      case 'payment_required':
        return 'Payment is required to complete this action.';
      case 'account_locked':
        return 'Account temporarily locked due to suspicious activity.';
      case 'maintenance_mode':
        return 'App is under maintenance. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is retryable
  static bool isRetryableError(String errorCode) {
    final retryableErrors = [
      'network-request-failed',
      'timeout_error',
      'server_error',
      'quota-exceeded',
      'too-many-requests',
    ];
    return retryableErrors.contains(errorCode.toLowerCase());
  }

  /// Check if error requires user action
  static bool requiresUserAction(String errorCode) {
    final actionRequiredErrors = [
      'weak-password',
      'invalid-email',
      'invalid-phone-number',
      'wrong-password',
      'invalid-verification-code',
      'email-already-in-use',
    ];
    return actionRequiredErrors.contains(errorCode.toLowerCase());
  }

  /// Get suggested action for error
  static String? getSuggestedAction(String errorCode) {
    switch (errorCode.toLowerCase()) {
      case 'weak-password':
        return 'Use at least 8 characters with uppercase, lowercase, numbers, and symbols.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., user@example.com).';
      case 'wrong-password':
        return 'Try resetting your password if you\'ve forgotten it.';
      case 'user-not-found':
        return 'Register for a new account if you don\'t have one.';
      case 'too-many-requests':
        return 'Wait 5-10 minutes before trying again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'invalid-verification-code':
        return 'Request a new verification code if the current one isn\'t working.';
      default:
        return null;
    }
  }
}
