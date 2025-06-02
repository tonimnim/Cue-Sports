import 'package:equatable/equatable.dart';
import '../../../../core/services/secure_storage_service.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status on app start
class CheckAuthStatusEvent extends AuthEvent {}

/// Resume registration from local storage draft
class ResumeRegistrationEvent extends AuthEvent {}

/// Start fan registration flow
class StartFanRegistrationEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const StartFanRegistrationEvent({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, phoneNumber, password];
}

/// Start player registration flow
class StartPlayerRegistrationEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const StartPlayerRegistrationEvent({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, phoneNumber, password];
}

/// Select community for player registration
class SelectCommunityEvent extends AuthEvent {
  final String communityId;

  const SelectCommunityEvent({required this.communityId});

  @override
  List<Object> get props => [communityId];
}

/// Start polling for email verification
class StartEmailVerificationPollingEvent extends AuthEvent {
  final String uid;

  const StartEmailVerificationPollingEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Stop polling for email verification
class StopEmailVerificationPollingEvent extends AuthEvent {}

/// Email verification detected as complete
class EmailVerificationCompleteEvent extends AuthEvent {
  final String uid;

  const EmailVerificationCompleteEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Resend verification email
class ResendVerificationEmailEvent extends AuthEvent {
  final String uid;

  const ResendVerificationEmailEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Create Firestore user document after email verification
class CreateFirestoreUserEvent extends AuthEvent {
  final String uid;
  final RegistrationDraft draft;

  const CreateFirestoreUserEvent({
    required this.uid,
    required this.draft,
  });

  @override
  List<Object> get props => [uid, draft];
}

/// Verify payment for player registration
class VerifyPaymentEvent extends AuthEvent {
  final String paymentId;
  final String userId;
  final String? mpesaReceiptNumber;

  const VerifyPaymentEvent({
    required this.paymentId,
    required this.userId,
    this.mpesaReceiptNumber,
  });

  @override
  List<Object?> get props => [paymentId, userId, mpesaReceiptNumber];
}

/// Login user with email/phone and password
class LoginEvent extends AuthEvent {
  final String? email;
  final String? phoneNumber;
  final String password;

  const LoginEvent({
    this.email,
    this.phoneNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [email, phoneNumber, password];
}

/// Logout user
class LogoutEvent extends AuthEvent {}

/// Send password reset email
class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

/// Fetch available communities
class FetchCommunitiesEvent extends AuthEvent {}

/// Refresh authentication tokens
class RefreshTokensEvent extends AuthEvent {}

/// Clear registration draft
class ClearRegistrationDraftEvent extends AuthEvent {}

/// Handle payment deadline expiry
class HandlePaymentExpiryEvent extends AuthEvent {
  final String userId;

  const HandlePaymentExpiryEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Create pending registration with email verification
class CreatePendingRegistrationEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String userType; // 'fan' or 'player'
  final String? communityId; // For players only
  final String? paymentId; // For players only

  const CreatePendingRegistrationEvent({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.userType,
    this.communityId,
    this.paymentId,
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        phoneNumber,
        password,
        userType,
        communityId,
        paymentId
      ];
}

/// Verify email from pending registration and complete registration
class VerifyEmailFromPendingEvent extends AuthEvent {
  final String email;
  final String verificationCode;

  const VerifyEmailFromPendingEvent({
    required this.email,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [email, verificationCode];
}

/// Check pending registration status
class CheckPendingRegistrationStatusEvent extends AuthEvent {
  final String email;

  const CheckPendingRegistrationStatusEvent({required this.email});

  @override
  List<Object> get props => [email];
}

/// Resend verification email for pending registration
class ResendPendingVerificationEmailEvent extends AuthEvent {
  final String email;

  const ResendPendingVerificationEmailEvent({required this.email});

  @override
  List<Object> get props => [email];
}

/// Verify SMS code and complete registration
class VerifySmsCodeEvent extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;

  const VerifySmsCodeEvent({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [phoneNumber, verificationCode];
}

/// Resend SMS verification code
class ResendSmsCodeEvent extends AuthEvent {
  final String phoneNumber;

  const ResendSmsCodeEvent({
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [phoneNumber];
}
