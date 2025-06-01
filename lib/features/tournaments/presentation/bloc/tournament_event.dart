import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';

abstract class TournamentEvent extends Equatable {
  const TournamentEvent();

  @override
  List<Object> get props => [];
}

// Tournament events
class LoadTournamentsEvent extends TournamentEvent {}

class LoadFeaturedTournamentsEvent extends TournamentEvent {}

class LoadUpcomingTournamentsEvent extends TournamentEvent {}

class LoadTournamentsByStatusEvent extends TournamentEvent {
  final TournamentStatus status;

  const LoadTournamentsByStatusEvent(this.status);

  @override
  List<Object> get props => [status];
}

class LoadTournamentByIdEvent extends TournamentEvent {
  final String tournamentId;

  const LoadTournamentByIdEvent(this.tournamentId);

  @override
  List<Object> get props => [tournamentId];
}

class CreateTournamentEvent extends TournamentEvent {
  final Tournament tournament;

  const CreateTournamentEvent(this.tournament);

  @override
  List<Object> get props => [tournament];
}

class UpdateTournamentEvent extends TournamentEvent {
  final Tournament tournament;

  const UpdateTournamentEvent(this.tournament);

  @override
  List<Object> get props => [tournament];
}

// Registration events
class LoadTournamentRegistrationsEvent extends TournamentEvent {
  final String tournamentId;

  const LoadTournamentRegistrationsEvent(this.tournamentId);

  @override
  List<Object> get props => [tournamentId];
}

class LoadUserRegistrationsEvent extends TournamentEvent {
  final String userId;

  const LoadUserRegistrationsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class RegisterForTournamentEvent extends TournamentEvent {
  final TournamentRegistration registration;

  const RegisterForTournamentEvent(this.registration);

  @override
  List<Object> get props => [registration];
}

class CancelRegistrationEvent extends TournamentEvent {
  final String registrationId;

  const CancelRegistrationEvent(this.registrationId);

  @override
  List<Object> get props => [registrationId];
} 