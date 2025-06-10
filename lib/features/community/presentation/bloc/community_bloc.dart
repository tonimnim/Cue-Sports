import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../domain/community_repository.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import 'community_event.dart';
import 'community_state.dart';

/// BLoC for managing community-related state and operations
class CommunityBloc extends Bloc<CommunityBlocEvent, CommunityState> {
  final CommunityRepository _repository;

  CommunityBloc({
    required CommunityRepository repository,
  })  : _repository = repository,
        super(CommunityState.initial()) {
    on<LoadCommunitiesEvent>(_onLoadCommunities);
    on<LoadCommunityDetailsEvent>(_onLoadCommunityDetails);
    on<LoadUserCommunityEvent>(_onLoadUserCommunity);
    on<JoinCommunityEvent>(_onJoinCommunity);
    on<LeaveCommunityEvent>(_onLeaveCommunity);
    on<CheckCommunityMembershipEvent>(_onCheckCommunityMembership);
    on<SearchCommunitiesEvent>(_onSearchCommunities);
    on<ResetFiltersEvent>(_onResetFilters);
    on<LoadTopRankedCommunitiesEvent>(_onLoadTopRankedCommunities);
    on<LoadPlayerCommunityEvent>(_onLoadPlayerCommunity);
    on<LoadCommunitiesByLocationEvent>(_onLoadCommunitiesByLocation);
  }

  /// Handle LoadCommunitiesEvent
  Future<void> _onLoadCommunities(
    LoadCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _repository.getCommunities();

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
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
    emit(state.copyWithLoading());

    final result = await _repository.getCommunityById(event.communityId);

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
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
    emit(state.copyWithLoading());

    final result = await _repository.getUserCommunity(event.userId);

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (community) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        userCommunity: community,
      )),
    );
  }

  /// Handle JoinCommunityEvent
  Future<void> _onJoinCommunity(
    JoinCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      // First, optimistically update the state
      final currentCommunities = state.communities ?? [];
      final updatedCommunities = currentCommunities.map((community) {
        if (community.id == event.communityId) {
          return community.copyWith(memberCount: community.memberCount + 1);
        }
        return community;
      }).toList();

      // Find the joined community to set as user's community
      Community? joinedCommunity;
      try {
        joinedCommunity = updatedCommunities.firstWhere(
          (c) => c.id == event.communityId,
        );
      } catch (e) {
        // Community not found in updated list, try original list
        try {
          joinedCommunity = currentCommunities.firstWhere(
            (c) => c.id == event.communityId,
          );
          // Update member count for this community
          joinedCommunity = joinedCommunity.copyWith(
              memberCount: joinedCommunity.memberCount + 1);
        } catch (e2) {
          // Community not found in local lists, fetch it from backend
          print(
              '⚠️ Community ${event.communityId} not found locally, fetching from backend...');
          final result = await _repository.getCommunityById(event.communityId);
          result.fold(
            (failure) {
              print('❌ Failed to fetch community: ${failure.message}');
              // Still update state with whatever we have, don't block the UI
              emit(state.copyWith(
                status: CommunityStatus.loaded,
                communities: updatedCommunities,
                userCommunity: null, // No community found
              ));
              return;
            },
            (community) {
              joinedCommunity =
                  community.copyWith(memberCount: community.memberCount + 1);
            },
          );
        }
      }

      // Immediately update UI state (optimistic update)
      emit(state.copyWith(
        status: CommunityStatus.loaded,
        communities: updatedCommunities,
        userCommunity: joinedCommunity,
      ));

      // Then sync with backend
      final result = await _repository.joinCommunity(
        userId: event.userId,
        communityId: event.communityId,
      );

      result.fold(
        (failure) {
          // Revert state on failure
          emit(state.copyWith(
            status: CommunityStatus.loaded,
            communities: currentCommunities,
            userCommunity: null,
            errorMessage: failure.message,
          ));
        },
        (_) {
          // Backend sync successful - state is already updated
          emit(state.copyWith(status: CommunityStatus.loaded));
        },
      );
    } catch (e) {
      emit(state.copyWithError('Failed to join community: $e'));
    }
  }

  /// Handle CheckCommunityMembershipEvent
  Future<void> _onCheckCommunityMembership(
    CheckCommunityMembershipEvent event,
    Emitter<CommunityState> emit,
  ) async {
    final result = await _repository.isUserCommunityMember(
      userId: event.userId,
      communityId: event.communityId,
    );

    result.fold(
      (failure) => {}, // Silent fail for membership check
      (isMember) => emit(state.copyWith(isMember: isMember)),
    );
  }

  /// Handle LoadCommunitiesByLocationEvent
  Future<void> _onLoadCommunitiesByLocation(
    LoadCommunitiesByLocationEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _repository.getCommunitiesByLocation(event.location);

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (communities) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        filteredCommunities: communities,
        filterLocation: event.location,
      )),
    );
  }

  /// Handle LoadTopRankedCommunitiesEvent
  Future<void> _onLoadTopRankedCommunities(
    LoadTopRankedCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result =
        await _repository.getTopRankedCommunities(limit: event.limit);

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (communities) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        topCommunities: communities,
      )),
    );
  }

  /// Handle SearchCommunitiesEvent
  Future<void> _onSearchCommunities(
    SearchCommunitiesEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _repository.searchCommunities(event.query);

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (communities) => emit(state.copyWith(
        status: CommunityStatus.loaded,
        filteredCommunities: communities,
        searchQuery: event.query,
      )),
    );
  }

  /// Handle ResetFiltersEvent
  void _onResetFilters(
    ResetFiltersEvent event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(
      filteredCommunities: const [],
      searchQuery: null,
      filterLocation: null,
    ));
  }

  /// Handle LeaveCommunityEvent
  Future<void> _onLeaveCommunity(
    LeaveCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _repository.leaveCommunity(
      userId: event.userId,
      communityId: event.communityId,
    );

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (_) => emit(state.copyWithLoaded()),
    );
  }

  /// Handle LoadPlayerCommunityEvent
  Future<void> _onLoadPlayerCommunity(
    LoadPlayerCommunityEvent event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());

      final result = await _repository.getUserCommunity(event.userId);

      result.fold(
        (failure) => emit(state.copyWithError(failure.message)),
        (community) => emit(state.copyWith(
          status: CommunityStatus.loaded,
          userCommunity: community,
        )),
      );
    } catch (e) {
      emit(state.copyWithError('Failed to load player community'));
    }
  }
}
