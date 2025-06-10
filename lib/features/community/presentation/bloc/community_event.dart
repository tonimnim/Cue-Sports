import 'package:equatable/equatable.dart';
import '../../domain/entities/community.dart';

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

/// Event to join a community (for players)
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

/// Event to leave current community (for players)
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

/// Event to load player's current community
class LoadPlayerCommunityEvent extends CommunityBlocEvent {
  final String userId;

  const LoadPlayerCommunityEvent(this.userId);

  @override
  List<Object> get props => [userId];
}
