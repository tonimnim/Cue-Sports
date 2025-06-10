import 'package:firebase_auth/firebase_auth.dart';

/// Production-ready authentication service for user ID management
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get the current authenticated user's ID
  /// This is the primary method for getting user ID in the app
  String? getCurrentUserId() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return user.uid;
    }
    return null;
  }

  /// Get the current authenticated user's ID with validation
  /// Throws an exception if user is not authenticated
  String getValidatedUserId() {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('User is not authenticated or has no valid ID');
    }
    return userId;
  }

  /// Get the current authenticated user's email
  String? getCurrentUserEmail() {
    final user = _firebaseAuth.currentUser;
    return user?.email;
  }

  /// Check if a user is currently authenticated
  bool isUserAuthenticated() {
    return _firebaseAuth.currentUser != null;
  }

  /// Stream of authentication state changes
  Stream<String?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  /// Get Firebase Auth user instance (use sparingly)
  User? get currentFirebaseUser => _firebaseAuth.currentUser;
}
