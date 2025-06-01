import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../components/tournament_card.dart';
import '../payment/payment_page.dart';
import 'tournament_service.dart';

class TournamentScreenDirect extends StatefulWidget {
  const TournamentScreenDirect({Key? key}) : super(key: key);

  @override
  State<TournamentScreenDirect> createState() => _TournamentScreenDirectState();
}

class _TournamentScreenDirectState extends State<TournamentScreenDirect> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _error = '';
  
  // List to store tournaments
  List<Tournament> _tournaments = [];
  Tournament? _featuredTournament;
  
  // Tournament service
  final _tournamentService = TournamentService();
  
  // Current user ID
  final String _userId = 'user123';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tournaments when the screen initializes
    _loadTournaments();
    
    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadTournaments() async {
    print('DIRECT-SCREEN: Loading tournaments...');
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      // The TournamentService now handles all loading strategies
      final tournaments = await _tournamentService.getTournaments();
      
      setState(() {
        _tournaments = tournaments;
        _updateFeaturedTournament();
        _isLoading = false;
      });
      
      print('DIRECT-SCREEN: Loaded ${_tournaments.length} tournaments');
      if (_tournaments.isNotEmpty) {
        print('DIRECT-SCREEN: First tournament: ${_tournaments[0].name}');
        // Show success message if tournaments loaded successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournaments loaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('DIRECT-SCREEN: No tournaments loaded');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tournaments found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('DIRECT-SCREEN: Error loading tournaments: $e');
      
      setState(() {
        _isLoading = false;
        _error = 'Error loading tournaments: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tournaments: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _updateFeaturedTournament() {
    // First check for explicitly marked featured tournaments
    final explicitlyFeatured = _tournaments.where((t) => t.isFeatured).toList();
    
    if (explicitlyFeatured.isNotEmpty) {
      _featuredTournament = explicitlyFeatured.first;
      return;
    }
    
    // If no explicitly featured tournament, use the closest upcoming one
    final now = DateTime.now();
    final upcomingTournaments = _tournaments
        .where((t) => _parseDate(t.date).isAfter(now))
        .toList();
    
    if (upcomingTournaments.isNotEmpty) {
      upcomingTournaments.sort((a, b) => 
          _parseDate(a.date).compareTo(_parseDate(b.date)));
      _featuredTournament = upcomingTournaments.first;
    } else {
      _featuredTournament = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text('TOURNAMENTS (${_tournaments.length})'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Debug refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('DIRECT-SCREEN: Manual refresh triggered');
              _loadTournaments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing tournaments...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildBody(context),
    );
  }
  
  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tournaments...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        
        // Featured Tournament Card
        if (_featuredTournament != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TournamentCard(
              name: _featuredTournament!.name,
              type: _featuredTournament!.type,
              location: _featuredTournament!.location,
              dateRange: _featuredTournament!.date,
              players: _featuredTournament!.players,
              price: _featuredTournament!.price,
              isFeatured: true,
              onRegisterPressed: () {
                // Navigate to payment page for featured tournament
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      paymentType: 'tournament',
                      typeId: _featuredTournament!.id,
                      userId: _userId,
                      amount: _featuredTournament!.price,
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
    );
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
    print('DIRECT-SCREEN: Getting filtered tournaments: search="$searchQuery", upcoming=$upcoming, past=$past');
    print('DIRECT-SCREEN: Total tournaments before filtering: ${_tournaments.length}');
    
    final now = DateTime.now();
    
    final result = _tournaments.where((tournament) {
      // Apply date filter
      final tournamentDate = _parseDate(tournament.date);
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
    
    print('DIRECT-SCREEN: Tournaments after filtering: ${result.length}');
    return result;
  }

  Widget _buildTournamentList({bool upcoming = false, bool past = false}) {
    print('DIRECT-SCREEN: Building tournament list: upcoming=$upcoming, past=$past, search="$_searchQuery"');
    
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
            style: const TextStyle(
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
          final isRegistered = tournament.registeredUsers.contains(_userId);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              children: [
                TournamentCard(
                  name: tournament.name,
                  type: tournament.type,
                  location: tournament.location,
                  dateRange: tournament.date,
                  players: tournament.players,
                  price: tournament.price,
                  isRegistered: isRegistered,
                  onRegisterPressed: () async {
                    if (isRegistered) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('You are already registered for this tournament'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    } else {
                      // Navigate to payment page
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            paymentType: 'tournament',
                            typeId: tournament.id,
                            userId: _userId,
                            amount: tournament.price,
                          ),
                        ),
                      );
                      
                      // If payment was successful, register the user
                      if (result == true) {
                        final success = await _tournamentService.registerUserForTournament(
                          tournament.id,
                          _userId,
                        );
                        
                        if (success) {
                          // Reload tournaments to update UI
                          _loadTournaments();
                        }
                      }
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
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
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
