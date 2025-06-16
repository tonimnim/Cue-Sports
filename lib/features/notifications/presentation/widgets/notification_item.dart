import 'package:flutter/material.dart';

import '../../domain/entities/notification.dart';

/// Widget to display a single notification item
class NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: notification.read ? Colors.transparent : Colors.green.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getNotificationTitle(),
                          style: TextStyle(
                            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.read ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (notification.action != NotificationAction.none)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildActionButton(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.category) {
      case NotificationCategory.tournament:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationCategory.match:
        iconData = Icons.sports_esports;
        iconColor = Colors.blue;
        break;
      case NotificationCategory.community:
        iconData = Icons.people;
        iconColor = Colors.green;
        break;
      case NotificationCategory.system:
        iconData = Icons.notifications;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24.0,
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    
    switch (notification.action) {
      case NotificationAction.viewTournament:
        buttonText = 'Check In Now';
        break;
      case NotificationAction.viewMatch:
        buttonText = 'Accept Challenge';
        break;
      case NotificationAction.viewCommunity:
        buttonText = 'Register Now';
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        textStyle: const TextStyle(fontSize: 14.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(buttonText),
          const SizedBox(width: 4.0),
          const Icon(Icons.arrow_forward, size: 16.0),
        ],
      ),
    );
  }

  String _getNotificationTitle() {
    switch (notification.category) {
      case NotificationCategory.tournament:
        return 'Tournament ${notification.isHighPriority ? 'Alert' : 'Update'}';
      case NotificationCategory.match:
        return 'Match Challenge';
      case NotificationCategory.community:
        return 'Community Update';
      case NotificationCategory.system:
        return 'System Notification';
      default:
        return 'Notification';
    }
  }
}