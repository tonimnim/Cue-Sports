import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to mark a notification as read
class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  /// Execute the use case
  Future<Either<Failure, void>> call(String notificationId) {
    return repository.markNotificationAsRead(notificationId);
  }
}