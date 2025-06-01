class StringConstants {
  // App information
  static const String appName = 'Kenya Pool Billiards Club';
  static const String appVersion = '1.0.0';

  // Auth screens
  static const String welcomeMessage = 'Welcome to Kenya Pool Billiards Club';
  static const String loginTitle = 'Sign In';
  static const String registerTitle = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = 'Don\'t have an account?';
  static const String hasAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String verifyEmail = 'Verify your email';
  static const String verificationSent = 'Verification code sent to your email';
  static const String resendCode = 'Resend Code';
  static const String verify = 'Verify';
  static const String resetPassword = 'Reset Password';
  static const String newPassword = 'New Password';
  static const String confirmPassword = 'Confirm Password';
  static const String resetPasswordSuccess = 'Password reset successful';

  // Membership
  static const String chooseMembership = 'Choose Membership Type';
  static const String playerMembership = 'Player';
  static const String playerMembershipDesc =
      'Register as a player to participate in tournaments and track your stats. KSh 500 registration fee.';
  static const String basicMembership = 'Basic User';
  static const String basicMembershipDesc =
      'Join as a basic user to follow tournaments and connect with the pool community.';
  static const String continueText = 'Continue';

  // Payment
  static const String paymentTitle = 'Player Registration Payment';
  static const String paymentAmount = 'Amount: KSh 500';
  static const String paymentInstructions =
      'Pay via M-Pesa to complete your player registration';
  static const String paymentSuccessful = 'Payment Successful';
  static const String paymentFailed = 'Payment Failed';

  // Form labels
  static const String nameLabel = 'Full Name';
  static const String phoneLabel = 'Phone Number';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String codeLabel = 'Verification Code';

  // Error messages
  static const String generalError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network error. Please check your internet connection.';
  static const String invalidCredentials = 'Invalid phone number or password.';
  static const String invalidCode = 'Invalid verification code.';
  static const String emailInUse = 'This email is already in use.';
  static const String phoneInUse = 'This phone number is already in use.';
  static const String weakPassword =
      'Password is too weak. Use at least 6 characters.';
}

class AssetPaths {
  static const String logo = 'assets/images/logo.png';
}
