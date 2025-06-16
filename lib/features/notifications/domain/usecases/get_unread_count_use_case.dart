import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to get unread notifications count for a user
class GetUnreadCountUseCase {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  /// Execute the use case
  Future<Either<Failure, int>> call(String userId) {
    return repository.getUnreadNotificationsCount(userId);
  }
}