import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to mark all notifications as read for a user
class MarkAllReadUseCase {
  final NotificationRepository repository;

  MarkAllReadUseCase(this.repository);

  /// Execute the use case
  Future<Either<Failure, void>> call(String userId) {
    return repository.markAllNotificationsAsRead(userId);
  }
}