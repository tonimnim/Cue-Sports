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
