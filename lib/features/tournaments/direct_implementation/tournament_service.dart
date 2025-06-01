import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tournament.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all tournaments using multiple methods to ensure data is loaded
  Future<List<Tournament>> getTournaments() async {
    // First try Firestore direct access
    final firestoreTournaments = await _getFirestoreTournaments();
    if (firestoreTournaments.isNotEmpty) {
      print('TOURNAMENT-SERVICE: Successfully loaded ${firestoreTournaments.length} tournaments from Firestore');
      
      // Debug the order of tournaments by updatedAt
      print('TOURNAMENT-SERVICE: First 3 tournaments by updatedAt:');
      for (int i = 0; i < (firestoreTournaments.length > 3 ? 3 : firestoreTournaments.length); i++) {
        print('TOURNAMENT-SERVICE:   ${i+1}. ${firestoreTournaments[i].name} - ${firestoreTournaments[i].updatedAt}');
      }
      
      return firestoreTournaments;
    }
    
    // If Firestore fails, try HTTP approach
    final httpTournaments = await _getHttpTournaments();
    if (httpTournaments.isNotEmpty) {
      print('TOURNAMENT-SERVICE: Successfully loaded ${httpTournaments.length} tournaments via HTTP');
      
      // Sort by updatedAt timestamp (newest first) after loading from HTTP
      httpTournaments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Debug the order of tournaments by updatedAt
      print('TOURNAMENT-SERVICE: First 3 tournaments by updatedAt (HTTP): ${httpTournaments.take(3).map((t) => "${t.name}: ${t.updatedAt}").join(", ")}');
      
      return httpTournaments;
    }
    
    // If all methods fail, return empty list - no hardcoded data
    print('TOURNAMENT-SERVICE: All remote methods failed, returning empty list');
    return [];
  }

  // Get tournaments directly from Firestore
  Future<List<Tournament>> _getFirestoreTournaments() async {
    try {
      print('TOURNAMENT-SERVICE: Attempting to get tournaments from Firestore...');
      
      // Try different collection names
      final collectionNames = ['tournaments', 'Tournaments'];
      
      for (final collectionName in collectionNames) {
        try {
          print('TOURNAMENT-SERVICE: Trying collection: $collectionName');
          // Order by updatedAt field in descending order (newest first)
          final QuerySnapshot snapshot = await _firestore.collection(collectionName)
            .orderBy('updatedAt', descending: true)
            .get();
          
          print('TOURNAMENT-SERVICE: Found ${snapshot.docs.length} documents in $collectionName');
          
          if (snapshot.docs.isNotEmpty) {
            final tournaments = snapshot.docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                
                // Parse the updatedAt field - it could be in different formats
                DateTime updatedAt;
                try {
                  if (data['updatedAt'] is Timestamp) {
                    updatedAt = (data['updatedAt'] as Timestamp).toDate();
                  } else if (data['updatedAt'] is String) {
                    updatedAt = DateTime.parse(data['updatedAt']);
                  } else {
                    // Default to current time if no valid updatedAt field
                    updatedAt = DateTime.now();
                  }
                } catch (e) {
                  print('TOURNAMENT-SERVICE: Error parsing updatedAt: $e');
                  updatedAt = DateTime.now();
                }
                
                // Extract date fields, handling both new and legacy formats
                String startDate = data['startDate'] ?? '';
                String endDate = data['endDate'] ?? '';
                
                // If using legacy format with only 'date', use it for both start and end
                if (startDate.isEmpty && data['date'] != null) {
                  startDate = data['date'];
                  endDate = data['date'];
                }
                
                return Tournament(
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
                  updatedAt: updatedAt,
                );
              } catch (e) {
                print('TOURNAMENT-SERVICE: Error parsing tournament: $e');
                return null;
              }
            }).whereType<Tournament>().toList();
            
            if (tournaments.isNotEmpty) {
              return tournaments;
            }
          }
        } catch (e) {
          print('TOURNAMENT-SERVICE: Error accessing collection $collectionName: $e');
        }
      }

      return [];
    } catch (e) {
      print('TOURNAMENT-SERVICE: Error getting tournaments from Firestore: $e');
      return [];
    }
  }
  
  // Get tournaments via HTTP (similar to the test script)
  Future<List<Tournament>> _getHttpTournaments() async {
    try {
      print('TOURNAMENT-SERVICE: Attempting to get tournaments via HTTP...');
      
      // The project ID used in simple_tournament_test.dart
      const projectId = 'poolbilliard-167ad';
      final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/tournaments';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('TOURNAMENT-SERVICE: HTTP request successful');
        final data = json.decode(response.body);
        
        if (data['documents'] != null && data['documents'] is List) {
          final List<dynamic> documents = data['documents'];
          print('TOURNAMENT-SERVICE: Found ${documents.length} documents via HTTP');
          
          return documents.map((doc) {
            try {
              final docName = doc['name'] as String;
              final docId = docName.split('/').last;
              
              // Extract fields from document
              final fields = doc['fields'] as Map<String, dynamic>;
              
              // Helper function to extract value from Firestore field
              dynamic getFieldValue(String field) {
                if (fields[field] == null) return null;
                
                final fieldData = fields[field] as Map<String, dynamic>;
                final fieldType = fieldData.keys.first; // e.g., 'stringValue', 'integerValue'
                return fieldData[fieldType];
              }
              
              // Helper to parse integer
              int? parseInt(dynamic value) {
                if (value == null) return null;
                return int.tryParse(value.toString()) ?? 0;
              }
              
              // Helper to parse double
              double? parseDouble(dynamic value) {
                if (value == null) return null;
                return double.tryParse(value.toString()) ?? 0.0;
              }
              
              // Helper to parse boolean
              bool parseBool(dynamic value) {
                if (value == null) return false;
                if (value is bool) return value;
                return value.toString().toLowerCase() == 'true';
              }
              
              // Helper to parse registered users
              List<String> parseRegisteredUsers(dynamic registeredUsersValue) {
                if (registeredUsersValue == null) return [];
                
                try {
                  final users = [];
                  if (registeredUsersValue is List) {
                    for (var user in registeredUsersValue) {
                      if (user is Map && user.containsKey('stringValue')) {
                        users.add(user['stringValue']);
                      }
                    }
                  }
                  return List<String>.from(users);
                } catch (e) {
                  print('TOURNAMENT-SERVICE: Error parsing registered users: $e');
                  return [];
                }
              }
              
              // Parse the updatedAt field or use current time if not available
              DateTime parseUpdatedAt(dynamic value) {
                if (value == null) return DateTime.now();
                
                try {
                  return DateTime.parse(value.toString());
                } catch (e) {
                  print('TOURNAMENT-SERVICE: Error parsing updatedAt in HTTP: $e');
                  return DateTime.now();
                }
              }
              
              // Extract date fields, handling both new and legacy formats
              String startDate = getFieldValue('startDate') ?? '';
              String endDate = getFieldValue('endDate') ?? '';
              
              // If using legacy format with only 'date', use it for both start and end
              if (startDate.isEmpty) {
                String dateValue = getFieldValue('date') ?? '';
                if (dateValue.isNotEmpty) {
                  startDate = dateValue;
                  endDate = dateValue;
                }
              }
              
              return Tournament(
                id: docId,
                name: getFieldValue('name') ?? '',
                type: getFieldValue('type') ?? '',
                location: getFieldValue('location') ?? '',
                startDate: startDate,
                endDate: endDate,
                players: parseInt(getFieldValue('players')) ?? 0,
                price: parseDouble(getFieldValue('price')) ?? 0.0,
                isFeatured: parseBool(getFieldValue('isFeatured')),
                registeredUsers: parseRegisteredUsers(getFieldValue('registeredUsers')),
                updatedAt: parseUpdatedAt(getFieldValue('updatedAt')),
              );
            } catch (e) {
              print('TOURNAMENT-SERVICE: Error parsing tournament from HTTP: $e');
              return null;
            }
          }).whereType<Tournament>().toList();
        } else {
          print('TOURNAMENT-SERVICE: HTTP request returned empty result or error: ${response.statusCode}');
          return [];
        }
      } else {
        print('TOURNAMENT-SERVICE: HTTP request failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('TOURNAMENT-SERVICE: Error getting tournaments via HTTP: $e');
      return [];
    }
  }

  // Register a user for a tournament
  Future<bool> registerUserForTournament(String tournamentId, String userId) async {
    try {
      // Try to update the tournament document in different collections
      final collectionNames = ['tournaments', 'Tournaments'];
      
      for (final collectionName in collectionNames) {
        try {
          // Get the current document to check if it exists
          final docRef = _firestore.collection(collectionName).doc(tournamentId);
          final docSnapshot = await docRef.get();
          
          if (docSnapshot.exists) {
            // Get current registered users
            final data = docSnapshot.data() as Map<String, dynamic>;
            final List<String> currentUsers = List<String>.from(data['registeredUsers'] ?? []);
            
            // Check if user is already registered
            if (currentUsers.contains(userId)) {
              print('TOURNAMENT-SERVICE: User $userId is already registered for tournament $tournamentId');
              return true;
            }
            
            // Add user to registered users
            currentUsers.add(userId);
            
            // Update the document
            await docRef.update({
              'registeredUsers': currentUsers,
            });
            
            print('TOURNAMENT-SERVICE: Successfully registered user $userId for tournament $tournamentId');
            return true;
          }
        } catch (e) {
          print('TOURNAMENT-SERVICE: Error registering for tournament in $collectionName: $e');
        }
      }
      
      return false;
    } catch (e) {
      print('TOURNAMENT-SERVICE: Error registering for tournament: $e');
      return false;
    }
  }
  
  // Check if a user is registered for a tournament
  Future<bool> isUserRegistered(String tournamentId, String userId) async {
    try {
      // Try to check the tournament document in different collections
      final collectionNames = ['tournaments', 'Tournaments'];
      
      for (final collectionName in collectionNames) {
        try {
          // Get the current document
          final docSnapshot = await _firestore
              .collection(collectionName)
              .doc(tournamentId)
              .get();
          
          if (docSnapshot.exists) {
            // Get registered users
            final data = docSnapshot.data() as Map<String, dynamic>;
            final List<String> registeredUsers = List<String>.from(data['registeredUsers'] ?? []);
            
            // Check if user is registered
            return registeredUsers.contains(userId);
          }
        } catch (e) {
          print('TOURNAMENT-SERVICE: Error checking registration in $collectionName: $e');
        }
      }
      
      return false;
    } catch (e) {
      print('TOURNAMENT-SERVICE: Error checking registration: $e');
      return false;
    }
  }
}
