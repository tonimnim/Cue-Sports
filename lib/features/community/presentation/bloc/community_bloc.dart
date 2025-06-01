import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/usecases/usecase.dart';

import '../../domain/entities/community.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/community_repository.dart';
import '../../domain/use_cases/check_community_membership_use_case.dart';
import '../../domain/use_cases/get_communities_by_location_use_case.dart';
import '../../domain/use_cases/get_communities_use_case.dart';
import '../../domain/use_cases/get_community_details_use_case.dart';
import '../../domain/use_cases/get_top_ranked_communities_use_case.dart';
import '../../domain/use_cases/get_user_community_use_case.dart';
import '../../domain/use_cases/join_community_use_case.dart';
import '../../domain/use_cases/search_communities_use_case.dart';
import '../../domain/use_cases/get_community_events_use_case.dart';
import '../../domain/use_cases/get_community_posts_use_case.dart';
import '../../domain/use_cases/leave_community_use_case.dart';
import '../../domain/use_cases/register_for_event_use_case.dart';
import '../../domain/use_cases/unregister_from_event_use_case.dart';

// Import the event and state files
import 'community_event.dart';
import 'community_state.dart';

/// BLoC for managing community feature state
class CommunityBloc extends Bloc<CommunityBlocEvent, CommunityState> {
  final LoggerService logger;
  final GetCommunitiesUseCase getCommunitiesUseCase;
  final GetCommunityDetailsUseCase getCommunityDetailsUseCase;
  final GetUserCommunityUseCase getUserCommunityUseCase;
  final JoinCommunityUseCase joinCommunityUseCase;
  final CheckCommunityMembershipUseCase checkMembershipUseCase;
  final GetCommunitiesByLocationUseCase getCommunitiesByLocationUseCase;
  final GetTopRankedCommunitiesUseCase getTopRankedCommunitiesUseCase;
  final SearchCommunitiesUseCase searchCommunitiesUseCase;
  final CommunityRepository _repository;
  final GetCommunityEventsUseCase getCommunityEventsUseCase;
  final GetCommunityPostsUseCase getCommunityPostsUseCase;
  final LeaveCommunityUseCase leaveCommunityUseCase;
  final RegisterForEventUseCase registerForEventUseCase;
  final UnregisterFromEventUseCase unregisterFromEventUseCase;

  CommunityBloc({
    required this.logger,
    required this.getCommunitiesUseCase,
    required this.getCommunityDetailsUseCase,
    required this.getUserCommunityUseCase,
    required this.joinCommunityUseCase,
    required this.checkMembershipUseCase,
    required this.getCommunitiesByLocationUseCase,
    required this.getTopRankedCommunitiesUseCase,
    required this.searchCommunitiesUseCase,
    required this.getCommunityEventsUseCase,
    required this.getCommunityPostsUseCase,
    required this.leaveCommunityUseCase,
    required this.registerForEventUseCase,
    required this.unregisterFromEventUseCase,
    required CommunityRepository repository,
  }) : _repository = repository,
      super(CommunityState.initial()) {
    on<LoadCommunitiesEvent>(_onLoadCommunities);
    on<LoadCommunityDetailsEvent>(_onLoadCommunityDetails);
    on<LoadUserCommunityEvent>(_onLoadUserCommunity);
    on<JoinCommunityEvent>(_onJoinCommunity);
    on<CheckCommunityMembershipEvent>(_onCheckMembership);
    on<LoadCommunitiesByLocationEvent>(_onLoadCommunitiesByLocation);
    on<LoadTopRankedCommunitiesEvent>(_onLoadTopRankedCommunities);
    on<SearchCommunitiesEvent>(_onSearchCommunities);
    on<ResetFiltersEvent>(_onResetFilters);
    on<LoadCommunityEventsEvent>(_onLoadCommunityEvents);
    on<LoadCommunityPostsEvent>(_onLoadCommunityPosts);
    on<LeaveCommunityEvent>(_onLeaveCommunity);
    on<CreatePostEvent>(_onCreatePost);
    on<CreateEventEvent>(_onCreateEvent);
    on<LikePostEvent>(_onLikePost);
    on<UnlikePostEvent>(_onUnlikePost);
    on<PinPostEvent>(_onPinPost);
    on<UnpinPostEvent>(_onUnpinPost);
    on<RegisterForEventEvent>(_onRegisterForEvent);
    on<UnregisterFromEventEvent>(_onUnregisterFromEvent);
    on<CancelEventEvent>(_onCancelEvent);
  }

  /// Handle LoadCommunitiesEvent
  Future<void> _onLoadCommunities(
    LoadCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await getCommunitiesUseCase(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (communities) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        communities: communities,
      )),
    );
  }

  /// Handle LoadCommunityDetailsEvent
  Future<void> _onLoadCommunityDetails(
    LoadCommunityDetailsEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await getCommunityDetailsUseCase(CommunityDetailsParams(
      communityId: event.communityId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (community) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        selectedCommunity: community,
      )),
    );
  }

  /// Handle LoadUserCommunityEvent
  Future<void> _onLoadUserCommunity(
    LoadUserCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    logger.i('Loading user community for: ${event.userId}');
    emit(state.copyWithLoading());

    final result = await getUserCommunityUseCase(
      UserCommunityParams(userId: event.userId),
    );

    result.fold(
      (failure) {
        logger.e('Failed to load user community', failure);
        emit(state.copyWithError(failure.message));
      },
      (community) {
        logger.i('Loaded user community: ${community?.name ?? "None"}');
        emit(state.copyWith(
          status: CommunityStatus.loaded,
          userCommunity: community,
        ));
      },
    );
  }

  /// Handle JoinCommunityEvent
  Future<void> _onJoinCommunity(
    JoinCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await joinCommunityUseCase(JoinCommunityParams(
      communityId: event.communityId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: CommunityStatus.loaded,
      )),
    );
  }

  /// Handle CheckCommunityMembershipEvent
  Future<void> _onCheckMembership(
    CheckCommunityMembershipEvent event,
    Emitter<CommunityState> emit,
  ) async {
    logger.i('Checking membership for user ${event.userId} in community ${event.communityId}');
    // No loading state here to avoid UI flicker for this quick check

    final result = await checkMembershipUseCase(
      MembershipParams(
        userId: event.userId,
        communityId: event.communityId,
      ),
    );

    result.fold(
      (failure) {
        logger.e('Failed to check community membership', failure);
        // Don't change to error state, just log the error
      },
      (isMember) {
        logger.i('User is${isMember ? "" : " not"} a member of the community');
        emit(state.copyWith(isMember: isMember));
      },
    );
  }

  /// Handle LoadCommunitiesByLocationEvent
  Future<void> _onLoadCommunitiesByLocation(
    LoadCommunitiesByLocationEvent event,
    Emitter<CommunityState> emit,
  ) async {
    logger.i('Loading communities by location: ${event.location}');
    emit(state.copyWithLoading());

    final result = await getCommunitiesByLocationUseCase(
      LocationParams(location: event.location),
    );

    result.fold(
      (failure) {
        logger.e('Failed to load communities by location', failure);
        emit(state.copyWithError(failure.message));
      },
      (communities) {
        logger.i('Loaded ${communities.length} communities for location ${event.location}');
        emit(state.copyWith(
          status: CommunityStatus.loaded,
          filteredCommunities: communities,
          filterLocation: event.location,
        ));
      },
    );
  }

  /// Handle LoadTopRankedCommunitiesEvent
  Future<void> _onLoadTopRankedCommunities(
    LoadTopRankedCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    logger.i('Loading top ${event.limit} ranked communities');
    emit(state.copyWithLoading());

    final result = await getTopRankedCommunitiesUseCase(
      RankingParams(limit: event.limit),
    );

    result.fold(
      (failure) {
        logger.e('Failed to load top ranked communities', failure);
        emit(state.copyWithError(failure.message));
      },
      (communities) {
        logger.i('Loaded ${communities.length} top ranked communities');
        emit(state.copyWith(
          status: CommunityStatus.loaded,
          topCommunities: communities,
        ));
      },
    );
  }

  /// Handle SearchCommunitiesEvent
  Future<void> _onSearchCommunities(
    SearchCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    logger.i('Searching communities with query: "${event.query}"');
    emit(state.copyWithLoading());

    final result = await searchCommunitiesUseCase(
      SearchParams(query: event.query),
    );

    result.fold(
      (failure) {
        logger.e('Failed to search communities', failure);
        emit(state.copyWithError(failure.message));
      },
      (communities) {
        logger.i('Found ${communities.length} communities matching "${event.query}"');
        emit(state.copyWith(
          status: CommunityStatus.loaded,
          filteredCommunities: communities,
          searchQuery: event.query,
        ));
      },
    );
  }

  /// Handle ResetFiltersEvent
  void _onResetFilters(
    ResetFiltersEvent event,
    Emitter<CommunityState> emit,
  ) {
    logger.i('Resetting all filters and search');
    emit(state.copyWith(
      filteredCommunities: const [],
      searchQuery: null,
      filterLocation: null,
    ));
  }

  Future<void> _onLoadCommunityEvents(
    LoadCommunityEventsEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await getCommunityEventsUseCase(GetCommunityEventsParams(
      communityId: event.communityId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (events) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        events: events,
      )),
    );
  }

  Future<void> _onLoadCommunityPosts(
    LoadCommunityPostsEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await getCommunityPostsUseCase(GetCommunityPostsParams(
      communityId: event.communityId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (posts) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        posts: posts,
      )),
    );
  }

  Future<void> _onLeaveCommunity(
    LeaveCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await leaveCommunityUseCase(LeaveCommunityParams(
      communityId: event.communityId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: CommunityStatus.loaded,
      )),
    );
  }

  Future<void> _onCreatePost(
    CreatePostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.createPost(event.post);
      result.fold(
        (failure) => emit(CommunityError(message: failure.message)),
        (_) {
          emit(const CommunityActionSuccess(message: 'Post created successfully'));
          add(LoadCommunityPostsEvent(event.post.communityId));
        },
      );
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.createEvent(event.event);
      result.fold(
        (failure) => emit(CommunityError(message: failure.message)),
        (_) {
          emit(const CommunityActionSuccess(message: 'Event created successfully'));
          add(LoadCommunityEventsEvent(event.event.communityId));
        },
      );
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.likePost(event.postId, event.userId);
      result.fold(
        (failure) => emit(CommunityError(message: failure.message)),
        (_) {
          if (state is CommunityLoaded) {
            final currentState = state as CommunityLoaded;
            final currentPosts = currentState.posts ?? [];
            final updatedPosts = currentPosts.map((post) {
              if (post.id == event.postId) {
                return post.copyWith(
                  likes: [...post.likes, event.userId],
                );
              }
              return post;
            }).toList();
            emit(currentState.copyWith(posts: updatedPosts));
          }
        },
      );
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onUnlikePost(
    UnlikePostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.unlikePost(event.postId, event.userId);
      result.fold(
        (failure) => emit(CommunityError(message: failure.message)),
        (_) {
          if (state is CommunityLoaded) {
            final currentState = state as CommunityLoaded;
            final currentPosts = currentState.posts ?? [];
            final updatedPosts = currentPosts.map((post) {
              if (post.id == event.postId) {
                return post.copyWith(
                  likes: post.likes.where((id) => id != event.userId).toList(),
                );
              }
              return post;
            }).toList();
            emit(currentState.copyWith(posts: updatedPosts));
          }
        },
      );
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onRegisterForEvent(
    RegisterForEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await registerForEventUseCase(RegisterForEventParams(
      eventId: event.eventId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final currentEvents = state.events ?? [];
        final updatedEvents = currentEvents.map((e) {
          if (e.id == event.eventId) {
            return e.copyWith(
              participants: [...e.participants, event.userId],
            );
          }
          return e;
        }).toList();

        emit(state.copyWith(
          status: CommunityStatus.loaded,
          events: updatedEvents,
        ));
      },
    );
  }

  Future<void> _onUnregisterFromEvent(
    UnregisterFromEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    final result = await unregisterFromEventUseCase(UnregisterFromEventParams(
      eventId: event.eventId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final currentEvents = state.events ?? [];
        final updatedEvents = currentEvents.map((e) {
          if (e.id == event.eventId) {
            return e.copyWith(
              participants: e.participants.where((id) => id != event.userId).toList(),
            );
          }
          return e;
        }).toList();

        emit(state.copyWith(
          status: CommunityStatus.loaded,
          events: updatedEvents,
        ));
      },
    );
  }

  Future<void> _onPinPost(
    PinPostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.pinPost(event.postId);
      result.fold(
        (failure) => emit(state.copyWith(
          status: CommunityStatus.error,
          errorMessage: failure.message,
        )),
        (_) => emit(state.copyWith(
          status: CommunityStatus.loaded,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUnpinPost(
    UnpinPostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.unpinPost(event.postId);
      result.fold(
        (failure) => emit(state.copyWith(
          status: CommunityStatus.error,
          errorMessage: failure.message,
        )),
        (_) => emit(state.copyWith(
          status: CommunityStatus.loaded,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCancelEvent(
    CancelEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final result = await _repository.cancelEvent(event.eventId);
      result.fold(
        (failure) => emit(state.copyWith(
          status: CommunityStatus.error,
          errorMessage: failure.message,
        )),
        (_) => emit(state.copyWith(
          status: CommunityStatus.loaded,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}