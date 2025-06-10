import 'package:equatable/equatable.dart';

enum TournamentStatus {
  upcoming,
  registration_open,
  registration_closed,
  in_progress,
  completed,
  cancelled,
  draft,
  active,
}

enum TournamentType {
  national,
  professional,
  beginner,
  regional,
  sponsored,
}

class Tournament extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? createdByAdminId;
  final TournamentType type;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final int maxPlayers;
  final double entryFee;
  final bool isFeatured;
  final bool isNational;
  final double prizePool;
  final String venue;
  final int currentPlayers;
  final String? sponsorName;
  final List<String> rules;
  final String? bannerImageUrl;
  final String? youtubeChannelId;
  final List<String> registeredUserIds;
  final TournamentStatus status;
  final bool isPublic;
  final List<String> communityIds;
  final String? imageUrl;
  final Map<String, dynamic>? prizeStructure;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const Tournament({
    required this.id,
    required this.name,
    this.description = '',
    this.createdByAdminId,
    required this.type,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.maxPlayers,
    required this.entryFee,
    this.isFeatured = false,
    this.isNational = false,
    this.prizePool = 0.0,
    this.venue = '',
    this.currentPlayers = 0,
    this.sponsorName,
    this.rules = const [],
    this.bannerImageUrl,
    this.youtubeChannelId,
    this.registeredUserIds = const [],
    required this.status,
    this.isPublic = true,
    this.communityIds = const [],
    this.imageUrl,
    this.prizeStructure,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Helper getters
  int get currentPlayerCount => registeredUserIds.length;
  bool get isFull => currentPlayerCount >= maxPlayers && maxPlayers > 0;
  bool get canRegister =>
      status == TournamentStatus.registration_open &&
      !isFull &&
      startDate.isAfter(DateTime.now());

  bool get isOpenForRegistration => canRegister;
  bool get hasStarted =>
      status == TournamentStatus.in_progress ||
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
      return '${_formatDate(startDate)}';
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

  bool isUserRegistered(String userId) {
    return registeredUserIds.contains(userId);
  }

  bool isVisibleToUser(String userId, List<String> userCommunityIds) {
    if (isPublic) return true;
    if (communityIds.isEmpty) return true;
    return communityIds.any((id) => userCommunityIds.contains(id));
  }

  Tournament copyWith({
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
    return Tournament(
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdByAdminId,
        type,
        location,
        startDate,
        endDate,
        maxPlayers,
        entryFee,
        isFeatured,
        isNational,
        prizePool,
        venue,
        currentPlayers,
        sponsorName,
        rules,
        bannerImageUrl,
        youtubeChannelId,
        registeredUserIds,
        status,
        isPublic,
        communityIds,
        imageUrl,
        prizeStructure,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
