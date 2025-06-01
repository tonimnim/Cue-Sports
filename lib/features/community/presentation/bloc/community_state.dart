import 'package:equatable/equatable.dart';

import '../../domain/entities/community.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_member.dart';

/// Status of community operations
enum CommunityStatus {
  /// Initial state
  initial,
  
  /// Loading data
  loading,
  
  /// Data loaded successfully
  loaded,
  
  /// Error occurred
  error,
}

/// State for community feature
class CommunityState extends Equatable {
  final CommunityStatus status;
  final List<Community>? communities;
  final Community? selectedCommunity;
  final Community? userCommunity;
  final List<Community>? filteredCommunities;
  final List<Community>? topCommunities;
  final List<CommunityEvent>? events;
  final List<CommunityPost>? posts;
  final List<CommunityMember>? members;
  final String? errorMessage;
  final String? searchQuery;
  final String? filterLocation;
  final bool? isMember;

  const CommunityState({
    required this.status,
    this.communities,
    this.selectedCommunity,
    this.userCommunity,
    this.filteredCommunities,
    this.topCommunities,
    this.events,
    this.posts,
    this.members,
    this.errorMessage,
    this.searchQuery,
    this.filterLocation,
    this.isMember,
  });

  factory CommunityState.initial() {
    return const CommunityState(
      status: CommunityStatus.initial,
    );
  }

  CommunityState copyWith({
    CommunityStatus? status,
    List<Community>? communities,
    Community? selectedCommunity,
    Community? userCommunity,
    List<Community>? filteredCommunities,
    List<Community>? topCommunities,
    List<CommunityEvent>? events,
    List<CommunityPost>? posts,
    List<CommunityMember>? members,
    String? errorMessage,
    String? searchQuery,
    String? filterLocation,
    bool? isMember,
  }) {
    return CommunityState(
      status: status ?? this.status,
      communities: communities ?? this.communities,
      selectedCommunity: selectedCommunity ?? this.selectedCommunity,
      userCommunity: userCommunity ?? this.userCommunity,
      filteredCommunities: filteredCommunities ?? this.filteredCommunities,
      topCommunities: topCommunities ?? this.topCommunities,
      events: events ?? this.events,
      posts: posts ?? this.posts,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterLocation: filterLocation ?? this.filterLocation,
      isMember: isMember ?? this.isMember,
    );
  }

  // Helper methods for common state transitions
  CommunityState copyWithLoading() {
    return copyWith(status: CommunityStatus.loading);
  }

  CommunityState copyWithError(String message) {
    return copyWith(
      status: CommunityStatus.error,
      errorMessage: message,
    );
  }

  CommunityState copyWithLoaded() {
    return copyWith(status: CommunityStatus.loaded);
  }

  @override
  List<Object?> get props => [
        status,
        communities,
        selectedCommunity,
        userCommunity,
        filteredCommunities,
        topCommunities,
        events,
        posts,
        members,
        errorMessage,
        searchQuery,
        filterLocation,
        isMember,
      ];
}

class CommunityInitial extends CommunityState {
  const CommunityInitial() : super(status: CommunityStatus.initial);
}

class CommunityLoading extends CommunityState {
  const CommunityLoading() : super(status: CommunityStatus.loading);
}

class CommunityError extends CommunityState {
  const CommunityError({required String message})
      : super(status: CommunityStatus.error, errorMessage: message);
}

class CommunityLoaded extends CommunityState {
  const CommunityLoaded({
    required List<Community> communities,
    required List<CommunityEvent> events,
    required List<CommunityPost> posts,
  }) : super(
          status: CommunityStatus.loaded,
          communities: communities,
          events: events,
          posts: posts,
        );
}

class CommunityActionSuccess extends CommunityState {
  final String message;

  const CommunityActionSuccess({required this.message})
      : super(status: CommunityStatus.loaded);

  @override
  List<Object?> get props => [...super.props, message];
}

class CommunityActionFailure extends CommunityState {
  final String message;

  const CommunityActionFailure({required this.message})
      : super(status: CommunityStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [...super.props, message];
}