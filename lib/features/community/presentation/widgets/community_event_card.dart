import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/community_event.dart';

class CommunityEventCard extends StatelessWidget {
  final CommunityEvent event;
  final VoidCallback? onTap;

  const CommunityEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image/Banner
            if (event.coverImageUrl != null)
              Image.network(
                event.coverImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        _getEventTypeIcon(),
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 150,
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    _getEventTypeIcon(),
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.type.toString().split('.').last.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Event Title
                  Text(
                    event.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Event Date & Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(event.startDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(event.startDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Event Location
                  if (event.hasVenue) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.venue!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Event Status
                  Row(
                    children: [
                      Icon(
                        _getEventStatusIcon(),
                        size: 16,
                        color: _getEventStatusColor(theme),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getEventStatus(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getEventStatusColor(theme),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${event.participants.length}/${event.maxParticipants} participants',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),

                  // Entry Fee
                  if (event.entryFee != null && event.entryFee! > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Entry Fee: \$${event.entryFee!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventTypeIcon() {
    switch (event.type) {
      case EventType.tournament:
        return Icons.emoji_events;
      case EventType.practice:
        return Icons.sports;
      case EventType.meetup:
        return Icons.groups;
      case EventType.training:
        return Icons.school;
      case EventType.workshop:
        return Icons.build;
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.other:
        return Icons.event;
    }
  }

  IconData _getEventStatusIcon() {
    if (event.isCancelled) return Icons.cancel;
    if (event.hasEnded) return Icons.event_busy;
    if (event.isOngoing) return Icons.event_available;
    if (event.isFull) return Icons.event_busy;
    return Icons.event_available;
  }

  Color _getEventStatusColor(ThemeData theme) {
    if (event.isCancelled) return theme.colorScheme.error;
    if (event.hasEnded) return theme.colorScheme.error;
    if (event.isOngoing) return theme.colorScheme.primary;
    if (event.isFull) return theme.colorScheme.error;
    return theme.colorScheme.primary;
  }

  String _getEventStatus() {
    if (event.isCancelled) return 'Cancelled';
    if (event.hasEnded) return 'Ended';
    if (event.isOngoing) return 'Ongoing';
    if (event.isFull) return 'Full';
    return 'Upcoming';
  }

  Color _getEventTypeColor(BuildContext context) {
    switch (event.type) {
      case EventType.tournament:
        return Theme.of(context).colorScheme.primary;
      case EventType.practice:
        return Theme.of(context).colorScheme.secondary;
      case EventType.meetup:
        return Theme.of(context).colorScheme.tertiary;
      case EventType.training:
        return Theme.of(context).colorScheme.error;
      case EventType.workshop:
        return Theme.of(context).colorScheme.secondary;
      case EventType.competition:
        return Theme.of(context).colorScheme.primary;
      case EventType.other:
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
} 