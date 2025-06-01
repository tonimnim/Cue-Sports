import 'package:equatable/equatable.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_event.dart' as domain_event;
import '../../domain/entities/trophy.dart';

/// Base class for all community BLoC events
abstract class CommunityBlocEvent extends Equatable {
  const CommunityBlocEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load all communities
class LoadCommunitiesEvent extends CommunityBlocEvent {
  const LoadCommunitiesEvent();
}

/// Event to load communities by level
class LoadCommunitiesByLevelEvent extends CommunityBlocEvent {
  final CommunityLevel level;
  
  const LoadCommunitiesByLevelEvent(this.level);
  
  @override
  List<Object> get props => [level];
}

/// Event to load communities by location
class LoadCommunitiesByLocationEvent extends CommunityBlocEvent {
  final String location;
  
  const LoadCommunitiesByLocationEvent(this.location);
  
  @override
  List<Object> get props => [location];
}

/// Event to load a specific community by ID
class LoadCommunityDetailsEvent extends CommunityBlocEvent {
  final String communityId;
  
  const LoadCommunityDetailsEvent(this.communityId);
  
  @override
  List<Object> get props => [communityId];
}

/// Event to load the user's community
class LoadUserCommunityEvent extends CommunityBlocEvent {
  final String userId;
  
  const LoadUserCommunityEvent(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// Event to join a community
class JoinCommunityEvent extends CommunityBlocEvent {
  final String communityId;
  final String userId;
  
  const JoinCommunityEvent({
    required this.communityId,
    required this.userId,
  });
  
  @override
  List<Object> get props => [communityId, userId];
}

/// Event to check if user is member of a community
class CheckCommunityMembershipEvent extends CommunityBlocEvent {
  final String userId;
  final String communityId;
  
  const CheckCommunityMembershipEvent({
    required this.userId,
    required this.communityId,
  });
  
  @override
  List<Object?> get props => [userId, communityId];
}

/// Event to leave current community
class LeaveCommunityEvent extends CommunityBlocEvent {
  final String communityId;
  final String userId;
  
  const LeaveCommunityEvent({
    required this.communityId,
    required this.userId,
  });
  
  @override
  List<Object> get props => [communityId, userId];
}

/// Event to add trophy to community
class AddTrophyEvent extends CommunityBlocEvent {
  final String communityId;
  final String playerId;
  final String trophyName;
  final TrophyType trophyType;
  
  const AddTrophyEvent({
    required this.communityId,
    required this.playerId,
    required this.trophyName,
    required this.trophyType,
  });
  
  @override
  List<Object> get props => [communityId, playerId, trophyName, trophyType];
}

/// Event to update community points
class UpdatePointsEvent extends CommunityBlocEvent {
  final String communityId;
  final int points;
  
  const UpdatePointsEvent({
    required this.communityId,
    required this.points,
  });
  
  @override
  List<Object> get props => [communityId, points];
}

/// Event to search communities
class SearchCommunitiesEvent extends CommunityBlocEvent {
  final String query;
  
  const SearchCommunitiesEvent(this.query);
  
  @override
  List<Object> get props => [query];
}

/// Event to reset the filter and search state
class ResetFiltersEvent extends CommunityBlocEvent {
  const ResetFiltersEvent();
}

/// Event to load top ranked communities
class LoadTopRankedCommunitiesEvent extends CommunityBlocEvent {
  final int limit;
  
  const LoadTopRankedCommunitiesEvent({this.limit = 10});
  
  @override
  List<Object> get props => [limit];
}

/// Event to load followed communities
class LoadFollowedCommunitiesEvent extends CommunityBlocEvent {
  final String userId;
  
  const LoadFollowedCommunitiesEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

/// Event to load player's current community
class LoadPlayerCommunityEvent extends CommunityBlocEvent {
  final String userId;
  
  const LoadPlayerCommunityEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

/// Event to load community events
class LoadCommunityEventsEvent extends CommunityBlocEvent {
  final String communityId;

  const LoadCommunityEventsEvent(this.communityId);

  @override
  List<Object> get props => [communityId];
}

/// Event to load community posts
class LoadCommunityPostsEvent extends CommunityBlocEvent {
  final String communityId;

  const LoadCommunityPostsEvent(this.communityId);

  @override
  List<Object> get props => [communityId];
}

/// Event to create a new post
class CreatePostEvent extends CommunityBlocEvent {
  final CommunityPost post;

  const CreatePostEvent(this.post);

  @override
  List<Object?> get props => [post];
}

/// Event to create a new event
class CreateEventEvent extends CommunityBlocEvent {
  final domain_event.CommunityEvent event;

  const CreateEventEvent(this.event);

  @override
  List<Object?> get props => [event];
}

/// Event to like a post
class LikePostEvent extends CommunityBlocEvent {
  final String postId;
  final String userId;

  const LikePostEvent({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

/// Event to unlike a post
class UnlikePostEvent extends CommunityBlocEvent {
  final String postId;
  final String userId;

  const UnlikePostEvent({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

/// Event to register for an event
class RegisterForEventEvent extends CommunityBlocEvent {
  final String eventId;
  final String userId;

  const RegisterForEventEvent({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
}

/// Event to unregister from an event
class UnregisterFromEventEvent extends CommunityBlocEvent {
  final String eventId;
  final String userId;

  const UnregisterFromEventEvent({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
}

/// Event to cancel an event
class CancelEventEvent extends CommunityBlocEvent {
  final String eventId;

  const CancelEventEvent({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

/// Event to pin a post
class PinPostEvent extends CommunityBlocEvent {
  final String postId;

  const PinPostEvent({required this.postId});

  @override
  List<Object> get props => [postId];
}

/// Event to unpin a post
class UnpinPostEvent extends CommunityBlocEvent {
  final String postId;

  const UnpinPostEvent({required this.postId});

  @override
  List<Object> get props => [postId];
}