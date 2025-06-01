import 'package:flutter/material.dart';
import 'package:pool_billiard_app/features/tournaments/models/tournament.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TournamentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = 'user123'; // Hardcoded user ID for now
  
  List<Tournament> _tournaments = [];
  List<Tournament> get tournaments => _tournaments;
  
  // Featured tournament (the most recent upcoming tournament)
  Tournament? _featuredTournament;
  Tournament? get featuredTournament => _featuredTournament;

  // Firebase project ID
  final String _projectId = 'poolbilliard-167ad';
  final String _baseUrl = 'https://firestore.googleapis.com/v1/projects/poolbilliard-167ad/databases/(default)/documents';
  
  // Constructor
  TournamentProvider() {
    // Load tournaments from Firestore
    print('TournamentProvider: Initializing...');
    
    // Load directly from Firebase
    print('TournamentProvider: Starting tournament loading...');
    // Try direct query first, then fallback to HTTP if needed
    loadDirectTournaments();
  }
  
  // This method is no longer used - we load directly from Firebase
  // Keeping the method signature for backward compatibility
  void _loadHardcodedData() {
    // No longer using hardcoded data
  }

  // Load tournaments from Firestore
  Future<void> loadTournaments() async {
    try {
      print('PROVIDER: Loading tournaments from Firestore...');
      print('PROVIDER: Project ID: poolbilliard-167ad');
      
      // First, try a direct query on the main collection to see what's happening
      try {
        print('PROVIDER: Testing direct Firestore access...');
        final testQuery = await _firestore.collection('orders').limit(1).get();
        print('PROVIDER: Firestore connection test - orders collection has ${testQuery.docs.length} documents');
      } catch (e) {
        print('PROVIDER: ❌ Error accessing Firestore: $e');
      }
      
      // Try different possible collection names
      final possibleCollectionNames = [
        'tournaments',  // Our standard name
        'Tournaments',  // Capitalized version
        'tournament',   // Singular version
        'Tournament',   // Capitalized singular
      ];
      
      List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs;
      String usedCollection = '';
      
      // Try each collection name until we find one with documents
      for (final collectionName in possibleCollectionNames) {
        print('PROVIDER: Trying collection: $collectionName');
        try {
          final snapshot = await _firestore.collection(collectionName).get();
          print('PROVIDER: Collection "$collectionName" has ${snapshot.docs.length} documents');
          
          if (snapshot.docs.isNotEmpty) {
            print('PROVIDER: ✅ Found ${snapshot.docs.length} documents in "$collectionName" collection');
            docs = snapshot.docs;
            usedCollection = collectionName;
            break;
          }
        } catch (e) {
          print('PROVIDER: ❌ Error querying "$collectionName": $e');
        }
      }
      
      // If we still don't have docs, use the original collection name for consistent error reporting
      if (docs == null) {
        print('WARNING: No tournaments found in any of the tried collections!');
        final snapshot = await _firestore.collection('tournaments').get();
        docs = snapshot.docs;
        usedCollection = 'tournaments';
        
        // Try to check if any collections exist
        try {
          // Check for other collections we know exist
          final ordersCollection = await _firestore.collection('orders').limit(1).get();
          print('Orders collection has documents: ${ordersCollection.docs.isNotEmpty}');
          
          // Try to list a few more collections
          final productsCheck = await _firestore.collection('products').limit(1).get();
          print('Products collection has documents: ${productsCheck.docs.isNotEmpty}');
          
          final usersCheck = await _firestore.collection('users').limit(1).get();
          print('Users collection has documents: ${usersCheck.docs.isNotEmpty}');
        } catch (e) {
          print('Error checking collections: $e');
        }
      }
      
      // Print the raw data of the first tournament to help debug
      if (docs.isNotEmpty) {
        print('Example tournament document:');
        print(docs.first.data());
      }
      
      final List<Tournament> loadedTournaments = [];
      
      // Process each document with error handling
      for (var doc in docs) {
        try {
          final tournament = Tournament.fromMap(doc.data(), doc.id);
          loadedTournaments.add(tournament);
        } catch (e) {
          print('Error parsing tournament ${doc.id}: $e');
          print('Document data: ${doc.data()}');
        }
      }
      
      _tournaments = loadedTournaments;
      print('Tournaments successfully loaded: ${_tournaments.length} from "$usedCollection" collection');
      
      // If we loaded tournaments successfully, save the collection name for next time
      if (_tournaments.isNotEmpty) {
        print('SUCCESS: Using "$usedCollection" as the tournament collection');
      }
      
      // Debug output for tournaments
      for (var t in _tournaments) {
        print('Tournament: ${t.name}, Date: ${t.date}, ID: ${t.id}');
        print('  Price: ${t.price.toStringAsFixed(2)}, Players: ${t.players}');
        print('  Registered users: ${t.registeredUsers.length}');
      }
      
      // If no tournaments were loaded but we did find a collection, try to add sample data
      if (_tournaments.isEmpty && usedCollection.isNotEmpty) {
        print('WARNING: No tournaments loaded successfully. Attempting to add sample data...');
        await _addSampleTournamentsToFirestore(usedCollection);
        // Try loading again after adding sample data
        return loadTournaments();
      }
      
      _updateFeaturedTournament();
      print('Featured tournament: ${_featuredTournament?.name ?? "None"}');
      
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error loading tournaments: $e');
      print('Stack trace: $stackTrace');
      // Initialize with empty list if Firebase fails
      _tournaments = [];
      _featuredTournament = null;
      notifyListeners();
    }
  }

  // Register user for a tournament
  Future<bool> registerForTournament(String tournamentId) async {
    try {
      // Add user to the tournament's registered users
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'registeredUsers': FieldValue.arrayUnion([_userId])
      });
      
      // Also add to user-tournament mapping collection
      await _firestore.collection('tournament_registrations').add({
        'userId': _userId,
        'tournamentId': tournamentId,
        'registeredAt': DateTime.now(),
        'paymentStatus': 'completed',
      });
      
      // Update local data
      await loadTournaments();
      return true;
    } catch (e) {
      print('Error registering for tournament: $e');
      return false;
    }
  }

  // Check if user is registered for a tournament
  bool isUserRegistered(String tournamentId) {
    try {
      final tournament = _tournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => Tournament(
          id: '',
          name: '',
          type: '',
          location: '',
          startDate: '',
          endDate: '',
          players: 0,
          price: 0,
          registeredUsers: [],
        ),
      );
      
      final isRegistered = tournament.isUserRegistered(_userId);
      print('User $_userId registration status for ${tournament.name}: $isRegistered');
      return isRegistered;
    } catch (e) {
      print('Error checking user registration: $e');
      return false;
    }
  }

  // Get filtered tournaments
  List<Tournament> getFilteredTournaments({
    required String searchQuery,
    bool upcoming = false,
    bool past = false,
  }) {
    print('getFilteredTournaments called: search="$searchQuery", upcoming=$upcoming, past=$past');
    print('Total tournaments before filtering: ${_tournaments.length}');
    final now = DateTime.now();
    print('Current date for filtering: $now');
    
    final result = _tournaments.where((tournament) {
      // Apply date filter
      final tournamentDate = _parseDate(tournament.date);
      final isPast = tournamentDate.isBefore(now);
      
      print('Tournament: ${tournament.name}, date: ${tournament.date}, parsed: $tournamentDate, isPast: $isPast');
      
      if (upcoming && isPast) {
        print('Filtered out: ${tournament.name} (upcoming filter, but is past)');
        return false;
      }
      if (past && !isPast) {
        print('Filtered out: ${tournament.name} (past filter, but is upcoming)');
        return false;
      }
      
      // Apply search query
      if (searchQuery.isEmpty) return true;
      
      final query = searchQuery.toLowerCase();
      final matchesName = tournament.name.toLowerCase().contains(query);
      final matchesType = tournament.type.toLowerCase().contains(query);
      final matchesLocation = tournament.location.toLowerCase().contains(query);
      
      final matches = matchesName || matchesType || matchesLocation;
      if (!matches) {
        print('Filtered out: ${tournament.name} (doesn\'t match search "$searchQuery")');
      }
      
      return matches;
    }).toList();
    
    print('Tournaments after filtering: ${result.length}');
    return result;
  }

  // Helper method to parse date string
  DateTime _parseDate(String dateStr) {
    try {
      print('Parsing date: $dateStr');
      
      // Handle format: 'Apr 15, 2025'
      final parts = dateStr.split(', ');
      if (parts.length >= 2) {
        final date = parts[0].split(' ');
        final month = _getMonthNumber(date[0]);
        final day = int.parse(date[1].replaceAll(',', ''));
        final year = int.parse(parts[1]);
        print('Parsed date as: $year-$month-$day');
        return DateTime(year, month, day);
      }
      
      // Handle format: 'Apr 15 2025' or similar
      final spaceParts = dateStr.split(' ');
      if (spaceParts.length >= 3) {
        final month = _getMonthNumber(spaceParts[0]);
        final day = int.parse(spaceParts[1].replaceAll(',', ''));
        final year = int.parse(spaceParts[2]);
        print('Parsed date as: $year-$month-$day');
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }
    
    print('Failed to parse date, using current date');
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

  // Update the featured tournament (most recent upcoming or marked as featured)
  void _updateFeaturedTournament() {
    final now = DateTime.now();
    
    // First check if any tournament is explicitly marked as featured
    final explicitlyFeatured = _tournaments.where((t) => t.isFeatured).toList();
    if (explicitlyFeatured.isNotEmpty) {
      _featuredTournament = explicitlyFeatured.first;
      print('Found explicitly featured tournament: ${_featuredTournament?.name}');
      return;
    }
    
    // If no tournament is marked as featured, use the closest upcoming one
    final upcomingTournaments = _tournaments
        .where((t) => _parseDate(t.date).isAfter(now))
        .toList();
    
    if (upcomingTournaments.isNotEmpty) {
      upcomingTournaments.sort((a, b) => 
          _parseDate(a.date).compareTo(_parseDate(b.date)));
      
      _featuredTournament = upcomingTournaments.first;
      print('Setting closest upcoming tournament as featured: ${_featuredTournament?.name}');
    } else {
      _featuredTournament = null;
      print('No upcoming tournaments found to feature');
    }
  }

  // This method is kept for reference but no longer used since we load data from Firestore
  // DO NOT CALL THIS METHOD
  void _initSampleData() {
    // This method is no longer used since we load data from Firestore
    print('WARNING: _initSampleData called but should not be used anymore');
  }
  
  // Helper method to add sample tournaments to Firestore if none exist
  Future<void> _addSampleTournamentsToFirestore(String collectionName) async {
    try {
      print('Adding sample tournaments to Firestore collection "$collectionName"...');
      
      // Create past tournaments (3)
      final List<Map<String, dynamic>> pastTournaments = [
        {
          'name': 'Winter Championship',
          'type': 'Premier League',
          'location': 'Downtown Center',
          'date': 'Feb 15, 2025',
          'players': 32,
          'price': 30.50,
          'isFeatured': false,
          'registeredUsers': [],
        },
        {
          'name': 'Spring Series',
          'type': 'Amateur League',
          'location': 'Eastside Hall',
          'date': 'Mar 22, 2025',
          'players': 24,
          'price': 25.00,
          'isFeatured': false,
          'registeredUsers': [],
        },
        {
          'name': 'National Championship Finals',
          'type': 'Professional',
          'location': 'Central Arena',
          'date': 'Apr 10, 2025',
          'players': 48,
          'price': 40.00,
          'isFeatured': true, // This is the featured tournament
          'registeredUsers': [],
        },
      ];
      
      // Create upcoming tournaments (3)
      final List<Map<String, dynamic>> upcomingTournaments = [
        {
          'name': 'Summer Open',
          'type': 'Open League',
          'location': 'Westside Club',
          'date': 'May 30, 2025',
          'players': 32,
          'price': 20.00,
          'isFeatured': false,
          'registeredUsers': [],
        },
        {
          'name': 'Regional Championship',
          'type': 'Elite Series',
          'location': 'Downtown Center',
          'date': 'Jun 15, 2025',
          'players': 16,
          'price': 35.00,
          'isFeatured': false,
          'registeredUsers': [],
        },
        {
          'name': 'International Cup',
          'type': 'Invitational',
          'location': 'Grand Hall',
          'date': 'Jul 5, 2025',
          'players': 64,
          'price': 50.00,
          'isFeatured': false,
          'registeredUsers': [],
        },
      ];
      
      // Add all tournaments to Firestore
      for (var tournament in [...pastTournaments, ...upcomingTournaments]) {
        await _firestore.collection(collectionName).add(tournament);
        print('Added tournament: ${tournament['name']}');
      }
      
      print('Sample tournaments added successfully!');
    } catch (e) {
      print('Error adding sample tournaments: $e');
    }
  }

  // Get current user ID
  String getCurrentUserId() {
    return _userId;
  }
  
  // Load tournaments directly using Firebase SDK with simple approach
  Future<void> loadDirectTournaments() async {
    print('DIRECT-QUERY: Attempting to load tournaments directly from Firestore...');
    try {
      // Try different collection names
      final collectionNames = ['tournaments', 'Tournaments', 'tournament', 'Tournament'];
      
      for (final collectionName in collectionNames) {
        print('DIRECT-QUERY: Trying collection "$collectionName"...');
        try {
          // Create a simple query that matches our test data
          final query = _firestore.collection(collectionName)
              .where('name', isGreaterThanOrEqualTo: 'Test')
              .limit(10);
          
          final snapshot = await query.get();
          print('DIRECT-QUERY: Found ${snapshot.docs.length} documents in "$collectionName"');
          
          if (snapshot.docs.isNotEmpty) {
            final List<Tournament> loadedTournaments = [];
            
            for (var doc in snapshot.docs) {
              try {
                final data = doc.data();
                print('DIRECT-QUERY: Document data: $data');
                
                // Extract date fields, handling both new and legacy formats
                String startDate = data['startDate'] ?? '';
                String endDate = data['endDate'] ?? '';
                
                // If using legacy format with only 'date', use it for both start and end
                if (startDate.isEmpty && data['date'] != null) {
                  startDate = data['date'];
                  endDate = data['date'];
                }
                
                final tournament = Tournament(
                  id: doc.id,
                  name: data['name'] ?? '',
                  type: data['type'] ?? '',
                  location: data['location'] ?? '',
                  startDate: startDate,
                  endDate: endDate,
                  players: data['players'] is int ? data['players'] : int.tryParse(data['players']?.toString() ?? '0') ?? 0,
                  price: data['price'] is double ? data['price'] : double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
                  isFeatured: data['isFeatured'] ?? false,
                  registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
                );
                
                loadedTournaments.add(tournament);
                print('DIRECT-QUERY: Successfully parsed tournament: ${tournament.name}');
              } catch (e) {
                print('DIRECT-QUERY: Error parsing tournament: $e');
              }
            }
            
            if (loadedTournaments.isNotEmpty) {
              _tournaments = loadedTournaments;
              print('DIRECT-QUERY: Successfully loaded ${_tournaments.length} tournaments');
              _updateFeaturedTournament();
              notifyListeners();
              return; // Exit if we found tournaments
            }
          }
        } catch (e) {
          print('DIRECT-QUERY: Error querying "$collectionName": $e');
        }
      }
      
      // If we didn't find any tournaments, try a different approach
      print('DIRECT-QUERY: No tournaments found via direct query, trying to get all documents...');
      final snapshot = await _firestore.collection('tournaments').get();
      print('DIRECT-QUERY: Found ${snapshot.docs.length} total documents in "tournaments"');
      
      if (snapshot.docs.isNotEmpty) {
        final List<Tournament> loadedTournaments = [];
        
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            
            // Handle both new format and legacy format
            String startDate = data['startDate'] ?? '';
            String endDate = data['endDate'] ?? '';
            
            // If we have legacy format with only 'date'
            if (startDate.isEmpty && data['date'] != null) {
              startDate = data['date'];
              endDate = data['date'];
            }
            
            final tournament = Tournament(
              id: doc.id,
              name: data['name'] ?? '',
              type: data['type'] ?? '',
              location: data['location'] ?? '',
              startDate: startDate,
              endDate: endDate,
              players: data['players'] is int ? data['players'] : int.tryParse(data['players']?.toString() ?? '0') ?? 0,
              price: data['price'] is double ? data['price'] : double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
              isFeatured: data['isFeatured'] ?? false,
              registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
            );
            
            loadedTournaments.add(tournament);
          } catch (e) {
            print('DIRECT-QUERY: Error parsing tournament: $e');
          }
        }
        
        if (loadedTournaments.isNotEmpty) {
          _tournaments = loadedTournaments;
          print('DIRECT-QUERY: Successfully loaded ${_tournaments.length} tournaments');
          _updateFeaturedTournament();
          notifyListeners();
          return;
        }
      }
      
      // If all direct methods fail, try HTTP
      print('DIRECT-QUERY: No tournaments found using direct methods, trying HTTP...');
      await loadTournamentsViaHttp();
      
    } catch (e) {
      print('DIRECT-QUERY: Error: $e');
      // Try HTTP method as fallback
      await loadTournamentsViaHttp();
    }
  }
  
  // Load tournaments using direct HTTP requests (similar to simple_tournament_test.dart)
  Future<void> loadTournamentsViaHttp() async {
    print('PROVIDER-HTTP: Loading tournaments via direct HTTP...');
    print('PROVIDER-HTTP: URL = $_baseUrl/tournaments');
    
    try {
      // First try to call a simpler endpoint to check connectivity
      try {
        print('PROVIDER-HTTP: Testing HTTP connectivity...');
        final testResponse = await http.get(Uri.parse('https://www.google.com'));
        print('PROVIDER-HTTP: Connectivity test status: ${testResponse.statusCode}');
      } catch (e) {
        print('PROVIDER-HTTP: Connectivity test failed: $e');
      }
      
      // Use the same approach as in simple_tournament_test.dart
      final url = '$_baseUrl/tournaments?pageSize=50';
      print('PROVIDER-HTTP: Calling Firestore API at $url');
      
      // Add a timeout to the HTTP request
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('PROVIDER-HTTP: Request timed out');
          throw Exception('Request timed out');
        },
      );
      
      print('PROVIDER-HTTP: Response status: ${response.statusCode}');
      print('PROVIDER-HTTP: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('PROVIDER-HTTP: Response body length: ${response.body.length}');
        print('PROVIDER-HTTP: Response body sample: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
        
        final data = json.decode(response.body);
        print('PROVIDER-HTTP: Successfully parsed JSON response');
        
        if (data.containsKey('documents') && data['documents'] is List) {
          final List<Tournament> loadedTournaments = [];
          final docs = data['documents'] as List;
          print('PROVIDER-HTTP: Found ${docs.length} tournaments');
          
          for (var doc in docs) {
            try {
              final String docPath = doc['name'];
              final String docId = docPath.split('/').last;
              final fields = doc['fields'];
              
              // Extract values using the helper methods
              final name = _getStringValue(fields, 'name');
              final type = _getStringValue(fields, 'type');
              final location = _getStringValue(fields, 'location');
              final date = _getStringValue(fields, 'date');
              final players = _getIntValue(fields, 'players');
              final price = _getDoubleValue(fields, 'price');
              final isFeatured = _getBoolValue(fields, 'isFeatured');
              final registeredUsers = _getStringArrayValue(fields, 'registeredUsers');
              
              print('PROVIDER-HTTP: Parsed tournament: $name, ID: $docId');
              
              final tournament = Tournament(
                id: docId,
                name: name,
                type: type,
                location: location,
                startDate: date,  // Use date for both startDate and endDate for legacy data
                endDate: date,    // Same date used for both fields
                players: players,
                price: price,
                isFeatured: isFeatured,
                registeredUsers: registeredUsers,
              );
              
              loadedTournaments.add(tournament);
            } catch (e) {
              print('PROVIDER-HTTP: Error parsing tournament: $e');
              print('PROVIDER-HTTP: Document data: $doc');
            }
          }
          
          _tournaments = loadedTournaments;
          print('PROVIDER-HTTP: Successfully loaded ${_tournaments.length} tournaments');
          _updateFeaturedTournament();
          notifyListeners();
          
          // Debug output
          for (var t in _tournaments) {
            print('PROVIDER-HTTP: Tournament: ${t.name}, Date: ${t.date}, Price: ${t.price}');
            print('PROVIDER-HTTP: Registered users: ${t.registeredUsers.join(', ')}');
          }
        } else {
          print('PROVIDER-HTTP: No documents found in response');
          print('PROVIDER-HTTP: Response data: $data');
        }
      } else {
        print('PROVIDER-HTTP: Error: ${response.statusCode} - ${response.body}');
        
        // Try the standard Firebase SDK method as fallback
        print('PROVIDER-HTTP: Falling back to standard Firebase SDK method');
        await loadTournaments();
      }
    } catch (e) {
      print('PROVIDER-HTTP: Exception: $e');
      // Try the standard Firebase SDK method as fallback
      print('PROVIDER-HTTP: Falling back to standard Firebase SDK method');
      await loadTournaments();
    }
  }
  
  // Helper methods for extracting values from Firestore REST API response
  String _getStringValue(Map<String, dynamic> fields, String fieldName) {
    if (!fields.containsKey(fieldName)) return '';
    final field = fields[fieldName];
    if (field is Map && field.containsKey('stringValue')) {
      return field['stringValue'] as String;
    }
    return '';
  }
  
  int _getIntValue(Map<String, dynamic> fields, String fieldName) {
    if (!fields.containsKey(fieldName)) return 0;
    final field = fields[fieldName];
    if (field is Map) {
      if (field.containsKey('integerValue')) {
        return int.tryParse(field['integerValue'].toString()) ?? 0;
      }
      if (field.containsKey('doubleValue')) {
        return (field['doubleValue'] as num).toInt();
      }
    }
    return 0;
  }
  
  double _getDoubleValue(Map<String, dynamic> fields, String fieldName) {
    if (!fields.containsKey(fieldName)) return 0.0;
    final field = fields[fieldName];
    if (field is Map) {
      if (field.containsKey('doubleValue')) {
        return (field['doubleValue'] as num).toDouble();
      }
      if (field.containsKey('integerValue')) {
        return double.tryParse(field['integerValue'].toString()) ?? 0.0;
      }
    }
    return 0.0;
  }
  
  bool _getBoolValue(Map<String, dynamic> fields, String fieldName) {
    if (!fields.containsKey(fieldName)) return false;
    final field = fields[fieldName];
    if (field is Map && field.containsKey('booleanValue')) {
      return field['booleanValue'] as bool;
    }
    return false;
  }
  
  List<String> _getStringArrayValue(Map<String, dynamic> fields, String fieldName) {
    if (!fields.containsKey(fieldName)) return [];
    final field = fields[fieldName];
    if (field is Map && field.containsKey('arrayValue')) {
      final arrayValue = field['arrayValue'];
      if (arrayValue is Map && arrayValue.containsKey('values')) {
        final values = arrayValue['values'] as List;
        return values.map((value) {
          if (value is Map && value.containsKey('stringValue')) {
            return value['stringValue'] as String;
          }
          return '';
        }).where((value) => value.isNotEmpty).toList();
      }
    }
    return [];
  }
}
