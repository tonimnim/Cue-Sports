import 'package:equatable/equatable.dart';

enum TournamentStatus {
  upcoming,
  registration_open,
  registration_closed,
  active,
  completed,
  cancelled,
  draft,
}

enum TournamentType {
  national,
  professional,
  beginner,
  regional,
  sponsored,
}

/// Venue information for tournaments
class TournamentVenue {
  final String id;
  final String name;
  final String address;
  final String? communityId; // For multi-venue tournaments
  final String? contactInfo;
  final int? capacity;

  const TournamentVenue({
    required this.id,
    required this.name,
    required this.address,
    this.communityId,
    this.contactInfo,
    this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'communityId': communityId,
      'contactInfo': contactInfo,
      'capacity': capacity,
    };
  }

  factory TournamentVenue.fromJson(Map<String, dynamic> json) {
    return TournamentVenue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      communityId: json['communityId'] as String?,
      contactInfo: json['contactInfo'] as String?,
      capacity: json['capacity'] as int?,
    );
  }
}

/// Access control for sponsored/private tournaments
class TournamentAccess {
  final bool isPublic;
  final List<String> allowedCommunityIds; // Communities that can participate
  final List<String> allowedUserIds; // Manually added users
  final String? restrictionCriteria; // e.g., "constituency_players_only"
  final String? restrictionDescription; // Human readable description

  const TournamentAccess({
    this.isPublic = true,
    this.allowedCommunityIds = const [],
    this.allowedUserIds = const [],
    this.restrictionCriteria,
    this.restrictionDescription,
  });

  /// Check if a user can access this tournament
  bool canUserAccess(String userId, List<String> userCommunityIds) {
    if (isPublic) return true;

    // Check if user is manually allowed
    if (allowedUserIds.contains(userId)) return true;

    // Check if user's community is allowed
    if (allowedCommunityIds.isNotEmpty) {
      return userCommunityIds.any((id) => allowedCommunityIds.contains(id));
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'allowedCommunityIds': allowedCommunityIds,
      'allowedUserIds': allowedUserIds,
      'restrictionCriteria': restrictionCriteria,
      'restrictionDescription': restrictionDescription,
    };
  }

  factory TournamentAccess.fromJson(Map<String, dynamic> json) {
    return TournamentAccess(
      isPublic: json['isPublic'] as bool? ?? true,
      allowedCommunityIds: List<String>.from(json['allowedCommunityIds'] ?? []),
      allowedUserIds: List<String>.from(json['allowedUserIds'] ?? []),
      restrictionCriteria: json['restrictionCriteria'] as String?,
      restrictionDescription: json['restrictionDescription'] as String?,
    );
  }
}

class Tournament extends Equatable {
  // Core Identity
  final String id;
  final String name;
  final String description;

  // Administrative
  final String? createdByAdminId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Type & Status
  final TournamentType type;
  final TournamentStatus status;

  // Business Logic
  final int maxPlayers;
  final double entryFee;
  final double prizePool;
  final Map<String, dynamic>? prizeStructure;

  // Timing
  final DateTime startDate;
  final DateTime? endDate;

  // Location & Venues (Supporting multi-venue for national tournaments)
  final String location; // General location description
  final List<TournamentVenue> venues; // Multiple venues support

  // Access Control (Supporting sponsored tournaments with restrictions)
  final TournamentAccess access;

  // Features
  final bool isFeatured;
  final bool isNational;
  final String? sponsorName;
  final List<String> rules;

  // Registration Management (Race condition safe)
  final List<String> registeredUserIds;

  // Search & Discovery
  final Map<String, dynamic> searchKeywords;

  const Tournament({
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
  });

  // Helper getters with null safety
  int get currentPlayerCount => registeredUserIds.length;

  bool get isFull => maxPlayers > 0 && currentPlayerCount >= maxPlayers;

  bool get hasMultipleVenues => venues.length > 1;

  String get primaryVenue => venues.isNotEmpty ? venues.first.name : location;

  bool get canRegister =>
      status == TournamentStatus.registration_open &&
      !isFull &&
      startDate.isAfter(DateTime.now());

  bool get isOpenForRegistration => canRegister;

  bool get hasStarted =>
      status == TournamentStatus.active ||
      status == TournamentStatus.completed;

  int get spotsRemaining =>
      maxPlayers > 0 ? maxPlayers - currentPlayerCount : 999;

  String get typeDisplayName {
    switch (type) {
      case TournamentType.national:
        return 'National';
      case TournamentType.professional:
        return 'Professional';
      case TournamentType.beginner:
        return 'Beginner';
      case TournamentType.regional:
        return 'Regional';
      case TournamentType.sponsored:
        return 'Sponsored';
    }
  }

  String get dateRange {
    if (endDate == null) {
      return _formatDate(startDate);
    }
    if (startDate.day == endDate!.day &&
        startDate.month == endDate!.month &&
        startDate.year == endDate!.year) {
      return _formatDate(startDate);
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Check if user is registered (null-safe)
  bool isUserRegistered(String? userId) {
    if (userId == null) return false;
    return registeredUserIds.contains(userId);
  }

  /// Check if user can access this tournament (improved visibility logic)
  bool isVisibleToUser(String? userId, List<String> userCommunityIds) {
    if (userId == null) return access.isPublic;
    return access.canUserAccess(userId, userCommunityIds);
  }

  /// Get venue for specific community (for multi-venue tournaments)
  TournamentVenue? getVenueForCommunity(String communityId) {
    final matchingVenues = venues.where((v) => v.communityId == communityId);
    return matchingVenues.isEmpty ? null : matchingVenues.first;
  }

  /// Check if tournament is restricted to specific criteria
  bool get hasAccessRestrictions => !access.isPublic;

  Tournament copyWith({
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
    return Tournament(
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdByAdminId,
        createdBy,
        createdAt,
        updatedAt,
        type,
        status,
        maxPlayers,
        entryFee,
        prizePool,
        prizeStructure,
        startDate,
        endDate,
        location,
        venues,
        access,
        isFeatured,
        isNational,
        sponsorName,
        rules,
        registeredUserIds,
        searchKeywords,
      ];
}
