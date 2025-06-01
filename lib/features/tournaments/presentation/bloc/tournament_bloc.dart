import 'package:bloc/bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/tournament_usecases.dart';
import 'tournament_event.dart';
import 'tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final GetTournamentsUseCase getTournamentsUseCase;
  final GetFeaturedTournamentsUseCase getFeaturedTournamentsUseCase;
  final GetUpcomingTournamentsUseCase getUpcomingTournamentsUseCase;

  TournamentBloc({
    required this.getTournamentsUseCase,
    required this.getFeaturedTournamentsUseCase,
    required this.getUpcomingTournamentsUseCase,
  }) : super(TournamentInitial()) {
    on<LoadTournamentsEvent>(_onLoadTournaments);
    on<LoadFeaturedTournamentsEvent>(_onLoadFeaturedTournaments);
    on<LoadUpcomingTournamentsEvent>(_onLoadUpcomingTournaments);
    on<LoadTournamentsByStatusEvent>(_onLoadTournamentsByStatus);
    on<LoadTournamentByIdEvent>(_onLoadTournamentById);
    on<CreateTournamentEvent>(_onCreateTournament);
    on<UpdateTournamentEvent>(_onUpdateTournament);
    on<LoadTournamentRegistrationsEvent>(_onLoadTournamentRegistrations);
    on<LoadUserRegistrationsEvent>(_onLoadUserRegistrations);
    on<RegisterForTournamentEvent>(_onRegisterForTournament);
    on<CancelRegistrationEvent>(_onCancelRegistration);
  }

  Future<void> _onLoadTournaments(LoadTournamentsEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    final result = await getTournamentsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(TournamentError(failure.message)),
      (tournaments) {
        final currentState = state is TournamentLoaded ? state as TournamentLoaded : const TournamentLoaded();
        emit(currentState.copyWith(tournaments: tournaments));
      },
    );
  }

  Future<void> _onLoadFeaturedTournaments(LoadFeaturedTournamentsEvent event, Emitter<TournamentState> emit) async {
    final result = await getFeaturedTournamentsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(TournamentError(failure.message)),
      (featuredTournaments) {
        final currentState = state is TournamentLoaded ? state as TournamentLoaded : const TournamentLoaded();
        emit(currentState.copyWith(featuredTournaments: featuredTournaments));
      },
    );
  }

  Future<void> _onLoadUpcomingTournaments(LoadUpcomingTournamentsEvent event, Emitter<TournamentState> emit) async {
    final result = await getUpcomingTournamentsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(TournamentError(failure.message)),
      (upcomingTournaments) {
        final currentState = state is TournamentLoaded ? state as TournamentLoaded : const TournamentLoaded();
        emit(currentState.copyWith(upcomingTournaments: upcomingTournaments));
      },
    );
  }

  Future<void> _onLoadTournamentsByStatus(LoadTournamentsByStatusEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement with GetTournamentsByStatusUseCase when needed
    emit(const TournamentError('Load tournaments by status not implemented yet'));
  }

  Future<void> _onLoadTournamentById(LoadTournamentByIdEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement with GetTournamentByIdUseCase when needed
    emit(const TournamentError('Load tournament by id not implemented yet'));
  }

  Future<void> _onCreateTournament(CreateTournamentEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement create tournament functionality
    emit(const TournamentError('Create tournament not implemented yet'));
  }

  Future<void> _onUpdateTournament(UpdateTournamentEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement update tournament functionality
    emit(const TournamentError('Update tournament not implemented yet'));
  }

  Future<void> _onLoadTournamentRegistrations(LoadTournamentRegistrationsEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement load tournament registrations functionality
    emit(const TournamentError('Load tournament registrations not implemented yet'));
  }

  Future<void> _onLoadUserRegistrations(LoadUserRegistrationsEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement load user registrations functionality
    emit(const TournamentError('Load user registrations not implemented yet'));
  }

  Future<void> _onRegisterForTournament(RegisterForTournamentEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement register for tournament functionality
    emit(const TournamentError('Register for tournament not implemented yet'));
  }

  Future<void> _onCancelRegistration(CancelRegistrationEvent event, Emitter<TournamentState> emit) async {
    emit(TournamentLoading());
    
    // TODO: Implement cancel registration functionality
    emit(const TournamentError('Cancel registration not implemented yet'));
  }
} 