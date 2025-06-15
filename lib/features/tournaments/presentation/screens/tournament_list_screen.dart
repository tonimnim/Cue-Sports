import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match.dart';
import '../bloc/tournament_bloc.dart';
import '../bloc/tournament_event.dart';
import '../bloc/tournament_state.dart';
import '../widgets/tournament_card.dart';
import '../widgets/live_tournament_card.dart';
import '../widgets/tournament_search_bar.dart';
import '../../../payment/domain/entities/payment.dart' as payment_entity;
import '../../../payment/services/payment_migration_helper.dart';
import '../../../auth/domain/get_current_user_use_case.dart';
import '../../../auth/domain/entities/user.dart' as auth_user;

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({Key? key}) : super(key: key);

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GetCurrentUserUseCase _getCurrentUserUseCase;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRegistering = false;
  auth_user.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getCurrentUserUseCase = di.sl<GetCurrentUserUseCase>();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userResult = await _getCurrentUserUseCase(NoParams());
    userResult.fold(
      (failure) {
        print('❌ Failed to get current user: ${failure.message}');
      },
      (user) {
        print('✅ Current user loaded: ${user?.fullName} (${user?.userType}) - ID: ${user?.id}');
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TournamentBloc>()
        ..add(const LoadTournamentsEvent())
        ..add(const LoadActiveTournamentsEvent())
        ..add(const LoadLiveMatchesEvent()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title:
              const Text('Tournaments', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // Navigate to tournament settings/filters
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentColor,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Live'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: BlocConsumer<TournamentBloc, TournamentState>(
          listener: (context, state) {
            if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (state.registrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Successfully registered for tournament!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildAllTournamentsTab(context, state),
                _buildLiveTournamentsTab(context, state),
                _buildUpcomingTournamentsTab(context, state),
                _buildPastTournamentsTab(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllTournamentsTab(BuildContext context, TournamentState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const RefreshTournamentsEvent());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // National Tournaments Section (only national tournaments are featured)
            if (state.activeTournaments.where((t) => t.type == TournamentType.national).isNotEmpty) ...[
              _buildSectionHeader('National Tournaments'),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.activeTournaments.where((t) => t.type == TournamentType.national).length,
                  itemBuilder: (context, index) {
                    final nationalTournaments = state.activeTournaments.where((t) => t.type == TournamentType.national).toList();
                    final tournament = nationalTournaments[index];
                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 16),
                      child: TournamentCard(
                        tournament: tournament,
                        isFeatured: true,
                        currentUser: _currentUser,
                        onTap: () => _navigateToTournamentDetails(tournament),
                        onRegister: () =>
                            _handleTournamentRegistration(tournament),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Live Tournaments Section
            if (state.liveMatches.isNotEmpty) ...[
              _buildSectionHeader('Live Tournaments'),
              const SizedBox(height: 12),
              ...state.liveMatches.map((match) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LiveTournamentCard(
                      match: match,
                      onTap: () => _navigateToMatchDetails(match),
                      onViewLive: () => _openLiveStream(match),
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // All Active Tournaments Section
            _buildSectionHeader('All Tournaments'),
            const SizedBox(height: 12),
            if (state.isLoadingTournaments)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white))
            else if (state.activeTournaments.isEmpty)
              _buildEmptyState('No tournaments available')
            else
              ...state.activeTournaments.map((tournament) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TournamentCard(
                      tournament: tournament,
                      isFeatured: tournament.type == TournamentType.national,
                      currentUser: _currentUser,
                      onTap: () => _navigateToTournamentDetails(tournament),
                      onRegister: () =>
                          _handleTournamentRegistration(tournament),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTournamentsTab(BuildContext context, TournamentState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadLiveMatchesEvent());
      },
      child: state.isLoadingMatches
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : state.liveMatches.isEmpty
              ? _buildEmptyState('No live tournaments at the moment')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = state.liveMatches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LiveTournamentCard(
                        match: match,
                        onTap: () => _navigateToMatchDetails(match),
                        onViewLive: () => _openLiveStream(match),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildUpcomingTournamentsTab(
      BuildContext context, TournamentState state) {
    final upcomingTournaments = state.activeTournaments
        .where((tournament) => !tournament.hasStarted)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadActiveTournamentsEvent());
      },
      child: upcomingTournaments.isEmpty
          ? _buildEmptyState('No upcoming tournaments')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingTournaments.length,
              itemBuilder: (context, index) {
                final tournament = upcomingTournaments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TournamentCard(
                    tournament: tournament,
                    isFeatured: tournament.type == TournamentType.national,
                    currentUser: _currentUser,
                    onTap: () => _navigateToTournamentDetails(tournament),
                    onRegister: () => _handleTournamentRegistration(tournament),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPastTournamentsTab(BuildContext context, TournamentState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const LoadTournamentsEvent(
              status: TournamentStatus.completed,
            ));
      },
      child: const Center(
        child: Text(
          'Past tournaments - Coming soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Search Tournaments',
            style: TextStyle(color: Colors.white)),
        content: TournamentSearchBar(
          controller: _searchController,
          onSearch: (query) {
            Navigator.pop(dialogContext);
            if (query.isNotEmpty) {
              context
                  .read<TournamentBloc>()
                  .add(SearchTournamentsEvent(query: query));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    // Navigate to tournament details screen
    Navigator.pushNamed(
      context,
      '/tournament-details',
      arguments: {'tournament': tournament},
    );
  }

  void _navigateToMatchDetails(Match match) {
    // Navigate to match details screen
    Navigator.pushNamed(
      context,
      '/match-details',
      arguments: {'match': match},
    );
  }

  void _openLiveStream(Match match) {
    if (match.youtubeStreamUrl != null) {
      // Open YouTube stream URL
      // You can use url_launcher package here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Opening live stream for ${match.player1Name} vs ${match.player2Name}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _handleTournamentRegistration(Tournament tournament) async {
    if (_isRegistering) return; // Prevent double registration
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to register for tournaments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!tournament.isOpenForRegistration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration is closed for this tournament'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // Get current user details to access community information
      final userResult = await _getCurrentUserUseCase(NoParams());
      
      auth_user.User? currentUser;
      List<String> userCommunityIds = [];
      
      userResult.fold(
        (failure) {
          print('❌ Failed to get current user: ${failure.message}');
          // Continue with empty community list - user might not be in a community yet
        },
        (user) {
          currentUser = user;
          if (user?.communityId != null) {
            userCommunityIds = [user.communityId!];
          }
        },
      );

      // Check if user can access this tournament
      if (!tournament.isVisibleToUser(user.uid, userCommunityIds)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tournament.hasAccessRestrictions 
                ? 'You must be a member of an allowed community to register for this tournament'
                : 'You do not have access to this tournament'
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isRegistering = false);
        return;
      }

      // Ensure user has a community for registration (required by tournament system)
      if (currentUser?.communityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please join a community before registering for tournaments'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isRegistering = false);
        return;
      }

      // Navigate to payment for tournament registration
      PaymentMigrationHelper.navigateToUnifiedPayment(
        context,
        paymentType: payment_entity.PaymentType.tournament,
        typeId: tournament.id,
        userId: user.uid,
        amount: tournament.entryFee,
        metadata: {
          'tournamentName': tournament.name,
          'tournamentDate': tournament.dateRange,
          'tournamentVenue': tournament.primaryVenue,
          'userCommunityId': currentUser?.communityId ?? '',
        },
        onSuccess: () {
          // Reset the registering state
          if (mounted) {
            setState(() => _isRegistering = false);
          }
          
          // Refresh tournaments and show success
          context.read<TournamentBloc>().add(const RefreshTournamentsEvent());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully registered for ${tournament.name}'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
        onFailure: () {
          if (mounted) {
            setState(() => _isRegistering = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('❌ Error during registration process: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isRegistering = false);
      }
    }
  }
}
