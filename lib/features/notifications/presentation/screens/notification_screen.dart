import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_item.dart';

/// Screen to display user notifications
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationBloc _notificationBloc;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notificationBloc = sl<NotificationBloc>();
    
    // Get current user ID from auth bloc
    // This is a placeholder - in a real app, you would get this from the auth bloc
    _userId = 'current_user_id';
    
    if (_userId != null) {
      _notificationBloc.add(LoadNotificationsEvent(_userId!));
      _notificationBloc.add(LoadUnreadCountEvent(_userId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationsLoaded && _userId != null) {
                  return TextButton(
                    onPressed: () {
                      _notificationBloc.add(MarkAllNotificationsReadEvent(_userId!));
                    },
                    child: const Text(
                      'Mark All Read',
                      style: TextStyle(color: Colors.amber),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Matches'),
              Tab(text: 'Tournaments'),
              Tab(text: 'Community'),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationList(NotificationCategory.all),
            _buildNotificationList(NotificationCategory.match),
            _buildNotificationList(NotificationCategory.tournament),
            _buildNotificationList(NotificationCategory.community),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(NotificationCategory category) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is NotificationsLoaded) {
          final notifications = _filterNotifications(state.notifications, category);
          
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                _notificationBloc.add(RefreshNotificationsEvent(_userId!));
              }
            },
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () {
                    if (!notification.read) {
                      _notificationBloc.add(MarkNotificationReadEvent(notification.id));
                    }
                    _handleNotificationTap(notification);
                  },
                  onDelete: () {
                    _notificationBloc.add(DeleteNotificationEvent(notification.id));
                  },
                );
              },
            ),
          );
        } else if (state is NotificationsError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  List<NotificationEntity> _filterNotifications(
    List<NotificationEntity> notifications,
    NotificationCategory category,
  ) {
    if (category == NotificationCategory.all) {
      return notifications;
    }
    
    return notifications.where((notification) => notification.category == category).toList();
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Handle notification tap based on action and data
    switch (notification.action) {
      case NotificationAction.viewTournament:
        // Navigate to tournament details
        if (notification.data != null && notification.data!.containsKey('tournamentId')) {
          final tournamentId = notification.data!['tournamentId'];
          // Navigator.pushNamed(context, '/tournament/details', arguments: tournamentId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to tournament: $tournamentId')),
          );
        }
        break;
      case NotificationAction.viewMatch:
        // Navigate to match details
        if (notification.data != null && notification.data!.containsKey('matchId')) {
          final matchId = notification.data!['matchId'];
          // Navigator.pushNamed(context, '/match/details', arguments: matchId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to match: $matchId')),
          );
        }
        break;
      case NotificationAction.viewCommunity:
        // Navigate to community details
        if (notification.data != null && notification.data!.containsKey('communityId')) {
          final communityId = notification.data!['communityId'];
          // Navigator.pushNamed(context, '/community/details', arguments: communityId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to community: $communityId')),
          );
        }
        break;
      case NotificationAction.none:
      default:
        // No action needed
        break;
    }
  }
}