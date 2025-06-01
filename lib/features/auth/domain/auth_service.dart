import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:pool_billiard_app/core/error/failures.dart';

/// AuthService provides direct access to Firebase Authentication with simplified methods
/// This is a complementary service to the AuthRepository for streamlined authentication
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        return Right(userCredential.user!);
      } else {
        return const Left(AuthFailure(message: 'Failed to authenticate user'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Authentication error: $e'));
    }
  }

  /// Sign in with phone number by first querying Firestore
  Future<Either<Failure, User>> signInWithPhoneAndPassword({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Query Firestore to find the user with this phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return const Left(AuthFailure(message: 'No user found with this phone number'));
      }
      
      // Get the user's email from Firestore
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final userEmail = userData['email'] as String?;
      
      if (userEmail == null || userEmail.isEmpty) {
        return const Left(AuthFailure(message: 'User email not found. Please contact support'));
      }
      
      // Sign in with email and password
      return await signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Phone login error: $e'));
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Password reset error: $e'));
    }
  }

  /// Create a new user with email and password
  Future<Either<Failure, User>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        return Right(userCredential.user!);
      } else {
        return const Left(AuthFailure(message: 'Failed to create user'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_handleFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'User creation error: $e'));
    }
  }

  /// Get user details from Firestore
  Future<Either<Failure, Map<String, dynamic>?>> getUserDetails({
    String? userId,
    String? phoneNumber,
  }) async {
    try {
      late final QuerySnapshot querySnapshot;
      
      if (userId != null) {
        querySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, isEqualTo: userId)
            .limit(1)
            .get();
      } else if (phoneNumber != null) {
        querySnapshot = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
      } else {
        return const Left(AuthFailure(message: 'Either userId or phoneNumber must be provided'));
      }
      
      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }
      
      final userDoc = querySnapshot.docs.first;
      return Right(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      return Left(AuthFailure(message: 'Error getting user details: $e'));
    }
  }

  /// Handle Firebase Auth exceptions
  Failure _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthFailure(message: 'No user found with this email');
      case 'wrong-password':
        return const AuthFailure(message: 'Incorrect password');
      case 'email-already-in-use':
        return const AuthFailure(message: 'Email is already in use');
      case 'invalid-email':
        return const AuthFailure(message: 'Invalid email address');
      case 'weak-password':
        return const AuthFailure(message: 'Password is too weak');
      case 'operation-not-allowed':
        return const AuthFailure(message: 'Operation not allowed. Please contact support');
      case 'user-disabled':
        return const AuthFailure(message: 'This account has been disabled');
      case 'too-many-requests':
        return const AuthFailure(message: 'Too many unsuccessful login attempts. Please try again later');
      case 'network-request-failed':
        return const NetworkFailure(message: 'Network error. Please check your connection');
      default:
        return AuthFailure(message: 'Authentication failed: ${e.message}');
    }
  }
}
