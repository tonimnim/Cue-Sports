import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Register a new fan user
  Future<Either<Failure, User>> registerFan({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Register a new player user with payment
  Future<Either<Failure, User>> registerPlayer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String communityId,
    required String paymentId,
  });

  /// Login with email and password
  Future<Either<Failure, User>> login({
    String? email,
    String? phoneNumber,
    required String password,
  });

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Get the current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Verify password reset code
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Reset password with verification code
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Get user by phone number
  Future<Either<Failure, User?>> getUserByPhone(String phoneNumber);

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  });

  /// Upgrade a fan to a player
  Future<Either<Failure, User>> upgradeToPlayer({
    required String userId,
    required String communityId,
    required String paymentId,
  });

  /// Check if email exists
  Future<Either<Failure, bool>> checkEmailExists(String email);

  /// Check if phone number exists
  Future<Either<Failure, bool>> checkPhoneExists(String phoneNumber);

  /// Check if email is verified
  Future<Either<Failure, bool>> checkEmailVerified(String email);
} 