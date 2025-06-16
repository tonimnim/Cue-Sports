import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/services/logger_service.dart';
import '../domain/entities/notification.dart';
import '../domain/repositories/notification_repository.dart';
import 'notification_remote_data_source.dart';

/// Implementation of the NotificationRepository interface
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final notifications = await remoteDataSource.getNotifications(userId);
        return Right(notifications);
      } on ServerException catch (e) {
        logger.e('Server exception when getting notifications: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected error when getting notifications: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      logger.e('No internet connection when getting notifications');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationsCount(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadCount(userId);
        return Right(count);
      } on ServerException catch (e) {
        logger.e('Server exception when getting unread count: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected error when getting unread count: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      logger.e('No internet connection when getting unread count');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markNotificationAsRead(notificationId);
        return const Right(null);
      } on ServerException catch (e) {
        logger.e('Server exception when marking notification as read: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        logger.e('Not found exception when marking notification as read: ${e.message}');
        return Left(NotFoundFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected error when marking notification as read: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      logger.e('No internet connection when marking notification as read');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllNotificationsAsRead(userId);
        return const Right(null);
      } on ServerException catch (e) {
        logger.e('Server exception when marking all notifications as read: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected error when marking all notifications as read: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      logger.e('No internet connection when marking all notifications as read');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotification(notificationId);
        return const Right(null);
      } on ServerException catch (e) {
        logger.e('Server exception when deleting notification: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        logger.e('Not found exception when deleting notification: ${e.message}');
        return Left(NotFoundFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected error when deleting notification: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      logger.e('No internet connection when deleting notification');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}