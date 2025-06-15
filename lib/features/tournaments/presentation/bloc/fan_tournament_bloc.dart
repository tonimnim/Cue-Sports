import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';

/// Fan-specific tournament events
abstract class FanTournamentEvent {}

class LoadFanTournamentDataEvent extends FanTournamentEvent {
  final String fanId;
  LoadFanTournamentDataEvent(this.fanId);
}

class FollowTournamentEvent extends FanTournamentEvent {
  final String tournamentId;
  final String fanId;

  FollowTournamentEvent({
    required this.tournamentId,
    required this.fanId,
  });
}

class UnfollowTournamentEvent extends FanTournamentEvent {
  final String tournamentId;
  final String fanId;

  UnfollowTournamentEvent({
    required this.tournamentId,
    required this.fanId,
  });
}

class AddToFavoritesEvent extends FanTournamentEvent {
  final String tournamentId;
  final String fanId;

  AddToFavoritesEvent({
    required this.tournamentId,
    required this.fanId,
  });
}

/// Fan-specific tournament state
class FanTournamentState {
  final List<Tournament> followedTournaments;
  final List<Tournament> favoriteTournaments;
  final List<Match> liveMatches;
  final Map<String, int> liveViewerCounts;
  final bool isFollowing;
  final bool isLoading;
  final String? errorMessage;

  const FanTournamentState({
    this.followedTournaments = const [],
    this.favoriteTournaments = const [],
    this.liveMatches = const [],
    this.liveViewerCounts = const {},
    this.isFollowing = false,
    this.isLoading = false,
    this.errorMessage,
  });

  FanTournamentState copyWith({
    List<Tournament>? followedTournaments,
    List<Tournament>? favoriteTournaments,
    List<Match>? liveMatches,
    Map<String, int>? liveViewerCounts,
    bool? isFollowing,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FanTournamentState(
      followedTournaments: followedTournaments ?? this.followedTournaments,
      favoriteTournaments: favoriteTournaments ?? this.favoriteTournaments,
      liveMatches: liveMatches ?? this.liveMatches,
      liveViewerCounts: liveViewerCounts ?? this.liveViewerCounts,
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if fan is following a tournament
  bool isFollowingTournament(String tournamentId) {
    return followedTournaments.any((t) => t.id == tournamentId);
  }

  /// Check if tournament is in favorites
  bool isFavoriteTournament(String tournamentId) {
    return favoriteTournaments.any((t) => t.id == tournamentId);
  }
}

/// BLoC for fan-specific tournament functionality
class FanTournamentBloc extends Bloc<FanTournamentEvent, FanTournamentState> {
  final TournamentRepository repository;
  final LoggerService logger;

  FanTournamentBloc({
    required this.repository,
    required this.logger,
  }) : super(const FanTournamentState()) {
    on<LoadFanTournamentDataEvent>(_onLoadFanData);
    on<FollowTournamentEvent>(_onFollowTournament);
    on<UnfollowTournamentEvent>(_onUnfollowTournament);
    on<AddToFavoritesEvent>(_onAddToFavorites);
  }

  Future<void> _onLoadFanData(
    LoadFanTournamentDataEvent event,
    Emitter<FanTournamentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Load fan-specific data
      final liveMatchesResult = await repository.getLiveMatches();
      final liveMatches = liveMatchesResult.fold((l) => <Match>[], (r) => r);

      // TODO: Load followed tournaments from fan preferences
      // TODO: Load live viewer counts from real-time database

      emit(state.copyWith(
        liveMatches: liveMatches,
        isLoading: false,
      ));
    } catch (e) {
      logger.e('Failed to load fan tournament data: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tournament data',
      ));
    }
  }

  Future<void> _onFollowTournament(
    FollowTournamentEvent event,
    Emitter<FanTournamentState> emit,
  ) async {
    emit(state.copyWith(isFollowing: true));

    try {
      // TODO: Implement tournament following in repository
      // await repository.followTournament(event.tournamentId, event.fanId);

      logger.i('Successfully followed tournament: ${event.tournamentId}');
      emit(state.copyWith(isFollowing: false));

      // Reload fan data
      add(LoadFanTournamentDataEvent(event.fanId));
    } catch (e) {
      logger.e('Failed to follow tournament: $e');
      emit(state.copyWith(
        isFollowing: false,
        errorMessage: 'Failed to follow tournament',
      ));
    }
  }

  Future<void> _onUnfollowTournament(
    UnfollowTournamentEvent event,
    Emitter<FanTournamentState> emit,
  ) async {
    emit(state.copyWith(isFollowing: true));

    try {
      // TODO: Implement tournament unfollowing in repository
      // await repository.unfollowTournament(event.tournamentId, event.fanId);

      logger.i('Successfully unfollowed tournament: ${event.tournamentId}');
      emit(state.copyWith(isFollowing: false));

      // Reload fan data
      add(LoadFanTournamentDataEvent(event.fanId));
    } catch (e) {
      logger.e('Failed to unfollow tournament: $e');
      emit(state.copyWith(
        isFollowing: false,
        errorMessage: 'Failed to unfollow tournament',
      ));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FanTournamentState> emit,
  ) async {
    try {
      // TODO: Implement favorites functionality
      // await repository.addTournamentToFavorites(event.tournamentId, event.fanId);

      logger.i('Added tournament to favorites: ${event.tournamentId}');

      // Reload fan data
      add(LoadFanTournamentDataEvent(event.fanId));
    } catch (e) {
      logger.e('Failed to add tournament to favorites: $e');
      emit(state.copyWith(errorMessage: 'Failed to add to favorites'));
    }
  }
}
