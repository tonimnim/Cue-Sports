import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/community_member.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/member_list_tile.dart';

class EventDetailsScreen extends StatelessWidget {
  final CommunityEvent event;
  final User currentUser;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (event.organizerId == currentUser.id)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-event',
                  arguments: event,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showEventOptions(context);
            },
          ),
        ],
      ),
      body: BlocListener<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state.status == CommunityStatus.loaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.status == CommunityStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Unknown error'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              if (event.coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.coverImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 16),

              // Event Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.type.toString().split('.').last.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getEventTypeColor(theme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Event Title
              Text(
                event.title,
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 16),

              // Event Details
              _buildDetailRow(
                context,
                Icons.calendar_today,
                dateFormat.format(event.startDateTime),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.access_time,
                '${timeFormat.format(event.startDateTime)} - ${timeFormat.format(event.endDateTime)}',
              ),
              if (event.hasVenue) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.location_on,
                  event.venue!,
                ),
                if (event.venueAddress != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      event.venueAddress!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Event Description
              Text(
                'Description',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // Event Status
              _buildStatusSection(context),

              const SizedBox(height: 24),

              // Participants
              Text(
                'Participants (${event.participants.length}/${event.maxParticipants})',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: event.participants.length,
                itemBuilder: (context, index) {
                  final userId = event.participants[index];
                  // TODO: Get user details from repository
                  return MemberListTile(
                    member: CommunityMember(
                      id: '$userId-${event.communityId}',
                      userId: userId,
                      communityId: event.communityId,
                      displayName: 'User $userId',
                      role: CommunityRole.member,
                      joinedAt: DateTime.now(),
                    ),
                    isAdmin: event.organizerId == userId,
                    onRemove: event.organizerId == currentUser.id
                        ? () {
                            // TODO: Implement remove participant
                          }
                        : null,
                  );
                },
              ),

              // Waitlist
              if (event.waitlist != null && event.waitlist!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Waitlist (${event.waitlist!.length})',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.waitlist!.length,
                  itemBuilder: (context, index) {
                    final userId = event.waitlist![index];
                    // TODO: Get user details from repository
                    return MemberListTile(
                      member: CommunityMember(
                        id: '$userId-${event.communityId}',
                        userId: userId,
                        communityId: event.communityId,
                        displayName: 'User $userId',
                        role: CommunityRole.member,
                        joinedAt: DateTime.now(),
                      ),
                      onRemove: event.organizerId == currentUser.id
                          ? () {
                              // TODO: Implement remove from waitlist
                            }
                          : null,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getEventStatusColor(theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getEventStatusIcon(),
            color: _getEventStatusColor(theme),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEventStatus(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _getEventStatusColor(theme),
                  ),
                ),
                if (event.isFull && !event.isUserRegistered(currentUser.id))
                  Text(
                    'You can join the waitlist',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (event.isCancelled || event.hasEnded) {
      return const SizedBox();
    }

    final isParticipant = event.isUserRegistered(currentUser.id);
    final isOnWaitlist = event.isUserOnWaitlist(currentUser.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.entryFee != null && event.entryFee! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Entry Fee: \$${event.entryFee!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: event.isFull && !isParticipant && !isOnWaitlist
                  ? () {
                      context.read<CommunityBloc>().add(
                            RegisterForEventEvent(
                              eventId: event.id,
                              userId: currentUser.id,
                            ),
                          );
                    }
                  : isParticipant || isOnWaitlist
                      ? () {
                          context.read<CommunityBloc>().add(
                                UnregisterFromEventEvent(
                                  eventId: event.id,
                                  userId: currentUser.id,
                                ),
                              );
                        }
                      : null,
              child: Text(
                isParticipant
                    ? 'Cancel Registration'
                    : isOnWaitlist
                        ? 'Leave Waitlist'
                        : event.isFull
                            ? 'Join Waitlist'
                            : 'Register',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventOptions(BuildContext context) {
    final isOrganizer = event.organizerId == currentUser.id;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOrganizer && !event.isCancelled) ...[
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel Event'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelConfirmation(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete Event'),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Event'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Event'),
          content: const Text(
            'Are you sure you want to cancel this event? All participants will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CommunityBloc>().add(
                      CancelEventEvent(eventId: event.id),
                    );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete event
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEventTypeColor(ThemeData theme) {
    switch (event.type) {
      case EventType.tournament:
        return theme.colorScheme.primary;
      case EventType.practice:
        return theme.colorScheme.secondary;
      case EventType.meetup:
        return theme.colorScheme.tertiary;
      case EventType.training:
        return theme.colorScheme.error;
      case EventType.workshop:
        return theme.colorScheme.secondary;
      case EventType.competition:
        return theme.colorScheme.primary;
      case EventType.other:
        return theme.colorScheme.primary;
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
} 