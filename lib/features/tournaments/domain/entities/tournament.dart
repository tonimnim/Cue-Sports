import 'package:equatable/equatable.dart';

enum TournamentStatus {
  upcoming,
  registration_open,
  registration_closed,
  in_progress,
  completed,
  cancelled,
}

class Tournament extends Equatable {
  final String id;
  final String name;
  final String type;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxPlayers;
  final double entryFee;
  final bool isFeatured;
  final List<String> registeredUserIds;
  final TournamentStatus status;
  final bool isPublic;
  final List<String> communityIds;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic>? prizeStructure;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const Tournament({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxPlayers,
    required this.entryFee,
    this.isFeatured = false,
    this.registeredUserIds = const [],
    required this.status,
    this.isPublic = true,
    this.communityIds = const [],
    this.description = '',
    this.imageUrl,
    this.prizeStructure,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Helper getters
  int get currentPlayerCount => registeredUserIds.length;
  bool get isFull => currentPlayerCount >= maxPlayers;
  bool get canRegister => 
      status == TournamentStatus.registration_open && 
      !isFull && 
      startDate.isAfter(DateTime.now());

  String get dateRange {
    if (startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year) {
      return '${_formatDate(startDate)}';
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
    String? type,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxPlayers,
    double? entryFee,
    bool? isFeatured,
    List<String>? registeredUserIds,
    TournamentStatus? status,
    bool? isPublic,
    List<String>? communityIds,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? prizeStructure,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      entryFee: entryFee ?? this.entryFee,
      isFeatured: isFeatured ?? this.isFeatured,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      communityIds: communityIds ?? this.communityIds,
      description: description ?? this.description,
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
        type,
        location,
        startDate,
        endDate,
        maxPlayers,
        entryFee,
        isFeatured,
        registeredUserIds,
        status,
        isPublic,
        communityIds,
        description,
        imageUrl,
        prizeStructure,
        createdAt,
        updatedAt,
        createdBy,
      ];
} 