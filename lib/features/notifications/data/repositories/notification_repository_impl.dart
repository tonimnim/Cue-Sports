import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final notifications = await remoteDataSource.getNotifications(userId);
        return Right(notifications);
      } catch (e) {
        return Left(ServerFailure(
            message: 'Failed to fetch notifications: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure(message: 'No internet connection available'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationsCount(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final count =
            await remoteDataSource.getUnreadNotificationsCount(userId);
        return Right(count);
      } catch (e) {
        return Left(ServerFailure(
            message: 'Failed to fetch unread count: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure(message: 'No internet connection available'));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(
      String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markNotificationAsRead(notificationId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(
            message: 'Failed to mark notification as read: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure(message: 'No internet connection available'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllNotificationsAsRead(userId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(
            message:
                'Failed to mark all notifications as read: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure(message: 'No internet connection available'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotification(notificationId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(
            message: 'Failed to delete notification: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure(message: 'No internet connection available'));
    }
  }
}