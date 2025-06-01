/// Base class for all application exceptions
class AppException implements Exception {
  final String message;

  const AppException([this.message = 'An error occurred']);

  @override
  String toString() => message;
}

/// Exception thrown when there is an error with the server
class ServerException extends AppException {
  const ServerException([String message = 'A server error occurred']) : super(message);
}

/// Exception thrown when there is an error with the cache
class CacheException extends AppException {
  const CacheException([String message = 'A cache error occurred']) : super(message);
}

/// Exception thrown when there is an error with authentication
class AuthException extends AppException {
  const AuthException([String message = 'An authentication error occurred']) : super(message);
}

/// Exception thrown when there is an error with network connectivity
class NetworkException extends AppException {
  const NetworkException([String message = 'A network error occurred']) : super(message);
}

/// Exception thrown when there is an error with validation
class ValidationException extends AppException {
  const ValidationException([String message = 'A validation error occurred']) : super(message);
}

/// Exception thrown when there is an error with permissions
class PermissionException extends AppException {
  const PermissionException([String message = 'A permission error occurred']) : super(message);
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found']) : super(message);
}

/// Exception thrown when there is a conflict
class ConflictException extends AppException {
  const ConflictException([String message = 'A conflict occurred']) : super(message);
}

/// Exception thrown when there is a timeout
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Operation timed out']) : super(message);
}

/// Exception thrown when there is an error with the database
class DatabaseException extends AppException {
  const DatabaseException([String message = 'A database error occurred']) : super(message);
}

/// Exception thrown when payment operations fail
class PaymentException extends AppException {
  PaymentException([String message = 'Payment error occurred'])
      : super(message);
}
