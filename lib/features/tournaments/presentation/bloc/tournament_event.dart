import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';

/// Base class for tournament events
abstract class TournamentEvent extends Equatable {
  const TournamentEvent();

  @override
  List<Object?> get props => [];
}

// Tournament Events
class LoadTournamentsEvent extends TournamentEvent {
  final TournamentStatus? status;
  final TournamentType? type;
  final bool? isFeatured;
  final int? limit;

  const LoadTournamentsEvent({
    this.status,
    this.type,
    this.isFeatured,
    this.limit,
  });

  @override
  List<Object?> get props => [status, type, isFeatured, limit];
}

class LoadFeaturedTournamentsEvent extends TournamentEvent {
  const LoadFeaturedTournamentsEvent();
}

class LoadActiveTournamentsEvent extends TournamentEvent {
  const LoadActiveTournamentsEvent();
}

class LoadTournamentDetailsEvent extends TournamentEvent {
  final String tournamentId;

  const LoadTournamentDetailsEvent({required this.tournamentId});

  @override
  List<Object> get props => [tournamentId];
}

class RegisterForTournamentEvent extends TournamentEvent {
  final String tournamentId;
  final String userId;
  final String communityId;

  const RegisterForTournamentEvent({
    required this.tournamentId,
    required this.userId,
    required this.communityId,
  });

  @override
  List<Object> get props => [tournamentId, userId, communityId];
}

class CheckRegistrationStatusEvent extends TournamentEvent {
  final String tournamentId;
  final String userId;

  const CheckRegistrationStatusEvent({
    required this.tournamentId,
    required this.userId,
  });

  @override
  List<Object> get props => [tournamentId, userId];
}

class SearchTournamentsEvent extends TournamentEvent {
  final String query;
  final TournamentType? type;
  final TournamentStatus? status;

  const SearchTournamentsEvent({
    required this.query,
    this.type,
    this.status,
  });

  @override
  List<Object?> get props => [query, type, status];
}

// Match Events
class LoadPlayerMatchesEvent extends TournamentEvent {
  final String playerId;
  final MatchStatus? status;
  final int? limit;

  const LoadPlayerMatchesEvent({
    required this.playerId,
    this.status,
    this.limit,
  });

  @override
  List<Object?> get props => [playerId, status, limit];
}

class LoadTournamentMatchesEvent extends TournamentEvent {
  final String tournamentId;
  final MatchStatus? status;
  final int? limit;

  const LoadTournamentMatchesEvent({
    required this.tournamentId,
    this.status,
    this.limit,
  });

  @override
  List<Object?> get props => [tournamentId, status, limit];
}

class LoadUpcomingMatchesEvent extends TournamentEvent {
  final String? playerId;
  final int? limit;

  const LoadUpcomingMatchesEvent({
    this.playerId,
    this.limit,
  });

  @override
  List<Object?> get props => [playerId, limit];
}

class LoadLiveMatchesEvent extends TournamentEvent {
  const LoadLiveMatchesEvent();
}

class LoadMatchDetailsEvent extends TournamentEvent {
  final String matchId;

  const LoadMatchDetailsEvent({required this.matchId});

  @override
  List<Object> get props => [matchId];
}

class SearchMatchesEvent extends TournamentEvent {
  final String query;
  final String? tournamentId;
  final MatchStatus? status;

  const SearchMatchesEvent({
    required this.query,
    this.tournamentId,
    this.status,
  });

  @override
  List<Object?> get props => [query, tournamentId, status];
}

// Player Statistics Events
class LoadPlayerStatsEvent extends TournamentEvent {
  final String userId;
  final String tournamentId;

  const LoadPlayerStatsEvent({
    required this.userId,
    required this.tournamentId,
  });

  @override
  List<Object> get props => [userId, tournamentId];
}

class LoadTournamentLeaderboardEvent extends TournamentEvent {
  final String tournamentId;
  final String? communityId;
  final int? limit;

  const LoadTournamentLeaderboardEvent({
    required this.tournamentId,
    this.communityId,
    this.limit,
  });

  @override
  List<Object?> get props => [tournamentId, communityId, limit];
}

class LoadCommunityLeaderboardEvent extends TournamentEvent {
  final String tournamentId;
  final String communityId;
  final int? limit;

  const LoadCommunityLeaderboardEvent({
    required this.tournamentId,
    required this.communityId,
    this.limit,
  });

  @override
  List<Object?> get props => [tournamentId, communityId, limit];
}

// UI Events
class RefreshTournamentsEvent extends TournamentEvent {
  const RefreshTournamentsEvent();
}

class RefreshMatchesEvent extends TournamentEvent {
  const RefreshMatchesEvent();
}

class ClearSearchEvent extends TournamentEvent {
  const ClearSearchEvent();
}

class ResetTournamentStateEvent extends TournamentEvent {
  const ResetTournamentStateEvent();
}
