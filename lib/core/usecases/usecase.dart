import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Abstract class for a Use Case in Clean Architecture
///
/// Type parameters:
/// * [Type] - The return type of the use case
/// * [Params] - The parameters required by the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case with the provided parameters
  ///
  /// Returns an [Either] with either:
  /// - a [Failure] if the use case fails, or
  /// - a [Type] if the use case succeeds
  Future<Either<Failure, Type>> call(Params params);
}

/// No parameters needed for use cases
class NoParams {
  const NoParams();
}
