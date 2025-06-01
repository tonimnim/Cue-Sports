import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Represents a failure that occurs when server operations fail
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Represents a failure that occurs when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Represents a failure that occurs when network operations fail
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Represents a failure that occurs when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Represents a failure that occurs when authentication fails
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Represents a failure that occurs when permissions are insufficient
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
