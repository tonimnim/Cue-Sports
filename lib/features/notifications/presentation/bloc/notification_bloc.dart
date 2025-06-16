import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/usecases/delete_notification_use_case.dart';
import '../../domain/usecases/get_notifications_use_case.dart';
import '../../domain/usecases/get_unread_count_use_case.dart';
import '../../domain/usecases/mark_all_read_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLoC for managing notification state
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllReadUseCase markAllReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final LoggerService logger;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllReadUseCase,
    required this.deleteNotificationUseCase,
    required this.logger,
  }) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllNotificationsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<LoadUnreadCountEvent>(_onLoadUnreadCount);
  }

  /// Handle LoadNotificationsEvent
  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Loading notifications for user: ${event.userId}');
    emit(NotificationsLoading());

    final result = await getNotificationsUseCase(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to load notifications: ${failure.message}');
        emit(NotificationsError(failure.message));
      },
      (notifications) {
        logger.i('Loaded ${notifications.length} notifications');
        emit(NotificationsLoaded(notifications));
      },
    );
  }

  /// Handle RefreshNotificationsEvent
  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Refreshing notifications for user: ${event.userId}');

    final result = await getNotificationsUseCase(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to refresh notifications: ${failure.message}');
        emit(NotificationsError(failure.message));
      },
      (notifications) {
        logger.i('Refreshed ${notifications.length} notifications');
        emit(NotificationsLoaded(notifications));
      },
    );
  }

  /// Handle MarkNotificationReadEvent
  Future<void> _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Marking notification as read: ${event.notificationId}');

    final result = await markNotificationReadUseCase(event.notificationId);

    result.fold(
      (failure) {
        logger.e('Failed to mark notification as read: ${failure.message}');
        emit(NotificationsError(failure.message));
      },
      (_) {
        logger.i('Notification marked as read');
        emit(const NotificationActionSuccess('Notification marked as read'));
        
        // If we have a loaded state with notifications, update it
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedNotifications = currentState.notifications.map((notification) {
            if (notification.id == event.notificationId) {
              return notification.copyWith(read: true);
            }
            return notification;
          }).toList();
          
          emit(NotificationsLoaded(updatedNotifications));
        }
      },
    );
  }

  /// Handle MarkAllNotificationsReadEvent
  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Marking all notifications as read for user: ${event.userId}');

    final result = await markAllReadUseCase(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to mark all notifications as read: ${failure.message}');
        emit(NotificationsError(failure.message));
      },
      (_) {
        logger.i('All notifications marked as read');
        emit(const NotificationActionSuccess('All notifications marked as read'));
        
        // If we have a loaded state with notifications, update it
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedNotifications = currentState.notifications.map((notification) {
            return notification.copyWith(read: true);
          }).toList();
          
          emit(NotificationsLoaded(updatedNotifications));
        }
        
        // Update unread count
        emit(const UnreadCountLoaded(0));
      },
    );
  }

  /// Handle DeleteNotificationEvent
  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Deleting notification: ${event.notificationId}');

    final result = await deleteNotificationUseCase(event.notificationId);

    result.fold(
      (failure) {
        logger.e('Failed to delete notification: ${failure.message}');
        emit(NotificationsError(failure.message));
      },
      (_) {
        logger.i('Notification deleted');
        emit(const NotificationActionSuccess('Notification deleted'));
        
        // If we have a loaded state with notifications, update it
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedNotifications = currentState.notifications
              .where((notification) => notification.id != event.notificationId)
              .toList();
          
          emit(NotificationsLoaded(updatedNotifications));
        }
      },
    );
  }

  /// Handle LoadUnreadCountEvent
  Future<void> _onLoadUnreadCount(
    LoadUnreadCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Loading unread count for user: ${event.userId}');

    final result = await getUnreadCountUseCase(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to load unread count: ${failure.message}');
        // Don't emit error state here to avoid disrupting the UI
        // Just log the error
      },
      (count) {
        logger.i('Loaded unread count: $count');
        emit(UnreadCountLoaded(count));
      },
    );
  }
}