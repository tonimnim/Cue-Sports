import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/tournament_bloc.dart';
import '../bloc/tournament_event.dart';
import '../bloc/tournament_state.dart';
import '../widgets/venue_card.dart';
import '../../../payment/services/payment_migration_helper.dart';
import '../../../payment/domain/entities/payment.dart' as payment_entity;
import '../../../auth/domain/get_current_user_use_case.dart';
import '../../../auth/domain/entities/user.dart' as auth_user;

class TournamentDetailsScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailsScreen({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TournamentBloc _tournamentBloc;
  late GetCurrentUserUseCase _getCurrentUserUseCase;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tournamentBloc = di.sl<TournamentBloc>();
    _getCurrentUserUseCase = di.sl<GetCurrentUserUseCase>();

    // Load detailed tournament data
    _tournamentBloc
        .add(LoadTournamentDetailsEvent(tournamentId: widget.tournament.id));

    // Check registration status if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tournamentBloc.add(CheckRegistrationStatusEvent(
        tournamentId: widget.tournament.id,
        userId: user.uid,
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tournamentBloc,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: BlocConsumer<TournamentBloc, TournamentState>(
          listener: (context, state) {
            // Handle registration state changes
            if (state.registrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully registered for tournament!'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() => _isRegistering = false);
            }

            if (state.hasError && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _isRegistering = false);
            }
          },
          builder: (context, state) {
            final tournament = state.selectedTournament ?? widget.tournament;

            return CustomScrollView(
              slivers: [
                _buildAppBar(tournament),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildTournamentHeader(tournament, state),
                      _buildTabBar(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(tournament),
                            _buildVenuesTab(tournament),
                            _buildRulesTab(tournament),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomActionBar(),
      ),
    );
  }

  Widget _buildAppBar(Tournament tournament) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.cardColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          tournament.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.cardColor,
                AppTheme.cardColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // Account for status bar
              Icon(
                _getTournamentIcon(tournament.type),
                size: 60,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(tournament.type),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tournament.typeDisplayName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentHeader(Tournament tournament, TournamentState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Featured badges
          Row(
            children: [
              _buildStatusBadge(tournament.status),
              const SizedBox(width: 8),
              if (tournament.isFeatured) _buildFeaturedBadge(),
              if (tournament.isNational) ...[
                const SizedBox(width: 8),
                _buildNationalBadge(),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Tournament description
          if (tournament.description.isNotEmpty) ...[
            Text(
              tournament.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Key information grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            children: [
              _buildInfoCard(
                Icons.calendar_today,
                'Date',
                tournament.dateRange,
              ),
              _buildInfoCard(
                Icons.location_on,
                'Location',
                tournament.location,
              ),
              _buildInfoCard(
                Icons.people,
                'Players',
                '${tournament.currentPlayerCount}/${tournament.maxPlayers == 0 ? '∞' : tournament.maxPlayers}',
              ),
              _buildInfoCard(
                Icons.attach_money,
                'Entry Fee',
                'KSh ${tournament.entryFee.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.backgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accentColor,
        labelColor: AppTheme.accentColor,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Venues'),
          Tab(text: 'Rules'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prize Information
          _buildSectionHeader('Prize Pool'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentColor,
                  AppTheme.accentColor.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'KSh ${tournament.prizePool.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Total Prize Pool',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Prize Structure (if available)
          if (tournament.prizeStructure != null) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('Prize Distribution'),
            const SizedBox(height: 12),
            ..._buildPrizeStructure(tournament.prizeStructure!),
          ],

          const SizedBox(height: 24),

          // Sponsor Information
          if (tournament.sponsorName != null) ...[
            _buildSectionHeader('Sponsored By'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppTheme.accentColor),
                  const SizedBox(width: 12),
                  Text(
                    tournament.sponsorName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Access Restrictions (if any)
          if (tournament.hasAccessRestrictions) ...[
            _buildSectionHeader('Access Requirements'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Restricted Tournament',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (tournament.access.restrictionDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      tournament.access.restrictionDescription ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Registration Status
          _buildSectionHeader('Registration Status'),
          const SizedBox(height: 12),
          _buildRegistrationInfo(tournament),
        ],
      ),
    );
  }

  Widget _buildVenuesTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.hasMultipleVenues) ...[
            _buildSectionHeader('Tournament Venues'),
            const SizedBox(height: 12),
            Text(
              'This tournament will be held across multiple venues. Community admins will notify players of their specific venue.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            ...tournament.venues.map((venue) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VenueCard(venue: venue),
                )),
          ] else ...[
            _buildSectionHeader('Venue Information'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.accentColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tournament.primaryVenue,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tournament.location,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tournament Rules'),
          const SizedBox(height: 12),
          if (tournament.rules.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No specific rules have been set for this tournament. Standard cue sports rules apply.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ] else ...[
            ...tournament.rules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        final tournament = state.selectedTournament ?? widget.tournament;

        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login to Register',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        if (state.isRegistered || tournament.isUserRegistered(user.uid)) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Already Registered',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Registration info
              if (!tournament.canRegister) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getRegistrationMessage(tournament),
                    style: const TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Register button
              ElevatedButton(
                onPressed: tournament.canRegister && !_isRegistering
                    ? () => _handleRegistration(tournament, user.uid)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tournament.canRegister
                      ? AppTheme.accentColor
                      : Colors.grey,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistering
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        tournament.canRegister
                            ? 'Register - KSh ${tournament.entryFee.toStringAsFixed(0)}'
                            : _getRegistrationMessage(tournament),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widgets and methods
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

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color;
    String text;

    switch (status) {
      case TournamentStatus.registration_open:
        color = Colors.green;
        text = 'Open';
        break;
      case TournamentStatus.registration_closed:
        color = Colors.orange;
        text = 'Closed';
        break;
      case TournamentStatus.active:
        color = Colors.blue;
        text = 'Active';
        break;
      case TournamentStatus.completed:
        color = Colors.grey;
        text = 'Finished';
        break;
      case TournamentStatus.upcoming:
        color = Colors.purple;
        text = 'Upcoming';
        break;
      default:
        color = Colors.grey;
        text = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Featured',
        style: TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNationalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'National',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildPrizeStructure(Map<String, dynamic> prizeStructure) {
    return prizeStructure.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'KSh ${entry.value.toString()}',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRegistrationInfo(Tournament tournament) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spots Available',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${tournament.spotsRemaining}',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: tournament.maxPlayers > 0
                ? tournament.currentPlayerCount / tournament.maxPlayers
                : 0,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            '${tournament.currentPlayerCount} of ${tournament.maxPlayers == 0 ? '∞' : tournament.maxPlayers} players registered',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTournamentIcon(TournamentType type) {
    switch (type) {
      case TournamentType.national:
        return Icons.flag;
      case TournamentType.professional:
        return Icons.emoji_events;
      case TournamentType.sponsored:
        return Icons.business;
      case TournamentType.regional:
        return Icons.location_city;
      case TournamentType.beginner:
        return Icons.school;
    }
  }

  Color _getTypeColor(TournamentType type) {
    switch (type) {
      case TournamentType.national:
        return Colors.red;
      case TournamentType.professional:
        return AppTheme.accentColor;
      case TournamentType.sponsored:
        return Colors.purple;
      case TournamentType.regional:
        return Colors.blue;
      case TournamentType.beginner:
        return Colors.green;
    }
  }

  String _getRegistrationMessage(Tournament tournament) {
    if (tournament.isFull) return 'Tournament Full';
    if (tournament.status == TournamentStatus.registration_closed)
      return 'Registration Closed';
    if (tournament.status == TournamentStatus.active)
      return 'Tournament Started';
    if (tournament.status == TournamentStatus.completed)
      return 'Tournament Finished';
    if (tournament.hasStarted) return 'Already Started';
    return 'Registration Not Available';
  }

  // Race condition safe registration
  Future<void> _handleRegistration(Tournament tournament, String userId) async {
    if (_isRegistering) return; // Prevent double registration

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
            userCommunityIds = [user!.communityId!];
          }
        },
      );

      // Check if user can access this tournament
      if (!tournament.isVisibleToUser(userId, userCommunityIds)) {
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

      // Navigate to payment with metadata
      PaymentMigrationHelper.navigateToUnifiedPayment(
        context,
        paymentType: payment_entity.PaymentType.tournament,
        typeId: tournament.id,
        userId: userId,
        amount: tournament.entryFee,
        metadata: {
          'tournamentName': tournament.name,
          'tournamentDate': tournament.dateRange,
          'tournamentVenue': tournament.primaryVenue,
          'tournamentType': tournament.typeDisplayName,
          'userCommunityId': currentUser?.communityId ?? '',
        },
        onSuccess: () {
          // Registration will be handled by payment success callback
          // Reset the registering state
          if (mounted) {
            setState(() => _isRegistering = false);
          }
          
          // Refresh tournament data and check registration status
          _tournamentBloc
              .add(LoadTournamentDetailsEvent(tournamentId: tournament.id));
          _tournamentBloc.add(CheckRegistrationStatusEvent(
            tournamentId: tournament.id,
            userId: userId,
          ));
        },
        onFailure: () {
          if (mounted) {
            setState(() => _isRegistering = false);
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
