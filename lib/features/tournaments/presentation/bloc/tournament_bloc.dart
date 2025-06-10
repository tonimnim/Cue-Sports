import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';
import 'tournament_event.dart';
import 'tournament_state.dart';

/// Tournament BLoC for managing tournament and match state
class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final TournamentRepository repository;
  final LoggerService logger;

  TournamentBloc({
    required this.repository,
    required this.logger,
  }) : super(TournamentState.initial()) {
    // Tournament events
    on<LoadTournamentsEvent>(_onLoadTournaments);
    on<LoadFeaturedTournamentsEvent>(_onLoadFeaturedTournaments);
    on<LoadActiveTournamentsEvent>(_onLoadActiveTournaments);
    on<LoadTournamentDetailsEvent>(_onLoadTournamentDetails);
    on<RegisterForTournamentEvent>(_onRegisterForTournament);
    on<CheckRegistrationStatusEvent>(_onCheckRegistrationStatus);
    on<SearchTournamentsEvent>(_onSearchTournaments);

    // Match events
    on<LoadPlayerMatchesEvent>(_onLoadPlayerMatches);
    on<LoadTournamentMatchesEvent>(_onLoadTournamentMatches);
    on<LoadUpcomingMatchesEvent>(_onLoadUpcomingMatches);
    on<LoadLiveMatchesEvent>(_onLoadLiveMatches);
    on<LoadMatchDetailsEvent>(_onLoadMatchDetails);
    on<SearchMatchesEvent>(_onSearchMatches);

    // Player statistics events
    on<LoadPlayerStatsEvent>(_onLoadPlayerStats);
    on<LoadTournamentLeaderboardEvent>(_onLoadTournamentLeaderboard);
    on<LoadCommunityLeaderboardEvent>(_onLoadCommunityLeaderboard);

    // UI events
    on<RefreshTournamentsEvent>(_onRefreshTournaments);
    on<RefreshMatchesEvent>(_onRefreshMatches);
    on<ClearSearchEvent>(_onClearSearch);
    on<ResetTournamentStateEvent>(_onResetState);
  }

  // Tournament event handlers
  Future<void> _onLoadTournaments(
    LoadTournamentsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingTournaments: true, clearError: true));

    final result = await repository.getTournaments(
      status: event.status,
      type: event.type,
      isFeatured: event.isFeatured,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load tournaments: ${failure.message}');
        emit(state
            .copyWithError('Failed to load tournaments: ${failure.message}'));
      },
      (tournaments) {
        emit(state.copyWith(
          tournaments: tournaments,
          isLoadingTournaments: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadFeaturedTournaments(
    LoadFeaturedTournamentsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingTournaments: true, clearError: true));

    final result = await repository.getFeaturedTournaments();

    result.fold(
      (failure) {
        logger.e('Failed to load featured tournaments: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load featured tournaments: ${failure.message}'));
      },
      (tournaments) {
        emit(state.copyWith(
          featuredTournaments: tournaments,
          isLoadingTournaments: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadActiveTournaments(
    LoadActiveTournamentsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingTournaments: true, clearError: true));

    final result = await repository.getActiveTournaments();

    result.fold(
      (failure) {
        logger.e('Failed to load active tournaments: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load active tournaments: ${failure.message}'));
      },
      (tournaments) {
        emit(state.copyWith(
          activeTournaments: tournaments,
          isLoadingTournaments: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadTournamentDetails(
    LoadTournamentDetailsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await repository.getTournamentById(event.tournamentId);

    result.fold(
      (failure) {
        logger.e('Failed to load tournament details: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load tournament details: ${failure.message}'));
      },
      (tournament) {
        emit(state.copyWith(
          selectedTournament: tournament,
          isLoading: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onRegisterForTournament(
    RegisterForTournamentEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isRegistering: true, clearError: true));

    final result = await repository.registerForTournament(
      tournamentId: event.tournamentId,
      userId: event.userId,
      communityId: event.communityId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to register for tournament: ${failure.message}');
        emit(state.copyWithError(
            'Failed to register for tournament: ${failure.message}'));
      },
      (success) {
        emit(state.copyWith(
          isRegistering: false,
          isRegistered: true,
          registrationSuccess: true,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onCheckRegistrationStatus(
    CheckRegistrationStatusEvent event,
    Emitter<TournamentState> emit,
  ) async {
    final result = await repository.isUserRegistered(
      tournamentId: event.tournamentId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to check registration status: ${failure.message}');
        // Don't emit error for this, just log it
      },
      (isRegistered) {
        emit(state.copyWith(isRegistered: isRegistered));
      },
    );
  }

  Future<void> _onSearchTournaments(
    SearchTournamentsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(
      isSearching: true,
      searchQuery: event.query,
      isSearchMode: true,
      clearError: true,
    ));

    final result = await repository.searchTournaments(
      query: event.query,
      type: event.type,
      status: event.status,
    );

    result.fold(
      (failure) {
        logger.e('Failed to search tournaments: ${failure.message}');
        emit(state
            .copyWithError('Failed to search tournaments: ${failure.message}'));
      },
      (tournaments) {
        emit(state.copyWith(
          searchResults: tournaments,
          isSearching: false,
          clearError: true,
        ));
      },
    );
  }

  // Match event handlers
  Future<void> _onLoadPlayerMatches(
    LoadPlayerMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingMatches: true, clearError: true));

    final result = await repository.getPlayerMatches(
      playerId: event.playerId,
      status: event.status,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load player matches: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load player matches: ${failure.message}'));
      },
      (matches) {
        emit(state.copyWith(
          playerMatches: matches,
          isLoadingMatches: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadTournamentMatches(
    LoadTournamentMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingMatches: true, clearError: true));

    final result = await repository.getTournamentMatches(
      tournamentId: event.tournamentId,
      status: event.status,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load tournament matches: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load tournament matches: ${failure.message}'));
      },
      (matches) {
        emit(state.copyWith(
          tournamentMatches: matches,
          isLoadingMatches: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadUpcomingMatches(
    LoadUpcomingMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingMatches: true, clearError: true));

    final result = await repository.getUpcomingMatches(
      playerId: event.playerId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load upcoming matches: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load upcoming matches: ${failure.message}'));
      },
      (matches) {
        emit(state.copyWith(
          upcomingMatches: matches,
          isLoadingMatches: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadLiveMatches(
    LoadLiveMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingMatches: true, clearError: true));

    final result = await repository.getLiveMatches();

    result.fold(
      (failure) {
        logger.e('Failed to load live matches: ${failure.message}');
        emit(state
            .copyWithError('Failed to load live matches: ${failure.message}'));
      },
      (matches) {
        emit(state.copyWith(
          liveMatches: matches,
          isLoadingMatches: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadMatchDetails(
    LoadMatchDetailsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await repository.getMatchById(event.matchId);

    result.fold(
      (failure) {
        logger.e('Failed to load match details: ${failure.message}');
        emit(state
            .copyWithError('Failed to load match details: ${failure.message}'));
      },
      (match) {
        emit(state.copyWith(
          selectedMatch: match,
          isLoading: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onSearchMatches(
    SearchMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(
      isSearching: true,
      searchQuery: event.query,
      isSearchMode: true,
      clearError: true,
    ));

    final result = await repository.searchMatches(
      query: event.query,
      tournamentId: event.tournamentId,
      status: event.status,
    );

    result.fold(
      (failure) {
        logger.e('Failed to search matches: ${failure.message}');
        emit(state
            .copyWithError('Failed to search matches: ${failure.message}'));
      },
      (matches) {
        emit(state.copyWith(
          matchSearchResults: matches,
          isSearching: false,
          clearError: true,
        ));
      },
    );
  }

  // Player statistics event handlers
  Future<void> _onLoadPlayerStats(
    LoadPlayerStatsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingStats: true, clearError: true));

    final result = await repository.getPlayerStats(
      userId: event.userId,
      tournamentId: event.tournamentId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load player stats: ${failure.message}');
        emit(state
            .copyWithError('Failed to load player stats: ${failure.message}'));
      },
      (stats) {
        emit(state.copyWith(
          playerStats: stats,
          isLoadingStats: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadTournamentLeaderboard(
    LoadTournamentLeaderboardEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingStats: true, clearError: true));

    final result = await repository.getTournamentLeaderboard(
      tournamentId: event.tournamentId,
      communityId: event.communityId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load tournament leaderboard: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load tournament leaderboard: ${failure.message}'));
      },
      (leaderboard) {
        emit(state.copyWith(
          leaderboard: leaderboard,
          isLoadingStats: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadCommunityLeaderboard(
    LoadCommunityLeaderboardEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(isLoadingStats: true, clearError: true));

    final result = await repository.getCommunityLeaderboard(
      tournamentId: event.tournamentId,
      communityId: event.communityId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load community leaderboard: ${failure.message}');
        emit(state.copyWithError(
            'Failed to load community leaderboard: ${failure.message}'));
      },
      (leaderboard) {
        emit(state.copyWith(
          communityLeaderboard: leaderboard,
          isLoadingStats: false,
          clearError: true,
        ));
      },
    );
  }

  // UI event handlers
  Future<void> _onRefreshTournaments(
    RefreshTournamentsEvent event,
    Emitter<TournamentState> emit,
  ) async {
    // Reload featured and active tournaments
    add(const LoadFeaturedTournamentsEvent());
    add(const LoadActiveTournamentsEvent());
  }

  Future<void> _onRefreshMatches(
    RefreshMatchesEvent event,
    Emitter<TournamentState> emit,
  ) async {
    // Reload live matches and upcoming matches
    add(const LoadLiveMatchesEvent());
    add(const LoadUpcomingMatchesEvent());
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(
      searchResults: [],
      matchSearchResults: [],
      searchQuery: '',
      isSearchMode: false,
      clearError: true,
    ));
  }

  Future<void> _onResetState(
    ResetTournamentStateEvent event,
    Emitter<TournamentState> emit,
  ) async {
    emit(TournamentState.initial());
  }
}
