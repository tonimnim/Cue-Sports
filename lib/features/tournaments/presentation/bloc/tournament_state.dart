import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';

abstract class TournamentState extends Equatable {
  const TournamentState();

  @override
  List<Object?> get props => [];
}

class TournamentInitial extends TournamentState {}

class TournamentLoading extends TournamentState {}

class TournamentLoaded extends TournamentState {
  final List<Tournament> tournaments;
  final List<Tournament> featuredTournaments;
  final List<Tournament> upcomingTournaments;
  final List<TournamentRegistration> registrations;
  final List<TournamentRegistration> userRegistrations;

  const TournamentLoaded({
    this.tournaments = const [],
    this.featuredTournaments = const [],
    this.upcomingTournaments = const [],
    this.registrations = const [],
    this.userRegistrations = const [],
  });

  TournamentLoaded copyWith({
    List<Tournament>? tournaments,
    List<Tournament>? featuredTournaments,
    List<Tournament>? upcomingTournaments,
    List<TournamentRegistration>? registrations,
    List<TournamentRegistration>? userRegistrations,
  }) {
    return TournamentLoaded(
      tournaments: tournaments ?? this.tournaments,
      featuredTournaments: featuredTournaments ?? this.featuredTournaments,
      upcomingTournaments: upcomingTournaments ?? this.upcomingTournaments,
      registrations: registrations ?? this.registrations,
      userRegistrations: userRegistrations ?? this.userRegistrations,
    );
  }

  @override
  List<Object?> get props => [
        tournaments,
        featuredTournaments,
        upcomingTournaments,
        registrations,
        userRegistrations,
      ];
}

class TournamentError extends TournamentState {
  final String message;

  const TournamentError(this.message);

  @override
  List<Object> get props => [message];
}

// Specific states for different operations
class TournamentDetailLoaded extends TournamentState {
  final Tournament? tournament;

  const TournamentDetailLoaded(this.tournament);

  @override
  List<Object?> get props => [tournament];
}

class TournamentCreated extends TournamentState {
  final String tournamentId;

  const TournamentCreated(this.tournamentId);

  @override
  List<Object> get props => [tournamentId];
}

class TournamentUpdated extends TournamentState {
  final Tournament tournament;

  const TournamentUpdated(this.tournament);

  @override
  List<Object> get props => [tournament];
}

class RegistrationSuccess extends TournamentState {
  final String registrationId;

  const RegistrationSuccess(this.registrationId);

  @override
  List<Object> get props => [registrationId];
}

class RegistrationCancelled extends TournamentState {
  final String message;

  const RegistrationCancelled(this.message);

  @override
  List<Object> get props => [message];
} 