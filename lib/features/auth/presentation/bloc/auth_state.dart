import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/community.dart';
import '../../../../core/services/secure_storage_service.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {}

/// Loading state for any auth operation
class AuthLoading extends AuthState {
  final String message;

  const AuthLoading({this.message = 'Loading...'});

  @override
  List<Object> get props => [message];
}

/// User has a valid session and is authenticated
class AuthAuthenticated extends AuthState {
  final User user;
  final bool isAutoLogin; // True if logged in automatically from stored tokens

  const AuthAuthenticated({
    required this.user,
    this.isAutoLogin = false,
  });

  @override
  List<Object> get props => [user, isAutoLogin];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Registration draft has been saved to local storage
class RegistrationDraftSaved extends AuthState {
  final RegistrationDraft draft;
  final String message;

  const RegistrationDraftSaved({
    required this.draft,
    required this.message,
  });

  @override
  List<Object> get props => [draft, message];
}

/// Community selected for player registration
class CommunitySelected extends AuthState {
  final RegistrationDraft draft;
  final Community selectedCommunity;

  const CommunitySelected({
    required this.draft,
    required this.selectedCommunity,
  });

  @override
  List<Object> get props => [draft, selectedCommunity];
}

/// Firebase Auth account created, verification email sent
class EmailVerificationSent extends AuthState {
  final String email;
  final String uid;
  final String message;

  const EmailVerificationSent({
    required this.email,
    required this.uid,
    required this.message,
  });

  @override
  List<Object> get props => [email, uid, message];
}

/// Polling for email verification
class PollingEmailVerification extends AuthState {
  final String email;
  final String uid;
  final int attemptCount;

  const PollingEmailVerification({
    required this.email,
    required this.uid,
    this.attemptCount = 1,
  });

  @override
  List<Object> get props => [email, uid, attemptCount];
}

/// Email verified, proceeding to create Firestore user
class EmailVerified extends AuthState {
  final String uid;
  final RegistrationDraft draft;

  const EmailVerified({
    required this.uid,
    required this.draft,
  });

  @override
  List<Object> get props => [uid, draft];
}

/// Fan registration completed successfully
class FanRegistrationComplete extends AuthState {
  final User user;

  const FanRegistrationComplete(this.user);

  @override
  List<Object> get props => [user];
}

/// Player account created, payment required
class PlayerAccountCreated extends AuthState {
  final User user;
  final String paymentId;

  const PlayerAccountCreated({
    required this.user,
    required this.paymentId,
  });

  @override
  List<Object> get props => [user, paymentId];
}

/// Player payment required (for returning unpaid users)
class PlayerPaymentRequired extends AuthState {
  final User user;
  final DateTime paymentDeadline;
  final String paymentId;

  const PlayerPaymentRequired({
    required this.user,
    required this.paymentDeadline,
    required this.paymentId,
  });

  @override
  List<Object> get props => [user, paymentDeadline, paymentId];
}

/// Payment verification in progress
class PaymentVerifying extends AuthState {
  final String paymentId;

  const PaymentVerifying({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// Payment completed successfully
class PaymentCompleted extends AuthState {
  final User user;

  const PaymentCompleted(this.user);

  @override
  List<Object> get props => [user];
}

/// Communities loading
class CommunitiesLoading extends AuthState {}

/// Communities loaded successfully
class CommunitiesLoaded extends AuthState {
  final List<Community> communities;

  const CommunitiesLoaded(this.communities);

  @override
  List<Object> get props => [communities];
}

/// Registration expired (player didn't pay within deadline)
class RegistrationExpired extends AuthState {
  final String email;
  final String message;

  const RegistrationExpired({
    required this.email,
    required this.message,
  });

  @override
  List<Object> get props => [email, message];
}

/// Password reset email sent
class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object> get props => [email];
}

/// Authentication error occurred
class AuthError extends AuthState {
  final String message;
  final String? email; // Optional email for context

  const AuthError(this.message, {this.email});

  @override
  List<Object?> get props => [message, email];
}

// New Pending Registration States

/// Pending registration created, verification email sent
class PendingRegistrationCreated extends AuthState {
  final String email;
  final String fullName;
  final String userType;
  final String message;

  const PendingRegistrationCreated({
    required this.email,
    required this.fullName,
    required this.userType,
    required this.message,
  });

  @override
  List<Object> get props => [email, fullName, userType, message];
}

/// Email verification completed, registration in progress
class EmailVerificationCompleted extends AuthState {
  final String email;
  final String message;

  const EmailVerificationCompleted({
    required this.email,
    required this.message,
  });

  @override
  List<Object> get props => [email, message];
}

/// Pending registration status loaded
class PendingRegistrationStatusLoaded extends AuthState {
  final String email;
  final Map<String, dynamic> pendingData;

  const PendingRegistrationStatusLoaded({
    required this.email,
    required this.pendingData,
  });

  @override
  List<Object> get props => [email, pendingData];
}

/// No pending registration found
class NoPendingRegistrationFound extends AuthState {
  final String email;

  const NoPendingRegistrationFound({required this.email});

  @override
  List<Object> get props => [email];
}

/// Verification email resent successfully
class VerificationEmailResent extends AuthState {
  final String email;
  final String message;

  const VerificationEmailResent({
    required this.email,
    required this.message,
  });

  @override
  List<Object> get props => [email, message];
}

/// Registration completed successfully
class RegistrationCompleted extends AuthState {
  final User user;
  final String message;

  const RegistrationCompleted({
    required this.user,
    required this.message,
  });

  @override
  List<Object> get props => [user, message];
}

/// SMS verification code resent successfully
class SmsCodeResent extends AuthState {
  final String phoneNumber;
  final String message;

  const SmsCodeResent({
    required this.phoneNumber,
    required this.message,
  });

  @override
  List<Object> get props => [phoneNumber, message];
}
