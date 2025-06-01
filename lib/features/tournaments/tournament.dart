import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/tournament_provider.dart';
import '../../../navigation/bottom_navigation.dart';
import 'models/tournament.dart';
import 'components/tournament_card.dart';
import 'components/search_bar.dart';
import 'payment/payment_page.dart';
import 'direct_implementation/tournament_service.dart';
import '../../../core/services/refresh_service.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({Key? key}) : super(key: key);

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> with SingleTickerProviderStateMixin {
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
  // TODO: Replace with actual user authentication in the future
  final String _userId = 'user123';
  
  // Community that the current user belongs to
  // TODO: In a production app, this would be fetched from a user profile in Firestore
  // TODO: This should be loaded dynamically based on the authenticated user
  // For testing: user123 is a member of community1 (can see "Elite Community Cup")
  final String _userCommunity = 'community1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tournaments when the screen initializes
    // Use Future.microtask to ensure the context is fully built before showing snackbars
    Future.microtask(() {
      _loadTournaments();
    });
    
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
        // No success message to keep UI clean
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
  
  // Handle pull-to-refresh using RefreshService
  Future<void> _handleRefresh() async {
    // Use the RefreshService to handle refresh logic
    return RefreshService.createRefreshCallback(
      fetchData: () => _tournamentService.getTournaments(),
      updateState: (data) {
        setState(() {
          _tournaments = data;
          _updateFeaturedTournament();
          _error = '';
        });
      },
      onError: (error) {
        setState(() {
          _error = 'Error refreshing tournaments: $error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
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
    return GestureDetector(
      // Add gesture detector to dismiss keyboard when tapping outside text fields
      onTap: () {
        // Hide keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tournaments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTournaments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // For determining if tournaments are past
    final now = DateTime.now();
    
    return Column(
      children: [
        // App header with title and notification icon
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tournaments',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                onPressed: () {
                  // Handle notification button press
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notifications coming soon!'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Search tournaments',
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        

        
        // Tab Bar - Horizontal fill layout with yellow selection
        Container(
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.onSecondary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            padding: EdgeInsets.zero,
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
              _buildTournamentList(upcoming: false, past: false, featuredTournament: _featuredTournament),
              _buildTournamentList(upcoming: true, past: false),
              _buildTournamentList(upcoming: false, past: true),
            ],
          ),
        ),
      ],
    );
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      print('DIRECT-SCREEN: Empty or null date string');
      // Return a far future date if date is null or empty
      return DateTime(9999);
    }
    
    try {
      // Expected format: "May 30, 2025"
      final parts = dateStr.split(' ');
      
      if (parts.length < 3) {
        print('DIRECT-SCREEN: Invalid date format: $dateStr');
        return DateTime(9999);
      }
      
      final month = parts[0]; // "May"
      int day = int.parse(parts[1].replaceAll(',', '')); // "30"
      int year = int.parse(parts[2]); // "2025"
      
      int monthNumber = _getMonthNumber(month);
      
      return DateTime(year, monthNumber, day);
    } catch (e) {
      print('DIRECT-SCREEN: Error parsing date: $e');
      // Return a far future date if parsing fails
      return DateTime(9999);
    }
  }

  int _getMonthNumber(String month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    int index = months.indexOf(month.substring(0, 3));
    return index != -1 ? index + 1 : 1; // Default to January if not found
  }
  
  // Check if the user is allowed to access this tournament
  bool _isUserAllowedToAccessTournament(Tournament tournament) {
    // If the tournament is public, all users can access it
    if (tournament.isPublic) {
      print('DIRECT-SCREEN: Tournament ${tournament.name} is public - ACCESS GRANTED');
      return true;
    }
    
    print('DIRECT-SCREEN: Tournament ${tournament.name} is NOT public - checking communities');
    print('DIRECT-SCREEN: Tournament communities: ${tournament.communities}');
    print('DIRECT-SCREEN: User community: $_userCommunity');
    
    // If the tournament is not public, check if the user belongs to any of its communities
    if (tournament.communities.isEmpty) {
      print('DIRECT-SCREEN: Tournament ${tournament.name} has no communities but is not public - ACCESS DENIED');
      return false; // No communities specified, but tournament is not public
    }
    
    // Check if the tournament is available for the user's community
    if (tournament.communities.contains(_userCommunity)) {
      print('DIRECT-SCREEN: Tournament includes user\'s community $_userCommunity - ACCESS GRANTED');
      return true; // Tournament is available for the user's community
    }
    
    print('DIRECT-SCREEN: User\'s community $_userCommunity is not included in tournament communities - ACCESS DENIED');
    return false; // Tournament is not available for the user's community
  }

  List<Tournament> _getFilteredTournaments({
    required String searchQuery,
    bool upcoming = false,
    bool past = false,
  }) {
    print('DIRECT-SCREEN: Getting filtered tournaments: search="$searchQuery", upcoming=$upcoming, past=$past');
    print('DIRECT-SCREEN: Total tournaments before filtering: ${_tournaments.length}');
    
    final now = DateTime.now();
    
    final result = _tournaments.where((tournament) {
      // First, check if the tournament is accessible to this user
      if (!_isUserAllowedToAccessTournament(tournament)) {
        return false;
      }

      // Parse start and end dates
      final tournamentStartDate = _parseDate(tournament.startDate);
      final tournamentEndDate = _parseDate(tournament.endDate);
      
      // A tournament is considered past if its end date is before today
      final isPast = tournamentEndDate.isBefore(now);
      
      // A tournament is upcoming/ongoing if either its start date or end date is after today
      final isUpcomingOrOngoing = tournamentStartDate.isAfter(now) || tournamentEndDate.isAfter(now);
      
      print('DIRECT-SCREEN: Tournament ${tournament.name} - Start: ${tournament.startDate}, End: ${tournament.endDate}, isPast: $isPast, isUpcomingOrOngoing: $isUpcomingOrOngoing');
      
      if (upcoming && !isUpcomingOrOngoing) return false;
      if (past && !isPast) return false;
      
      // Apply search query
      if (searchQuery.isEmpty) return true;
      
      final query = searchQuery.toLowerCase();
      return tournament.name.toLowerCase().contains(query) ||
          tournament.type.toLowerCase().contains(query) ||
          tournament.location.toLowerCase().contains(query);
    }).toList();
    
    // Sort tournaments by updatedAt date, most recent first
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    // Debug log to verify sorting
    if (result.isNotEmpty) {
      print('DIRECT-SCREEN: Tournaments after filtering and sorting: ${result.length}');
      print('DIRECT-SCREEN: Top 3 tournaments by update date:');
      for (int i = 0; i < (result.length > 3 ? 3 : result.length); i++) {
        print('DIRECT-SCREEN:   ${i+1}. ${result[i].name} - Updated: ${result[i].updatedAt}');
      }
    }
    return result;
  }

  Widget _buildTournamentList({bool upcoming = false, bool past = false, Tournament? featuredTournament}) {
    print('DIRECT-SCREEN: Building tournament list: upcoming=$upcoming, past=$past, search="$_searchQuery"');
    
    final tournaments = _getFilteredTournaments(
      searchQuery: _searchQuery,
      upcoming: upcoming,
      past: past,
    );
    
    final now = DateTime.now();
    
    if (tournaments.isEmpty) {
      return Center(
        child: Text(
            _searchQuery.isNotEmpty
                ? 'No tournaments match your search'
                : upcoming
                    ? 'No upcoming tournaments available'
                    : past
                        ? 'No past tournaments available'
                        : 'No tournaments available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
            ),
          ),
        );
    }

    return RefreshService.buildRefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Include the featured tournament at the top if this is the first tab and we have a featured tournament
        if (featuredTournament != null && !upcoming && !past)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TournamentCard(
              name: featuredTournament.name,
              type: featuredTournament.type,
              location: featuredTournament.location,
              dateRange: featuredTournament.dateRange,  // Use the dateRange property
              players: featuredTournament.players,
              price: featuredTournament.price,
              isFeatured: true,
              isRegistered: featuredTournament.registeredUsers.contains(_userId),
              isPast: _parseDate(featuredTournament.endDate).isBefore(DateTime.now()),  // Past if end date is before now
              onRegisterPressed: () async {
                final isRegistered = featuredTournament.registeredUsers.contains(_userId);
                
                if (isRegistered) {
                  // Already registered, show message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('You are already registered for this tournament'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } else {
                  // Navigate to payment page for featured tournament
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        paymentType: 'tournament',
                        typeId: featuredTournament.id,
                        userId: _userId,
                        amount: featuredTournament.price,
                      ),
                    ),
                  );
                  
                  // If payment was successful, register the user
                  if (result == true) {
                    final success = await _tournamentService.registerUserForTournament(
                      featuredTournament.id,
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
          ),
        ...tournaments.map((tournament) {
          final isRegistered = tournament.registeredUsers.contains(_userId);
          
          // Determine if tournament is in the past - use the endDate for determining if it's past
          final tournamentEndDate = _parseDate(tournament.endDate);
          final isPast = tournamentEndDate.isBefore(now);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TournamentCard(
              name: tournament.name,
              type: tournament.type,
              location: tournament.location,
              dateRange: tournament.dateRange,  // Use the dateRange property
              players: tournament.players,
              price: tournament.price,
              isFeatured: false,
              isRegistered: isRegistered,
              isPast: isPast,  // Past if end date is before now
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
          );
        }).toList(),
      ],
    ),
    );
  }
}
