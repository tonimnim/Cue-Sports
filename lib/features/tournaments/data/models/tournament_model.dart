import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tournament.dart';

/// Tournament model for Firebase serialization
class TournamentModel extends Tournament {
  const TournamentModel({
    required String id,
    required String name,
    String description = '',
    String? createdByAdminId,
    required TournamentType type,
    required String location,
    required DateTime startDate,
    DateTime? endDate,
    required int maxPlayers,
    required double entryFee,
    bool isFeatured = false,
    bool isNational = false,
    double prizePool = 0.0,
    String venue = '',
    int currentPlayers = 0,
    String? sponsorName,
    List<String> rules = const [],
    String? bannerImageUrl,
    String? youtubeChannelId,
    List<String> registeredUserIds = const [],
    required TournamentStatus status,
    bool isPublic = true,
    List<String> communityIds = const [],
    String? imageUrl,
    Map<String, dynamic>? prizeStructure,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String createdBy,
  }) : super(
          id: id,
          name: name,
          description: description,
          createdByAdminId: createdByAdminId,
          type: type,
          location: location,
          startDate: startDate,
          endDate: endDate,
          maxPlayers: maxPlayers,
          entryFee: entryFee,
          isFeatured: isFeatured,
          isNational: isNational,
          prizePool: prizePool,
          venue: venue,
          currentPlayers: currentPlayers,
          sponsorName: sponsorName,
          rules: rules,
          bannerImageUrl: bannerImageUrl,
          youtubeChannelId: youtubeChannelId,
          registeredUserIds: registeredUserIds,
          status: status,
          isPublic: isPublic,
          communityIds: communityIds,
          imageUrl: imageUrl,
          prizeStructure: prizeStructure,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
        );

  /// Create TournamentModel from Tournament entity
  factory TournamentModel.fromEntity(Tournament tournament) {
    return TournamentModel(
      id: tournament.id,
      name: tournament.name,
      description: tournament.description,
      createdByAdminId: tournament.createdByAdminId,
      type: tournament.type,
      location: tournament.location,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      maxPlayers: tournament.maxPlayers,
      entryFee: tournament.entryFee,
      isFeatured: tournament.isFeatured,
      isNational: tournament.isNational,
      prizePool: tournament.prizePool,
      venue: tournament.venue,
      currentPlayers: tournament.currentPlayers,
      sponsorName: tournament.sponsorName,
      rules: tournament.rules,
      bannerImageUrl: tournament.bannerImageUrl,
      youtubeChannelId: tournament.youtubeChannelId,
      registeredUserIds: tournament.registeredUserIds,
      status: tournament.status,
      isPublic: tournament.isPublic,
      communityIds: tournament.communityIds,
      imageUrl: tournament.imageUrl,
      prizeStructure: tournament.prizeStructure,
      createdAt: tournament.createdAt,
      updatedAt: tournament.updatedAt,
      createdBy: tournament.createdBy,
    );
  }

  /// Create TournamentModel from JSON
  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    try {
      return TournamentModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unnamed Tournament',
        description: json['description'] as String? ?? '',
        createdByAdminId: json['createdByAdminId'] as String?,
        type: _parseTournamentType(json['type'] as String? ?? 'beginner'),
        location: json['location'] as String? ?? json['venue'] as String? ?? '',
        startDate: _parseDateTime(json['startDate']),
        endDate:
            json['endDate'] != null ? _parseDateTime(json['endDate']) : null,
        maxPlayers: _parseInt(json['maxPlayers']) ?? 0,
        entryFee: _parseDouble(json['entryFee']) ?? 0.0,
        isFeatured: json['isFeatured'] as bool? ?? false,
        isNational: json['isNational'] as bool? ?? false,
        prizePool: _parseDouble(json['prizePool']) ?? 0.0,
        venue: json['venue'] as String? ?? '',
        currentPlayers: _parseInt(json['currentPlayers']) ?? 0,
        sponsorName: json['sponsorName'] as String?,
        rules: _parseStringList(json['rules']),
        bannerImageUrl: json['bannerImageUrl'] as String?,
        youtubeChannelId: json['youtubeChannelId'] as String?,
        registeredUserIds: _parseStringList(json['registeredUserIds']),
        status: _parseTournamentStatus(json['status'] as String? ?? 'upcoming'),
        isPublic: json['isPublic'] as bool? ?? true,
        communityIds: _parseStringList(json['communityIds']),
        imageUrl:
            json['imageUrl'] as String? ?? json['bannerImageUrl'] as String?,
        prizeStructure: json['prizeStructure'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? _parseDateTime(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? _parseDateTime(json['updatedAt'])
            : DateTime.now(),
        createdBy: json['createdBy'] as String? ??
            json['createdByAdminId'] as String? ??
            '',
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
        type: TournamentType.beginner,
        location: 'Unknown',
        startDate: DateTime.now().add(const Duration(days: 30)),
        maxPlayers: 0,
        entryFee: 0.0,
        status: TournamentStatus.draft,
        venue: 'Unknown',
        currentPlayers: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
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

  /// Convert to Tournament entity
  Tournament toEntity() {
    return Tournament(
      id: id,
      name: name,
      description: description,
      createdByAdminId: createdByAdminId,
      type: type,
      location: location,
      startDate: startDate,
      endDate: endDate,
      maxPlayers: maxPlayers,
      entryFee: entryFee,
      isFeatured: isFeatured,
      isNational: isNational,
      prizePool: prizePool,
      venue: venue,
      currentPlayers: currentPlayers,
      sponsorName: sponsorName,
      rules: rules,
      bannerImageUrl: bannerImageUrl,
      youtubeChannelId: youtubeChannelId,
      registeredUserIds: registeredUserIds,
      status: status,
      isPublic: isPublic,
      communityIds: communityIds,
      imageUrl: imageUrl,
      prizeStructure: prizeStructure,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  /// Convert TournamentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdByAdminId': createdByAdminId,
      'type': _tournamentTypeToString(type),
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'maxPlayers': maxPlayers,
      'entryFee': entryFee,
      'isFeatured': isFeatured,
      'isNational': isNational,
      'prizePool': prizePool,
      'venue': venue,
      'currentPlayers': currentPlayers,
      'sponsorName': sponsorName,
      'rules': rules,
      'bannerImageUrl': bannerImageUrl,
      'youtubeChannelId': youtubeChannelId,
      'registeredUserIds': registeredUserIds,
      'status': _tournamentStatusToString(status),
      'isPublic': isPublic,
      'communityIds': communityIds,
      'imageUrl': imageUrl,
      'prizeStructure': prizeStructure,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
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
      case TournamentStatus.in_progress:
        return 'in_progress';
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
        return TournamentStatus.in_progress;
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
  @override
  TournamentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdByAdminId,
    TournamentType? type,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxPlayers,
    double? entryFee,
    bool? isFeatured,
    bool? isNational,
    double? prizePool,
    String? venue,
    int? currentPlayers,
    String? sponsorName,
    List<String>? rules,
    String? bannerImageUrl,
    String? youtubeChannelId,
    List<String>? registeredUserIds,
    TournamentStatus? status,
    bool? isPublic,
    List<String>? communityIds,
    String? imageUrl,
    Map<String, dynamic>? prizeStructure,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      type: type ?? this.type,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      entryFee: entryFee ?? this.entryFee,
      isFeatured: isFeatured ?? this.isFeatured,
      isNational: isNational ?? this.isNational,
      prizePool: prizePool ?? this.prizePool,
      venue: venue ?? this.venue,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      sponsorName: sponsorName ?? this.sponsorName,
      rules: rules ?? this.rules,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      youtubeChannelId: youtubeChannelId ?? this.youtubeChannelId,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      communityIds: communityIds ?? this.communityIds,
      imageUrl: imageUrl ?? this.imageUrl,
      prizeStructure: prizeStructure ?? this.prizeStructure,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
