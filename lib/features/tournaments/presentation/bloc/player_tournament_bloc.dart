import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/player_tournament_stats.dart';
import 'tournament_event.dart';

/// Player-specific tournament events
abstract class PlayerTournamentEvent {}

class LoadPlayerTournamentDataEvent extends PlayerTournamentEvent {
  final String playerId;
  LoadPlayerTournamentDataEvent(this.playerId);
}

class RegisterForTournamentEvent extends PlayerTournamentEvent {
  final String tournamentId;
  final String userId;
  final String communityId;

  RegisterForTournamentEvent({
    required this.tournamentId,
    required this.userId,
    required this.communityId,
  });
}

/// Player-specific tournament state
class PlayerTournamentState {
  final List<Tournament> registeredTournaments;
  final List<Match> playerMatches;
  final List<Match> upcomingMatches;
  final PlayerTournamentStats? playerStats;
  final List<PlayerTournamentStats> leaderboards;
  final bool isRegistering;
  final bool isLoading;
  final String? errorMessage;

  const PlayerTournamentState({
    this.registeredTournaments = const [],
    this.playerMatches = const [],
    this.upcomingMatches = const [],
    this.playerStats,
    this.leaderboards = const [],
    this.isRegistering = false,
    this.isLoading = false,
    this.errorMessage,
  });

  PlayerTournamentState copyWith({
    List<Tournament>? registeredTournaments,
    List<Match>? playerMatches,
    List<Match>? upcomingMatches,
    PlayerTournamentStats? playerStats,
    List<PlayerTournamentStats>? leaderboards,
    bool? isRegistering,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerTournamentState(
      registeredTournaments:
          registeredTournaments ?? this.registeredTournaments,
      playerMatches: playerMatches ?? this.playerMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      playerStats: playerStats ?? this.playerStats,
      leaderboards: leaderboards ?? this.leaderboards,
      isRegistering: isRegistering ?? this.isRegistering,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// BLoC for player-specific tournament functionality
class PlayerTournamentBloc
    extends Bloc<PlayerTournamentEvent, PlayerTournamentState> {
  final TournamentRepository repository;
  final LoggerService logger;

  PlayerTournamentBloc({
    required this.repository,
    required this.logger,
  }) : super(const PlayerTournamentState()) {
    on<LoadPlayerTournamentDataEvent>(_onLoadPlayerData);
    on<RegisterForTournamentEvent>(_onRegisterForTournament);
  }

  Future<void> _onLoadPlayerData(
    LoadPlayerTournamentDataEvent event,
    Emitter<PlayerTournamentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Load player-specific data in parallel
      final futures = await Future.wait([
        repository.getPlayerMatches(playerId: event.playerId),
        repository.getUpcomingMatches(playerId: event.playerId),
        repository.getPlayerStats(
          userId: event.playerId,
          tournamentId: '', // Get all tournaments
        ),
      ]);

      final playerMatches =
          futures[0].fold((l) => <Match>[], (r) => r as List<Match>);
      final upcomingMatches =
          futures[1].fold((l) => <Match>[], (r) => r as List<Match>);
      final playerStats =
          futures[2].fold((l) => null, (r) => r as PlayerTournamentStats?);

      emit(state.copyWith(
        playerMatches: playerMatches,
        upcomingMatches: upcomingMatches,
        playerStats: playerStats,
        isLoading: false,
      ));
    } catch (e) {
      logger.e('Failed to load player tournament data: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tournament data',
      ));
    }
  }

  Future<void> _onRegisterForTournament(
    RegisterForTournamentEvent event,
    Emitter<PlayerTournamentState> emit,
  ) async {
    emit(state.copyWith(isRegistering: true));

    final result = await repository.registerForTournament(
      tournamentId: event.tournamentId,
      userId: event.userId,
      communityId: event.communityId,
    );

    result.fold(
      (failure) {
        logger.e('Tournament registration failed: ${failure.message}');
        emit(state.copyWith(
          isRegistering: false,
          errorMessage: 'Registration failed: ${failure.message}',
        ));
      },
      (success) {
        logger.i('Tournament registration successful');
        emit(state.copyWith(isRegistering: false));
        // Reload player data
        add(LoadPlayerTournamentDataEvent(event.userId));
      },
    );
  }
}
