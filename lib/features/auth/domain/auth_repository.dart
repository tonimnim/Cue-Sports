import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'entities.dart';

/// Repository interface for authentication operations
/// This follows the Repository pattern and defines the contract
/// that any implementation must adhere to.
///
/// All methods return Either<Failure, T> where T is the success type
/// This allows for consistent error handling throughout the app
abstract class AuthRepository {
  /// Pending Registration Methods (New Approach - SMS Based)

  /// Create a pending registration with SMS verification
  Future<Either<Failure, bool>> createPendingUserRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String userType,
    String? communityId,
    String? paymentId,
  });

  /// Verify SMS code and complete registration (Create Firebase Auth account)
  Future<Either<Failure, User>> verifySmsAndCompleteRegistration({
    required String phoneNumber,
    required String verificationCode,
  });

  /// Resend SMS verification code (with cooldown protection)
  Future<Either<Failure, bool>> resendSmsVerificationCode({
    required String phoneNumber,
  });

  /// Check if pending registration exists and is valid
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistrationStatus({
    required String email,
  });

  /// Legacy Email Verification Methods (Deprecated - Use SMS instead)

  /// Verify email and complete registration (Create Firebase Auth account)
  Future<Either<Failure, User>> verifyEmailAndCompleteRegistration({
    required String email,
    required String verificationCode,
  });

  /// Resend verification email for pending registration
  Future<Either<Failure, bool>> resendVerificationEmail({
    required String email,
  });

  /// Legacy Methods (Keep for backward compatibility during transition)

  /// Create a pending registration record before email verification (Legacy)
  Future<Either<Failure, bool>> createPendingRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String verificationCode,
    String? userType,
  });

  /// Verify an email for pending registration (Legacy)
  Future<Either<Failure, bool>> verifyPendingRegistration({
    required String email,
    required String verificationCode,
  });

  /// Get pending registration data (Legacy)
  Future<Either<Failure, Map<String, dynamic>?>> getPendingRegistration({
    required String email,
  });

  /// Delete a pending registration (Legacy)
  Future<Either<Failure, bool>> deletePendingRegistration({
    required String email,
  });

  /// Register a new fan user
  ///
  /// Returns Either a Failure or the registered User
  Future<Either<Failure, User>> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Register a new player user with payment
  ///
  /// Returns Either a Failure or the registered User
  Future<Either<Failure, User>> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  });

  /// Login an existing user
  ///
  /// Returns Either a Failure or the logged in User
  /// Also stores authentication tokens for future requests
  /// Either email or phoneNumber must be provided
  Future<Either<Failure, User>> login({
    String? email,
    String? phoneNumber,
    required String password,
  });

  /// Logout the current user
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated
  ///
  /// Returns Either a Failure or the current User if authenticated

  /// Get available communities
  ///
  /// Returns Either a Failure or a List of Communities
  Future<Either<Failure, List<Community>>> getCommunities();
  Future<Either<Failure, User?>> getCurrentUser();

  /// Send password reset email
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Verify password reset code
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Reset password with code
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Upgrade fan to player with payment
  ///
  /// Returns Either a Failure or the updated User
  Future<Either<Failure, User>> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  });

  /// Update user profile
  ///
  /// Returns Either a Failure or the updated User
  Future<Either<Failure, User>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  });

  /// Verify user email
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> verifyEmail({
    required String email,
    required String code,
  });

  /// Send email verification code
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> sendEmailVerification({
    required String email,
  });

  /// Get user by ID
  ///
  /// Returns Either a Failure or the User with the specified ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Get user by phone number
  ///
  /// Returns Either a Failure or the User with the specified phone number
  Future<Either<Failure, User?>> getUserByPhone(String phoneNumber);

  /// Delete user account
  ///
  /// Returns Either a Failure or void if successful
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Get authentication token
  ///
  /// Returns Either a Failure or the authentication token if available
  Future<Either<Failure, String?>> getAuthToken();

  /// Check if token is valid and not expired
  ///
  /// Returns Either a Failure or boolean indicating if token is valid
  Future<Either<Failure, bool>> isTokenValid();

  /// Check if a user exists with the given email
  ///
  /// Returns Either a Failure or boolean indicating if user exists
  Future<Either<Failure, bool>> checkEmailExists(String email);

  /// Check if a user exists with the given phone number
  ///
  /// Returns Either a Failure or boolean indicating if user exists
  Future<Either<Failure, bool>> checkPhoneExists(String phoneNumber);

  /// Check if a user's email is verified
  ///
  /// Returns Either a Failure or boolean indicating if email is verified
  Future<Either<Failure, bool>> isEmailVerified(String email);

  /// Update a pending registration
  Future<Either<Failure, bool>> updatePendingRegistration({
    required String email,
    required Map<String, dynamic> updates,
  });

  /// Complete email verification and store tokens
  Future<Either<Failure, User>> completeEmailVerification({
    required String uid,
  });

  /// Verify custom email verification code
  /// Returns Either a Failure or the verified User
  Future<Either<Failure, User>> verifyCustomEmailCode({
    required String email,
    required String verificationCode,
  });

  /// Clean up orphaned Firebase Auth account
  /// This is useful when a Firebase Auth account exists but no Firestore document
  Future<Either<Failure, bool>> cleanupOrphanedAccount({
    required String email,
    required String password,
  });
}
