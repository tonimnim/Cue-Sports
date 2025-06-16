import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

/// Use case to get all notifications for a user
class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  /// Execute the use case
  Future<Either<Failure, List<NotificationEntity>>> call(String userId) {
    return repository.getNotifications(userId);
  }
}