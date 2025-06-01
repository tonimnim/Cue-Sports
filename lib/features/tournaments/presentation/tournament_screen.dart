import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../presentation/bloc/tournament_bloc.dart';
import '../presentation/bloc/tournament_event.dart';
import '../presentation/bloc/tournament_state.dart';
import '../domain/entities/tournament.dart';
import '../../../navigation/bottom_navigation.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({Key? key}) : super(key: key);

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TournamentStatus? _selectedStatus;
  int _selectedIndex = 1; // Tournament tab index

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TournamentBloc>()
        ..add(LoadTournamentsEvent())
        ..add(LoadFeaturedTournamentsEvent()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F4A22),
        appBar: AppBar(
          title: const Text('Tournaments', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0F4A22),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                // Navigate to create tournament
                Navigator.pushNamed(context, '/create-tournament');
              },
            ),
          ],
        ),
        body: BlocBuilder<TournamentBloc, TournamentState>(
          builder: (context, state) {
            if (state is TournamentLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is TournamentError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading tournaments',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TournamentBloc>().add(LoadTournamentsEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is TournamentLoaded) {
              return _buildTournamentContent(context, state);
            }
            
            return const Center(
              child: Text('Welcome to Tournaments', style: TextStyle(color: Colors.white)),
            );
          },
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildTournamentContent(BuildContext context, TournamentLoaded state) {
    List<Tournament> filteredTournaments = _getFilteredTournaments(state.tournaments);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 20),
          
          // Status filter
          _buildStatusFilter(),
          const SizedBox(height: 20),
          
          // Featured tournaments section
          if (state.featuredTournaments.isNotEmpty) ...[
            _buildSectionHeader('Featured Tournaments'),
            const SizedBox(height: 10),
            _buildTournamentGrid(state.featuredTournaments.take(2).toList()),
            const SizedBox(height: 20),
          ],
          
          // All tournaments section
          _buildSectionHeader('All Tournaments'),
          const SizedBox(height: 10),
          _buildTournamentGrid(filteredTournaments),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search tournaments...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusChip('All', null),
          const SizedBox(width: 8),
          _buildStatusChip('Open', TournamentStatus.registration_open),
          const SizedBox(width: 8),
          _buildStatusChip('Upcoming', TournamentStatus.upcoming),
          const SizedBox(width: 8),
          _buildStatusChip('In Progress', TournamentStatus.in_progress),
          const SizedBox(width: 8),
          _buildStatusChip('Completed', TournamentStatus.completed),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, TournamentStatus? status) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF0F4A22),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0F4A22),
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

  Widget _buildTournamentGrid(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No tournaments found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildTournamentCard(tournament),
        );
      },
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament header
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4A22),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(tournament.status),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tournament details
            Row(
              children: [
                const Icon(Icons.sports_esports, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    tournament.type,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    tournament.location,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date and players
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament.dateRange,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.currentPlayerCount}/${tournament.maxPlayers} players',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Entry fee and register button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Entry Fee: KSh ${tournament.entryFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4A22),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: tournament.canRegister
                        ? () => _handleTournamentRegistration(tournament)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4A22),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      tournament.canRegister ? 'Register' : 'Full',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color badgeColor;
    String statusText;
    
    switch (status) {
      case TournamentStatus.upcoming:
        badgeColor = Colors.blue;
        statusText = 'Upcoming';
        break;
      case TournamentStatus.registration_open:
        badgeColor = Colors.green;
        statusText = 'Open';
        break;
      case TournamentStatus.registration_closed:
        badgeColor = Colors.orange;
        statusText = 'Closed';
        break;
      case TournamentStatus.in_progress:
        badgeColor = Colors.purple;
        statusText = 'Live';
        break;
      case TournamentStatus.completed:
        badgeColor = Colors.grey;
        statusText = 'Completed';
        break;
      case TournamentStatus.cancelled:
        badgeColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Tournament> _getFilteredTournaments(List<Tournament> tournaments) {
    List<Tournament> filtered = tournaments;
    
    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((tournament) => tournament.status == _selectedStatus).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tournament) {
        return tournament.name.toLowerCase().contains(_searchQuery) ||
               tournament.type.toLowerCase().contains(_searchQuery) ||
               tournament.location.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    return filtered;
  }

  void _handleTournamentRegistration(Tournament tournament) {
    // Navigate to tournament registration/payment
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'paymentType': 'tournament_registration',
        'typeId': tournament.id,
        'userId': 'current_user', // Get from auth
        'amount': tournament.entryFee,
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Tournaments
        // Already on tournaments
        break;
      case 2: // Communities
        Navigator.pushReplacementNamed(context, '/communities');
        break;
      case 3: // Shop
        Navigator.pushReplacementNamed(context, '/shop');
        break;
    }
  }
} 