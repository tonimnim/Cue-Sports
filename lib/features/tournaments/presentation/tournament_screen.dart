import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/theme.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/usecases/usecase.dart';
import '../domain/entities/tournament.dart';
import '../domain/entities/match.dart';
import 'bloc/tournament_bloc.dart';
import 'bloc/tournament_event.dart';
import 'bloc/tournament_state.dart';
import 'widgets/tournament_card.dart';
import 'widgets/live_tournament_card.dart';
import '../../payment/domain/entities/payment.dart' as payment_entity;
import '../../auth/domain/get_current_user_use_case.dart';
import '../../auth/domain/entities/user.dart' as app_user;

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({Key? key}) : super(key: key);

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TournamentBloc _tournamentBloc;
  late GetCurrentUserUseCase _getCurrentUserUseCase;
  bool _isInitialized = false;
  app_user.User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Dynamic tab count based on user type (will be updated in didChangeDependencies)
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _tournamentBloc = context.read<TournamentBloc>();
      _getCurrentUserUseCase = di.sl<GetCurrentUserUseCase>();
      _isInitialized = true;
      
      // Load current user and tournament data
      _loadCurrentUser();
      _loadAllData();
    }
  }

  Future<void> _loadCurrentUser() async {
    final userResult = await _getCurrentUserUseCase(NoParams());
    userResult.fold(
      (failure) {
        print('❌ Failed to get current user: ${failure.message}');
      },
      (user) {
        if (mounted) {
          setState(() {
            _currentUser = user;
            // Update tab controller based on user type
            _updateTabController();
          });
        }
      },
    );
  }

  void _updateTabController() {
    final newLength = _getTabCount();
    if (_tabController.length != newLength) {
      final oldController = _tabController;
      _tabController = TabController(length: newLength, vsync: this);
      // Dispose the old controller after the frame to avoid issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }
  }

  int _getTabCount() {
    if (_currentUser?.isPlayer == true) {
      return 4; // All, Live, Upcoming, Registered
    } else {
      return 3; // All, Live, Upcoming (for fans and non-authenticated)
    }
  }

  void _loadAllData() {
    print('🏆 TOURNAMENT SCREEN: Loading all tournament data...');

    // Load ALL tournaments first
    _tournamentBloc.add(const LoadTournamentsEvent());

    // Load active tournaments
    _tournamentBloc.add(const LoadActiveTournamentsEvent());

    // Load live matches (only live matches, not featured tournaments)
    _tournamentBloc.add(const LoadLiveMatchesEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Tournaments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to tournament settings
              },
            ),
          ],
        ),
        body: BlocConsumer<TournamentBloc, TournamentState>(
          listener: (context, state) {
            // Debug logging
            print('🏆 TOURNAMENT STATE UPDATE:');
            print('   - Total tournaments: ${state.tournaments.length}');
            print(
                '   - Featured tournaments: ${state.featuredTournaments.length}');
            print('   - Active tournaments: ${state.activeTournaments.length}');
            print('   - Live matches: ${state.liveMatches.length}');
            print('   - Loading tournaments: ${state.isLoadingTournaments}');
            print('   - Loading matches: ${state.isLoadingMatches}');
            print('   - Has error: ${state.hasError}');
            if (state.hasError) {
              print('   - Error message: ${state.errorMessage}');
            }

            // Show error messages
            if (state.hasError && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _refreshData,
                  ),
                ),
              );
            }

            // Show success message when tournaments are loaded
            if (!state.isLoadingTournaments &&
                state.tournaments.isNotEmpty &&
                !state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Loaded ${state.tournaments.length} tournaments'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            // Ensure tab controller matches the current tab count
            if (_tabController.length != _getTabCount()) {
              _updateTabController();
            }
            
            return Column(
              children: [
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: _buildTabs(),
                  labelColor: AppTheme.accentColor,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: AppTheme.accentColor,
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _buildTabViews(state),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  void _refreshData() {
    print('🔄 TOURNAMENT SCREEN: Refreshing all data...');
    _loadAllData();
  }

  List<Tab> _buildTabs() {
    if (_currentUser?.isPlayer == true) {
      return const [
        Tab(text: 'All'),
        Tab(text: 'Live'),
        Tab(text: 'Upcoming'),
        Tab(text: 'Registered'),
      ];
    } else {
      return const [
        Tab(text: 'All'),
        Tab(text: 'Live'),
        Tab(text: 'Upcoming'),
      ];
    }
  }

  List<Widget> _buildTabViews(TournamentState state) {
    if (_currentUser?.isPlayer == true) {
      return [
        _buildAllTournamentsTab(state),
        _buildLiveTab(state),
        _buildUpcomingTab(state),
        _buildRegisteredTab(state),
      ];
    } else {
      return [
        _buildAllTournamentsTab(state),
        _buildLiveTab(state),
        _buildUpcomingTab(state),
      ];
    }
  }

  Widget _buildAllTournamentsTab(TournamentState state) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
        // Wait a bit for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh always works
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug Information Card (only in debug mode)
            if (const bool.fromEnvironment('dart.vm.product') == false) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total tournaments: ${state.tournaments.length}\n'
                      'Featured: ${state.featuredTournaments.length}\n'
                      'Active: ${state.activeTournaments.length}\n'
                      'Loading: ${state.isLoadingTournaments}\n'
                      'Error: ${state.hasError ? state.errorMessage : 'None'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator
            if (state.isLoadingTournaments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.accentColor),
                      SizedBox(height: 16),
                      Text(
                        'Loading tournaments from Firebase...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

            // Error state
            if (state.hasError && state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load tournaments',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // Show ALL tournaments
            if (!state.isLoadingTournaments &&
                state.tournaments.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'All Tournaments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.tournaments.length}',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display ALL tournaments from Firebase with proper constraints
              Column(
                children: state.tournaments.map((tournament) {
                  // Only national tournaments are featured
                  final isFeatured = tournament.type == TournamentType.national;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TournamentCard(
                      tournament: tournament,
                      isFeatured: isFeatured,
                      currentUser: _currentUser,
                      onTap: () => _navigateToTournamentDetails(tournament),
                      onRegister: () =>
                          _handleTournamentRegistration(tournament),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Empty State (only show if not loading and no tournaments)
            if (!state.isLoadingTournaments &&
                state.tournaments.isEmpty &&
                !state.hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tournaments available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back soon for new tournaments!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredTab(TournamentState state) {
    if (_currentUser == null) {
      return _buildEmptyState('Please log in to view registered tournaments');
    }

    // Filter tournaments where user is registered
    final registeredTournaments = state.tournaments
        .where((tournament) => _currentUser != null && tournament.isUserRegistered(_currentUser!.id))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadTournamentsEvent());
      },
      child: registeredTournaments.isEmpty
          ? _buildEmptyState('You are not registered for any tournaments yet')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registeredTournaments.length,
              itemBuilder: (context, index) {
                final tournament = registeredTournaments[index];
                final isFeatured = tournament.type == TournamentType.national;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TournamentCard(
                    tournament: tournament,
                    isFeatured: isFeatured,
                    currentUser: _currentUser,
                    onTap: () => _navigateToTournamentDetails(tournament),
                    onRegister: () => _handleTournamentRegistration(tournament),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLiveTab(TournamentState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadLiveMatchesEvent());
      },
      child: state.isLoadingMatches
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : state.liveMatches.isEmpty
              ? _buildEmptyState('No live matches at the moment')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = state.liveMatches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LiveMatchCard(
                        match: match,
                        onTap: () => _navigateToMatchDetails(match),
                        onViewLive: () => _openLiveStream(match),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildUpcomingTab(TournamentState state) {
    // Filter tournaments for upcoming status
    final upcomingTournaments = state.tournaments
        .where((tournament) =>
            tournament.status == TournamentStatus.upcoming ||
            tournament.status == TournamentStatus.registration_open ||
            tournament.status == TournamentStatus.registration_closed ||
            (tournament.status == TournamentStatus.active &&
                !tournament.hasStarted))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadTournamentsEvent(
              status: TournamentStatus.upcoming,
            ));
      },
      child: upcomingTournaments.isEmpty
          ? _buildEmptyState('No upcoming tournaments')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingTournaments.length,
              itemBuilder: (context, index) {
                final tournament = upcomingTournaments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TournamentCard(
                    tournament: tournament,
                    currentUser: _currentUser,
                    onTap: () => _navigateToTournamentDetails(tournament),
                    onRegister: () => _handleTournamentRegistration(tournament),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Search Tournaments',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter tournament name...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accentColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accentColor),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (query) {
            Navigator.pop(context);
            if (query.isNotEmpty) {
              context.read<TournamentBloc>().add(
                    SearchTournamentsEvent(query: query),
                  );
            }
          },
        ),
      ),
    );
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    // TODO: Navigate to tournament details
    print('Navigate to tournament: ${tournament.name}');
  }

  void _handleTournamentRegistration(Tournament tournament) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<TournamentBloc>().add(
            RegisterForTournamentEvent(
              tournamentId: tournament.id,
              userId: user.uid,
              communityId: '', // You might need to get this from user profile
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to register for tournaments'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToMatchDetails(Match match) {
    // TODO: Navigate to match details
    print('Navigate to match: ${match.id}');
  }

  void _openLiveStream(Match match) {
    // TODO: Open live stream
    print('Open live stream for match: ${match.id}');
  }
}
