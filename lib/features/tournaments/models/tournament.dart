import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String name;
  final String type;
  final String location;
  final String startDate; // Start date of the tournament
  final String endDate;   // End date of the tournament
  final int players;
  final double price;
  final bool isFeatured;
  final List<String> registeredUsers;
  final DateTime updatedAt; // When the tournament was last updated
  final bool isPublic; // Whether the tournament is open to all users
  final List<String> communities; // IDs of communities this tournament belongs to
  
  // For backward compatibility with older tournament data
  String get date => startDate.isNotEmpty ? startDate : 'Jan 1, 2025';
  
  // Formatted date range for display on tournament cards
  String get dateRange {
    // Handle null values by using empty strings
    final start = startDate ?? '';
    final end = endDate ?? '';
    
    if (start.isEmpty && end.isEmpty) return 'TBD';
    if (start == end && start.isNotEmpty) return start;
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.players,
    required this.price,
    this.isFeatured = false,
    this.registeredUsers = const [],
    DateTime? updatedAt,
    this.isPublic = true, // Default to public tournament
    this.communities = const [], // Default to empty list
  }) : this.updatedAt = updatedAt ?? DateTime.now();

  // For Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'players': players,
      'price': price,
      'isFeatured': isFeatured,
      'registeredUsers': registeredUsers,
      'updatedAt': updatedAt.toIso8601String(), // Store as ISO string instead of Timestamp
      'isPublic': isPublic,
      'communities': communities,
    };
  }

  // From Firebase
  factory Tournament.fromMap(Map<String, dynamic>? map, String documentId) {
    // Early return for null input
    if (map == null) {
      print('Error: Tournament.fromMap received null map');
      return Tournament(
        id: documentId,
        name: 'Unknown Tournament',
        type: 'Unknown',
        location: 'Unknown',
        startDate: 'Jan 1, 2025',
        endDate: 'Jan 1, 2025',
        players: 0,
        price: 0.0,
        isFeatured: false,
        registeredUsers: [],
        isPublic: true, // Default to public
        communities: [], // Empty communities list
      );
    }
    
    // Helper functions to parse data
    DateTime parseUpdatedAt(dynamic updatedAtData) {
      try {
        if (updatedAtData is Timestamp) {
          return updatedAtData.toDate();
        } else if (updatedAtData is String) {
          return DateTime.parse(updatedAtData);
        } else if (updatedAtData is Map && updatedAtData.containsKey('timestampValue')) {
          final timestampStr = updatedAtData['timestampValue'] as String;
          return DateTime.parse(timestampStr);
        } else if (updatedAtData is Map && 
                updatedAtData.containsKey('seconds') && 
                updatedAtData.containsKey('nanoseconds')) {
          final seconds = updatedAtData['seconds'] as int;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        print('Error parsing updatedAt: $e');
      }
      
      return DateTime.now();
    };
    
    // Handle registered users field which can be in different formats
    List<String> parseStringList(dynamic listData, String fieldName) {
      if (listData == null) return [];
      
      try {
        // Handle different Firestore data formats
        if (listData is List) {
          return List<String>.from(listData);
        } else if (listData is Map && 
                  listData.containsKey('arrayValue') &&
                  listData['arrayValue'] is Map &&
                  listData['arrayValue'].containsKey('values')) {
          final values = listData['arrayValue']['values'] as List;
          return values
              .where((v) => v is Map && v.containsKey('stringValue'))
              .map((v) => v['stringValue'] as String)
              .toList();
        }
      } catch (e) {
        print('Error parsing $fieldName as List: $e');
      }
      
      return [];
    }
    
    bool parseBoolean(dynamic boolData, bool defaultValue) {
      if (boolData == null) return defaultValue;
      
      try {
        if (boolData is bool) {
          return boolData;
        } else if (boolData is Map && boolData.containsKey('booleanValue')) {
          return boolData['booleanValue'] as bool;
        }
      } catch (e) {
        print('Error parsing boolean: $e');
      }
      
      return defaultValue;
    }
    
    int parsePlayers(dynamic playersData) {
      if (playersData is int) return playersData;
      return int.tryParse(playersData?.toString() ?? '0') ?? 0;
    }
    
    double parsePrice(dynamic priceData) {
      if (priceData is double) return priceData;
      return double.tryParse(priceData?.toString() ?? '0') ?? 0.0;
    }
    
    bool parseFeatured(dynamic featuredData) {
      if (featuredData is bool) return featuredData;
      return featuredData ?? false;
    }
    
    try {
      // Handle both new format (startDate/endDate) and legacy format (date only)
      // Use empty string as fallback for null values
      String startDate = '';
      String endDate = '';
      
      // Safely extract startDate
      if (map['startDate'] != null) {
        startDate = map['startDate'].toString();
      }
      
      // Safely extract endDate
      if (map['endDate'] != null) {
        endDate = map['endDate'].toString();
      }
      
      // If we have the legacy format with only 'date', use it for both start and end
      if (startDate.isEmpty && endDate.isEmpty && map['date'] != null) {
        final legacyDate = map['date'].toString();
        startDate = legacyDate;
        endDate = legacyDate;
      }
      
      // Use default date if both are still empty
      if (startDate.isEmpty && endDate.isEmpty) {
        startDate = 'Jan 1, 2025';
        endDate = 'Jan 1, 2025';
      }
      
      return Tournament(
        id: documentId,
        name: map['name'] ?? '',
        type: map['type'] ?? '',
        location: map['location'] ?? '',
        startDate: startDate,
        endDate: endDate,
        players: parsePlayers(map['players']),
        price: parsePrice(map['price']),
        isFeatured: parseFeatured(map['isFeatured']),
        registeredUsers: parseStringList(map['registeredUsers'], 'registeredUsers'),
        // Always provide a valid DateTime, even if updatedAt is null
        updatedAt: map['updatedAt'] != null ? parseUpdatedAt(map['updatedAt']) : DateTime.now(),
        // Add new fields with defaults
        isPublic: parseBoolean(map['isPublic'], true), // Default to public if not specified
        communities: parseStringList(map['communities'], 'communities'),
      );
    } catch (e) {
      print('Error creating Tournament from map: $e');
      // Return a default tournament as fallback
      return Tournament(
        id: documentId,
        name: 'Unknown Tournament',
        type: 'Unknown',
        location: 'Unknown',
        startDate: map['startDate'] ?? map['date'] ?? 'Jan 1, 2025',
        endDate: map['endDate'] ?? map['date'] ?? 'Jan 1, 2025',
        players: 0,
        price: 0.0,
        isFeatured: false,
        registeredUsers: [],
      );
    }
  }

  // Check if a user is registered for this tournament
  bool isUserRegistered(String userId) {
    return registeredUsers.contains(userId);
  }
}
