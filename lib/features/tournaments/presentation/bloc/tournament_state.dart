import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/player_tournament_stats.dart';
import '../../../auth/domain/entities/user.dart';

/// Tournament state class with user context awareness
class TournamentState extends Equatable {
  // User context for role-based features
  final User? currentUser;
  bool get isPlayer => currentUser?.isPlayer ?? false;
  bool get isFan => currentUser?.userType == 'fan';

  // Tournament data
  final List<Tournament> tournaments;
  final List<Tournament> featuredTournaments;
  final List<Tournament> activeTournaments;
  final Tournament? selectedTournament;
  final List<Tournament> searchResults;

  // Player-specific data (only relevant for players)
  final List<Match> playerMatches;
  final List<Match> tournamentMatches;
  final List<Match> upcomingMatches;
  final PlayerTournamentStats? playerStats;
  final List<PlayerTournamentStats> leaderboard;
  final List<PlayerTournamentStats> communityLeaderboard;
  final List<TournamentRegistration> registrations;
  final List<TournamentRegistration> userRegistrations;
  final bool isRegistered;
  final bool registrationSuccess;
  final bool isRegistering;

  // Fan-specific data (only relevant for fans)
  final List<Tournament> followedTournaments;
  final List<String> favoriteTournamentIds;
  final Map<String, int> liveViewerCounts;

  // Shared data (relevant for both)
  final List<Match> liveMatches;
  final Match? selectedMatch;
  final List<Match> matchSearchResults;

  // UI state
  final bool isLoading;
  final bool isLoadingTournaments;
  final bool isLoadingMatches;
  final bool isLoadingStats;
  final bool isSearching;

  // Error handling
  final String? errorMessage;
  final bool hasError;

  // Search state
  final String searchQuery;
  final bool isSearchMode;

  const TournamentState({
    this.currentUser,
    this.tournaments = const [],
    this.featuredTournaments = const [],
    this.activeTournaments = const [],
    this.selectedTournament,
    this.searchResults = const [],
    this.playerMatches = const [],
    this.tournamentMatches = const [],
    this.upcomingMatches = const [],
    this.liveMatches = const [],
    this.selectedMatch,
    this.matchSearchResults = const [],
    this.playerStats,
    this.leaderboard = const [],
    this.communityLeaderboard = const [],
    this.registrations = const [],
    this.userRegistrations = const [],
    this.followedTournaments = const [],
    this.favoriteTournamentIds = const [],
    this.liveViewerCounts = const {},
    this.isLoading = false,
    this.isLoadingTournaments = false,
    this.isLoadingMatches = false,
    this.isLoadingStats = false,
    this.isRegistering = false,
    this.isSearching = false,
    this.isRegistered = false,
    this.registrationSuccess = false,
    this.errorMessage,
    this.hasError = false,
    this.searchQuery = '',
    this.isSearchMode = false,
  });

  /// Create initial state
  factory TournamentState.initial() {
    return const TournamentState();
  }

  /// Create user-aware initial state
  factory TournamentState.initialWithUser(User user) {
    return TournamentState(currentUser: user);
  }

  /// Create loading state
  TournamentState copyWithLoading({bool? loading}) {
    return copyWith(isLoading: loading ?? true);
  }

  /// Create error state
  TournamentState copyWithError(String message) {
    return copyWith(
      hasError: true,
      errorMessage: message,
      isLoading: false,
      isLoadingTournaments: false,
      isLoadingMatches: false,
      isLoadingStats: false,
      isRegistering: false,
      isSearching: false,
    );
  }

  /// Create success state
  TournamentState copyWithSuccess() {
    return copyWith(
      hasError: false,
      errorMessage: null,
      isLoading: false,
      isLoadingTournaments: false,
      isLoadingMatches: false,
      isLoadingStats: false,
      isRegistering: false,
      isSearching: false,
    );
  }

  /// Copy with updated fields
  TournamentState copyWith({
    User? currentUser,
    List<Tournament>? tournaments,
    List<Tournament>? featuredTournaments,
    List<Tournament>? activeTournaments,
    Tournament? selectedTournament,
    List<Tournament>? searchResults,
    List<Match>? playerMatches,
    List<Match>? tournamentMatches,
    List<Match>? upcomingMatches,
    List<Match>? liveMatches,
    Match? selectedMatch,
    List<Match>? matchSearchResults,
    PlayerTournamentStats? playerStats,
    List<PlayerTournamentStats>? leaderboard,
    List<PlayerTournamentStats>? communityLeaderboard,
    List<TournamentRegistration>? registrations,
    List<TournamentRegistration>? userRegistrations,
    List<Tournament>? followedTournaments,
    List<String>? favoriteTournamentIds,
    Map<String, int>? liveViewerCounts,
    bool? isLoading,
    bool? isLoadingTournaments,
    bool? isLoadingMatches,
    bool? isLoadingStats,
    bool? isRegistering,
    bool? isSearching,
    bool? isRegistered,
    bool? registrationSuccess,
    String? errorMessage,
    bool? hasError,
    String? searchQuery,
    bool? isSearchMode,
    bool clearError = false,
    bool clearSelectedTournament = false,
    bool clearSelectedMatch = false,
    bool clearPlayerStats = false,
  }) {
    return TournamentState(
      currentUser: currentUser ?? this.currentUser,
      tournaments: tournaments ?? this.tournaments,
      featuredTournaments: featuredTournaments ?? this.featuredTournaments,
      activeTournaments: activeTournaments ?? this.activeTournaments,
      selectedTournament: clearSelectedTournament
          ? null
          : (selectedTournament ?? this.selectedTournament),
      searchResults: searchResults ?? this.searchResults,
      playerMatches: playerMatches ?? this.playerMatches,
      tournamentMatches: tournamentMatches ?? this.tournamentMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      liveMatches: liveMatches ?? this.liveMatches,
      selectedMatch:
          clearSelectedMatch ? null : (selectedMatch ?? this.selectedMatch),
      matchSearchResults: matchSearchResults ?? this.matchSearchResults,
      playerStats: clearPlayerStats ? null : (playerStats ?? this.playerStats),
      leaderboard: leaderboard ?? this.leaderboard,
      communityLeaderboard: communityLeaderboard ?? this.communityLeaderboard,
      registrations: registrations ?? this.registrations,
      userRegistrations: userRegistrations ?? this.userRegistrations,
      followedTournaments: followedTournaments ?? this.followedTournaments,
      favoriteTournamentIds:
          favoriteTournamentIds ?? this.favoriteTournamentIds,
      liveViewerCounts: liveViewerCounts ?? this.liveViewerCounts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTournaments: isLoadingTournaments ?? this.isLoadingTournaments,
      isLoadingMatches: isLoadingMatches ?? this.isLoadingMatches,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isRegistering: isRegistering ?? this.isRegistering,
      isSearching: isSearching ?? this.isSearching,
      isRegistered: isRegistered ?? this.isRegistered,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasError: clearError ? false : (hasError ?? this.hasError),
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }

  /// Check if any loading is in progress
  bool get isAnyLoading {
    return isLoading ||
        isLoadingTournaments ||
        isLoadingMatches ||
        isLoadingStats ||
        isRegistering ||
        isSearching;
  }

  /// Check if tournaments are empty
  bool get hasTournaments {
    return tournaments.isNotEmpty;
  }

  /// Check if matches are empty
  bool get hasMatches {
    return playerMatches.isNotEmpty ||
        tournamentMatches.isNotEmpty ||
        upcomingMatches.isNotEmpty;
  }

  /// Check if search has results
  bool get hasSearchResults {
    return searchResults.isNotEmpty || matchSearchResults.isNotEmpty;
  }

  /// Get total tournaments count
  int get tournamentsCount {
    return tournaments.length;
  }

  /// Get total matches count
  int get matchesCount {
    return playerMatches.length +
        tournamentMatches.length +
        upcomingMatches.length;
  }

  /// Get featured tournaments count
  int get featuredTournamentsCount {
    return featuredTournaments.length;
  }

  /// Get live matches count
  int get liveMatchesCount {
    return liveMatches.length;
  }

  @override
  List<Object?> get props => [
        currentUser,
        tournaments,
        featuredTournaments,
        activeTournaments,
        selectedTournament,
        searchResults,
        playerMatches,
        tournamentMatches,
        upcomingMatches,
        liveMatches,
        selectedMatch,
        matchSearchResults,
        playerStats,
        leaderboard,
        communityLeaderboard,
        registrations,
        userRegistrations,
        followedTournaments,
        favoriteTournamentIds,
        liveViewerCounts,
        isLoading,
        isLoadingTournaments,
        isLoadingMatches,
        isLoadingStats,
        isRegistering,
        isSearching,
        isRegistered,
        registrationSuccess,
        errorMessage,
        hasError,
        searchQuery,
        isSearchMode,
      ];
}

class TournamentInitial extends TournamentState {}

class TournamentLoading extends TournamentState {}

class TournamentLoaded extends TournamentState {
  const TournamentLoaded({
    super.currentUser,
    super.tournaments,
    super.featuredTournaments,
    super.activeTournaments,
    super.registrations,
    super.userRegistrations,
    super.selectedTournament,
    super.searchResults,
    super.playerMatches,
    super.tournamentMatches,
    super.upcomingMatches,
    super.liveMatches,
    super.selectedMatch,
    super.matchSearchResults,
    super.playerStats,
    super.leaderboard,
    super.communityLeaderboard,
    super.followedTournaments,
    super.favoriteTournamentIds,
    super.liveViewerCounts,
    super.isLoading,
    super.isLoadingTournaments,
    super.isLoadingMatches,
    super.isLoadingStats,
    super.isRegistering,
    super.isSearching,
    super.isRegistered,
    super.registrationSuccess,
    super.errorMessage,
    super.hasError,
    super.searchQuery,
    super.isSearchMode,
  });

  @override
  TournamentLoaded copyWith({
    User? currentUser,
    List<Tournament>? tournaments,
    List<Tournament>? featuredTournaments,
    List<Tournament>? activeTournaments,
    Tournament? selectedTournament,
    List<Tournament>? searchResults,
    List<Match>? playerMatches,
    List<Match>? tournamentMatches,
    List<Match>? upcomingMatches,
    List<Match>? liveMatches,
    Match? selectedMatch,
    List<Match>? matchSearchResults,
    PlayerTournamentStats? playerStats,
    List<PlayerTournamentStats>? leaderboard,
    List<PlayerTournamentStats>? communityLeaderboard,
    List<TournamentRegistration>? registrations,
    List<TournamentRegistration>? userRegistrations,
    List<Tournament>? followedTournaments,
    List<String>? favoriteTournamentIds,
    Map<String, int>? liveViewerCounts,
    bool? isLoading,
    bool? isLoadingTournaments,
    bool? isLoadingMatches,
    bool? isLoadingStats,
    bool? isRegistering,
    bool? isSearching,
    bool? isRegistered,
    bool? registrationSuccess,
    String? errorMessage,
    bool? hasError,
    String? searchQuery,
    bool? isSearchMode,
    bool clearError = false,
    bool clearSelectedTournament = false,
    bool clearSelectedMatch = false,
    bool clearPlayerStats = false,
  }) {
    return TournamentLoaded(
      currentUser: currentUser ?? this.currentUser,
      tournaments: tournaments ?? this.tournaments,
      featuredTournaments: featuredTournaments ?? this.featuredTournaments,
      activeTournaments: activeTournaments ?? this.activeTournaments,
      selectedTournament: clearSelectedTournament
          ? null
          : (selectedTournament ?? this.selectedTournament),
      searchResults: searchResults ?? this.searchResults,
      playerMatches: playerMatches ?? this.playerMatches,
      tournamentMatches: tournamentMatches ?? this.tournamentMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      liveMatches: liveMatches ?? this.liveMatches,
      selectedMatch:
          clearSelectedMatch ? null : (selectedMatch ?? this.selectedMatch),
      matchSearchResults: matchSearchResults ?? this.matchSearchResults,
      playerStats: clearPlayerStats ? null : (playerStats ?? this.playerStats),
      leaderboard: leaderboard ?? this.leaderboard,
      communityLeaderboard: communityLeaderboard ?? this.communityLeaderboard,
      registrations: registrations ?? this.registrations,
      userRegistrations: userRegistrations ?? this.userRegistrations,
      followedTournaments: followedTournaments ?? this.followedTournaments,
      favoriteTournamentIds:
          favoriteTournamentIds ?? this.favoriteTournamentIds,
      liveViewerCounts: liveViewerCounts ?? this.liveViewerCounts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTournaments: isLoadingTournaments ?? this.isLoadingTournaments,
      isLoadingMatches: isLoadingMatches ?? this.isLoadingMatches,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isRegistering: isRegistering ?? this.isRegistering,
      isSearching: isSearching ?? this.isSearching,
      isRegistered: isRegistered ?? this.isRegistered,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasError: clearError ? false : (hasError ?? this.hasError),
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }
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
