import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tournament.dart';

/// Tournament model for Firebase serialization
/// Handles BOTH mobile app fields AND web app fields
/// Provides backward compatibility and graceful mapping
class TournamentModel {
  // Mobile app fields (core Tournament entity)
  final String id;
  final String name;
  final String description;
  final String? createdByAdminId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TournamentType type;
  final TournamentStatus status;
  final int maxPlayers;
  final double entryFee;
  final double prizePool;
  final Map<String, dynamic>? prizeStructure;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final List<TournamentVenue> venues;
  final TournamentAccess access;
  final bool isFeatured;
  final bool isNational;
  final String? sponsorName;
  final List<String> rules;
  final List<String> registeredUserIds;
  final Map<String, dynamic> searchKeywords;

  // Legacy/Web app fields (for backward compatibility)
  final String? venue; // Maps to location or venues[0].name
  final int? currentPlayers; // Maps to registeredUserIds.length
  final String? bannerImageUrl; // Web app only
  final String? youtubeChannelId; // Web app only
  final bool? isPublic; // Maps to access.isPublic
  final List<String>? communityIds; // Maps to access.allowedCommunityIds
  final String? imageUrl; // Web app only

  const TournamentModel({
    // Mobile app fields (required)
    required this.id,
    required this.name,
    this.description = '',
    this.createdByAdminId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.status,
    required this.maxPlayers,
    required this.entryFee,
    this.prizePool = 0.0,
    this.prizeStructure,
    required this.startDate,
    this.endDate,
    required this.location,
    this.venues = const [],
    this.access = const TournamentAccess(),
    this.isFeatured = false,
    this.isNational = false,
    this.sponsorName,
    this.rules = const [],
    this.registeredUserIds = const [],
    this.searchKeywords = const {},
    // Legacy/Web app fields (optional)
    this.venue,
    this.currentPlayers,
    this.bannerImageUrl,
    this.youtubeChannelId,
    this.isPublic,
    this.communityIds,
    this.imageUrl,
  });

  /// Convert to mobile app Tournament entity
  Tournament toEntity() {
    return Tournament(
      id: id,
      name: name,
      description: description,
      createdByAdminId: createdByAdminId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      type: type,
      status: status,
      maxPlayers: maxPlayers,
      entryFee: entryFee,
      prizePool: prizePool,
      prizeStructure: prizeStructure,
      startDate: startDate,
      endDate: endDate,
      location: location,
      venues: venues,
      access: access,
      isFeatured: isFeatured,
      isNational: isNational,
      sponsorName: sponsorName,
      rules: rules,
      registeredUserIds: registeredUserIds,
      searchKeywords: searchKeywords,
    );
  }

  /// Mobile app compatibility getters
  /// These provide backward compatibility for widgets expecting old properties
  
  /// Mobile app compatibility - primary venue name
  String get mobileVenue => venues.isNotEmpty ? venues.first.name : location;
  
  /// Mobile app compatibility - current player count
  int get mobileCurrentPlayers => registeredUserIds.length;
  
  /// Mobile app compatibility - public status
  bool get mobileIsPublic => access.isPublic;

  /// Create from mobile app Tournament entity
  factory TournamentModel.fromEntity(Tournament tournament) {
    return TournamentModel(
      // Mobile app fields
      id: tournament.id,
      name: tournament.name,
      description: tournament.description,
      createdByAdminId: tournament.createdByAdminId,
      createdBy: tournament.createdBy,
      createdAt: tournament.createdAt,
      updatedAt: tournament.updatedAt,
      type: tournament.type,
      status: tournament.status,
      maxPlayers: tournament.maxPlayers,
      entryFee: tournament.entryFee,
      prizePool: tournament.prizePool,
      prizeStructure: tournament.prizeStructure,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      location: tournament.location,
      venues: tournament.venues,
      access: tournament.access,
      isFeatured: tournament.isFeatured,
      isNational: tournament.isNational,
      sponsorName: tournament.sponsorName,
      rules: tournament.rules,
      registeredUserIds: tournament.registeredUserIds,
      searchKeywords: tournament.searchKeywords,
      // Legacy fields for web app compatibility
      venue: tournament.venues.isNotEmpty ? tournament.venues.first.name : tournament.location,
      currentPlayers: tournament.registeredUserIds.length,
      isPublic: tournament.access.isPublic,
      communityIds: tournament.access.allowedCommunityIds,
    );
  }

  /// Create TournamentModel from JSON
  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    try {
      return TournamentModel(
        // Mobile app core fields
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unnamed Tournament',
        description: json['description'] as String? ?? '',
        createdByAdminId: json['createdByAdminId'] as String?,
        createdBy: json['createdBy'] as String? ??
            json['createdByAdminId'] as String? ??
            '',
        createdAt: json['createdAt'] != null
            ? _parseDateTime(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? _parseDateTime(json['updatedAt'])
            : DateTime.now(),
        type: _parseTournamentType(json['type'] as String? ?? 'beginner'),
        status: _parseTournamentStatus(json['status'] as String? ?? 'upcoming'),
        maxPlayers: _parseInt(json['maxPlayers']) ?? 0,
        entryFee: _parseDouble(json['entryFee']) ?? 0.0,
        prizePool: _parseDouble(json['prizePool']) ?? 0.0,
        prizeStructure: json['prizeStructure'] as Map<String, dynamic>?,
        startDate: _parseDateTime(json['startDate']),
        endDate:
            json['endDate'] != null ? _parseDateTime(json['endDate']) : null,
        location: json['location'] as String? ?? json['venue'] as String? ?? '',
        venues: _parseVenues(json['venues']),
        access: _parseAccess(json['access'], json['isPublic'], json['communityIds']),
        isFeatured: json['isFeatured'] as bool? ?? false,
        isNational: json['isNational'] as bool? ?? false,
        sponsorName: json['sponsorName'] as String?,
        rules: _parseStringList(json['rules']),
        registeredUserIds: _parseStringList(json['registeredUserIds']),
        searchKeywords: _parseSearchKeywords(json['searchKeywords']),
        // Legacy/Web app fields for compatibility
        venue: json['venue'] as String?,
        currentPlayers: _parseInt(json['currentPlayers']),
        bannerImageUrl: json['bannerImageUrl'] as String?,
        youtubeChannelId: json['youtubeChannelId'] as String?,
        isPublic: json['isPublic'] as bool?,
        communityIds: _parseStringList(json['communityIds']),
        imageUrl: json['imageUrl'] as String? ?? json['bannerImageUrl'] as String?,
      );
    } catch (e) {
      print('🚨 ERROR: Failed to parse tournament document ${json['id']}: $e');
      // Return a safe default tournament for invalid documents
      return TournamentModel(
        id: json['id'] as String? ??
            'unknown_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? 'Invalid Tournament Data',
        description:
            'This tournament has corrupted data and needs to be fixed.',
        createdBy: 'system',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: TournamentType.beginner,
        status: TournamentStatus.draft,
        maxPlayers: 0,
        entryFee: 0.0,
        startDate: DateTime.now().add(const Duration(days: 30)),
        location: 'Unknown',
      );
    }
  }

  /// Safely parse integer from dynamic value
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Safely parse double from dynamic value
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Safely parse string list from dynamic value
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Safely parse DateTime from either Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      try {
        // Try parsing ISO string first
        return DateTime.parse(value);
      } catch (e) {
        // Try parsing common date formats
        try {
          // Handle formats like "Apr 5, 2025", "Jan 15, 2025", etc.
          final dateFormats = [
            // "Apr 5, 2025" format
            RegExp(r'^(\w{3})\s+(\d{1,2}),\s+(\d{4})$'),
            // "Apr 15 2025" format (without comma)
            RegExp(r'^(\w{3})\s+(\d{1,2})\s+(\d{4})$'),
          ];

          for (final format in dateFormats) {
            final match = format.firstMatch(value);
            if (match != null) {
              final month = _getMonthNumber(match.group(1)!);
              final day = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            }
          }

          // If no format matches, try default parsing with space-to-T replacement
          return DateTime.parse(value.replaceAll(' ', 'T'));
        } catch (e2) {
          print(
              '⚠️ WARNING: Could not parse date "$value", using current time');
          // If all parsing fails, return current time
          return DateTime.now();
        }
      }
    }

    // For any other type, return current time
    print(
        '⚠️ WARNING: Unexpected date type ${value.runtimeType}, using current time');
    return DateTime.now();
  }

  /// Convert month name to number
  static int _getMonthNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12
    };
    return months[month] ?? 1;
  }

  /// Create TournamentModel from Firestore document
  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return TournamentModel.fromJson(data);
  }

  /// Convert TournamentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdByAdminId': createdByAdminId,
      // Mobile app fields
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'type': _tournamentTypeToString(type),
      'status': _tournamentStatusToString(status),
      'maxPlayers': maxPlayers,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'prizeStructure': prizeStructure,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'venues': venues.map((v) => v.toJson()).toList(),
      'access': access.toJson(),
      'isFeatured': isFeatured,
      'isNational': isNational,
      'sponsorName': sponsorName,
      'rules': rules,
      'registeredUserIds': registeredUserIds,
      'searchKeywords': searchKeywords,
      // Legacy/Web app fields for backward compatibility
      'venue': mobileVenue,
      'currentPlayers': mobileCurrentPlayers,
      'isPublic': mobileIsPublic,
      'communityIds': access.allowedCommunityIds,
      if (bannerImageUrl != null) 'bannerImageUrl': bannerImageUrl,
      if (youtubeChannelId != null) 'youtubeChannelId': youtubeChannelId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Convert to Firestore data (without id)
  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    return data;
  }

  /// Convert tournament type to string
  static String _tournamentTypeToString(TournamentType type) {
    switch (type) {
      case TournamentType.national:
        return 'national';
      case TournamentType.professional:
        return 'professional';
      case TournamentType.beginner:
        return 'beginner';
      case TournamentType.regional:
        return 'regional';
      case TournamentType.sponsored:
        return 'sponsored';
    }
  }

  /// Convert tournament status to string
  static String _tournamentStatusToString(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return 'upcoming';
      case TournamentStatus.registration_open:
        return 'registration_open';
      case TournamentStatus.registration_closed:
        return 'registration_closed';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
      case TournamentStatus.draft:
        return 'draft';
      case TournamentStatus.active:
        return 'active';
    }
  }

  /// Parse tournament type from string
  static TournamentType _parseTournamentType(String type) {
    switch (type.toLowerCase()) {
      case 'national':
        return TournamentType.national;
      case 'professional':
        return TournamentType.professional;
      case 'beginner':
        return TournamentType.beginner;
      case 'regional':
        return TournamentType.regional;
      case 'sponsored':
        return TournamentType.sponsored;
      default:
        return TournamentType.beginner;
    }
  }

  /// Parse tournament status from string
  static TournamentStatus _parseTournamentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return TournamentStatus.upcoming;
      case 'registration_open':
        return TournamentStatus.registration_open;
      case 'registration_closed':
        return TournamentStatus.registration_closed;
      case 'in_progress':
        return TournamentStatus.active;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      case 'draft':
        return TournamentStatus.draft;
      case 'active':
        return TournamentStatus.active;
      default:
        return TournamentStatus.upcoming;
    }
  }

  /// Create a copy with updated fields
  TournamentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdByAdminId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    TournamentType? type,
    TournamentStatus? status,
    int? maxPlayers,
    double? entryFee,
    double? prizePool,
    Map<String, dynamic>? prizeStructure,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    List<TournamentVenue>? venues,
    TournamentAccess? access,
    bool? isFeatured,
    bool? isNational,
    String? sponsorName,
    List<String>? rules,
    List<String>? registeredUserIds,
    Map<String, dynamic>? searchKeywords,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      prizeStructure: prizeStructure ?? this.prizeStructure,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      venues: venues ?? this.venues,
      access: access ?? this.access,
      isFeatured: isFeatured ?? this.isFeatured,
      isNational: isNational ?? this.isNational,
      sponsorName: sponsorName ?? this.sponsorName,
      rules: rules ?? this.rules,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  /// Parse venues from JSON
  static List<TournamentVenue> _parseVenues(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return TournamentVenue.fromJson(item);
              }
            } catch (e) {
              print('⚠️ Failed to parse venue: $e');
            }
            return null;
          })
          .where((v) => v != null)
          .cast<TournamentVenue>()
          .toList();
    }
    return [];
  }

  /// Parse access from JSON with legacy support
  static TournamentAccess _parseAccess(dynamic value, dynamic legacyIsPublic, dynamic legacyCommunityIds) {
    // Try new format first
    if (value != null) {
      try {
        if (value is Map<String, dynamic>) {
          return TournamentAccess.fromJson(value);
        }
      } catch (e) {
        print('⚠️ Failed to parse new access format: $e');
      }
    }
    
    // Fallback to legacy format
    final isPublic = legacyIsPublic as bool? ?? true;
    final communityIds = _parseStringList(legacyCommunityIds);
    
    return TournamentAccess(
      isPublic: isPublic,
      allowedCommunityIds: communityIds,
    );
  }

  /// Parse search keywords from JSON
  static Map<String, dynamic> _parseSearchKeywords(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {};
  }
}