import 'package:flutter/material.dart';
import '../components/tournament_card.dart';
import '../components/search_bar.dart';
import '../domain/entities/tournament.dart';
import '../payment/payment_page.dart';
import '../services/hard_coded_tournaments.dart';

// This is a standalone implementation of the tournament screen
// that directly uses hardcoded data instead of relying on the provider
class DirectTournamentScreen extends StatefulWidget {
  const DirectTournamentScreen({Key? key}) : super(key: key);

  @override
  State<DirectTournamentScreen> createState() => _DirectTournamentScreenState();
}

class _DirectTournamentScreenState extends State<DirectTournamentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Directly load tournaments without provider
  final List<Tournament> _tournaments = HardCodedTournaments.getSampleTournaments();
  
  // Current user ID
  final String _userId = 'user123';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    print('DirectTournamentScreen: Loaded ${_tournaments.length} tournaments directly');
    
    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get featured tournament (closest upcoming or explicitly featured)
    final featuredTournament = _getFeaturedTournament();
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text('TOURNAMENTS (${_tournaments.length})'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search tournaments...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Featured Tournament Card
          if (featuredTournament != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TournamentCard(
                name: featuredTournament.name,
                type: featuredTournament.type,
                location: featuredTournament.location,
                dateRange: featuredTournament.dateRange,
                players: featuredTournament.maxPlayers,
                price: featuredTournament.entryFee,
                isFeatured: true,
                onRegisterPressed: () {
                  // Navigate to payment page for featured tournament
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        paymentType: 'tournament',
                        typeId: featuredTournament.id,
                        userId: _userId,
                        amount: featuredTournament.entryFee,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Tab Bar - Horizontal fill layout with yellow selection
          Container(
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(upcoming: false, past: false),
                _buildTournamentList(upcoming: true, past: false),
                _buildTournamentList(upcoming: false, past: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get featured tournament (most recent upcoming or marked as featured)
  Tournament? _getFeaturedTournament() {
    // First check if any tournament is explicitly marked as featured
    final explicitlyFeatured = _tournaments.where((t) => t.isFeatured).toList();
    if (explicitlyFeatured.isNotEmpty) {
      return explicitlyFeatured.first;
    }
    
    // If no tournament is marked as featured, use the closest upcoming one
    final now = DateTime.now();
    final upcomingTournaments = _tournaments
        .where((t) => _parseDate(t.dateRange).isAfter(now))
        .toList();
    
    if (upcomingTournaments.isNotEmpty) {
      upcomingTournaments.sort((a, b) => 
          _parseDate(a.dateRange).compareTo(_parseDate(b.dateRange)));
      return upcomingTournaments.first;
    }
    
    return null;
  }
  
  // Helper method to parse date string
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(', ');
      if (parts.length >= 2) {
        final date = parts[0].split(' ');
        final month = _getMonthNumber(date[0]);
        final day = int.parse(date[1].replaceAll(',', ''));
        final year = int.parse(parts[1]);
        return DateTime(year, month, day);
      }
      
      // Handle format: 'Apr 15 2025' or similar
      final spaceParts = dateStr.split(' ');
      if (spaceParts.length >= 3) {
        final month = _getMonthNumber(spaceParts[0]);
        final day = int.parse(spaceParts[1].replaceAll(',', ''));
        final year = int.parse(spaceParts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }
    
    return DateTime.now(); // Default to current date on parsing error
  }

  // Helper to convert month name to number
  int _getMonthNumber(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return months[month] ?? 1;
  }

  // Get filtered tournaments
  List<Tournament> _getFilteredTournaments({
    required String searchQuery,
    bool upcoming = false,
    bool past = false,
  }) {
    print('DirectScreen: getFilteredTournaments called: search="$searchQuery", upcoming=$upcoming, past=$past');
    print('DirectScreen: Total tournaments before filtering: ${_tournaments.length}');
    
    final now = DateTime.now();
    
    final result = _tournaments.where((tournament) {
      // Apply date filter
      final tournamentDate = _parseDate(tournament.dateRange);
      final isPast = tournamentDate.isBefore(now);
      
      if (upcoming && isPast) return false;
      if (past && !isPast) return false;
      
      // Apply search query
      if (searchQuery.isEmpty) return true;
      
      final query = searchQuery.toLowerCase();
      return tournament.name.toLowerCase().contains(query) ||
          tournament.type.toLowerCase().contains(query) ||
          tournament.location.toLowerCase().contains(query);
    }).toList();
    
    print('DirectScreen: Tournaments after filtering: ${result.length}');
    return result;
  }

  Widget _buildTournamentList({bool upcoming = false, bool past = false}) {
    print('DirectScreen: _buildTournamentList called: upcoming=$upcoming, past=$past, search="$_searchQuery"');
    
    final tournaments = _getFilteredTournaments(
      searchQuery: _searchQuery,
      upcoming: upcoming,
      past: past,
    );

    if (tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No tournaments match your search'
                : upcoming
                    ? 'No upcoming tournaments'
                    : past
                        ? 'No past tournaments'
                        : 'No tournaments available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...tournaments.map((tournament) {
          final isRegistered = tournament.isUserRegistered(_userId);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              children: [
                TournamentCard(
                  name: tournament.name,
                  type: tournament.type,
                  location: tournament.location,
                  dateRange: tournament.dateRange,
                  players: tournament.maxPlayers,
                  price: tournament.entryFee,
                  onRegisterPressed: () {
                    if (isRegistered) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are already registered for this tournament'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    } else {
                      // Navigate to payment page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            paymentType: 'tournament',
                            typeId: tournament.id,
                            userId: _userId,
                            amount: tournament.entryFee,
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Show a badge if the user is registered
                if (isRegistered)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Registered',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
