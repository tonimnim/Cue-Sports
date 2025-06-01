import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/trophy.dart';
import '../../domain/entities/community.dart';

/// Model class for communities
class CommunityModel extends Community {
  const CommunityModel({
    required String id,
    required String name,
    String? description,
    required String location,
    required String leaderId,
    required CommunityLevel level,
    required int totalPlayers,
    required int points,
    required int trophyCount,
    required int followCount,
    required List<String> playerIds,
    required List<String> followerIds,
    required List<Trophy> trophies,
    required DateTime createdAt,
    String? logoUrl,
    DateTime? lastActivityAt,
    String rankingTier = 'Intermediate',
    int memberCount = 0,
    int communityPoints = 0,
    int achievementCount = 0,
    List<String>? achievements,
  }) : super(
          id: id,
          name: name,
          description: description,
          location: location,
          leaderId: leaderId,
          level: level,
          totalPlayers: totalPlayers,
          points: points,
          trophyCount: trophyCount,
          followCount: followCount,
          playerIds: playerIds,
          followerIds: followerIds,
          trophies: trophies,
          createdAt: createdAt,
          logoUrl: logoUrl,
          lastActivityAt: lastActivityAt,
          rankingTier: rankingTier,
          memberCount: memberCount,
          communityPoints: communityPoints,
          achievementCount: achievementCount,
          achievements: achievements,
        );

  /// Create a CommunityModel from a map
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
      leaderId: json['leaderId'] as String? ?? '',
      level: CommunityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (json['level'] as String? ?? 'local'),
        orElse: () => CommunityLevel.local,
      ),
      totalPlayers: (json['totalPlayers'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      trophyCount: (json['trophyCount'] as num?)?.toInt() ?? 0,
      followCount: (json['followCount'] as num?)?.toInt() ?? 0,
      playerIds: List<String>.from(json['playerIds'] as List? ?? []),
      followerIds: List<String>.from(json['followerIds'] as List? ?? []),
      trophies: (json['trophies'] as List? ?? [])
          .map((e) => Trophy(
                id: e['id'] as String? ?? '',
                name: e['name'] as String? ?? '',
                type: TrophyType.values.firstWhere(
                  (t) => t.toString().split('.').last == (e['type'] as String? ?? 'regional'),
                  orElse: () => TrophyType.regional,
                ),
                playerId: e['playerId'] as String? ?? '',
                wonAt: _parseDateTime(e['wonAt']),
              ))
          .toList(),
      createdAt: _parseDateTime(json['createdAt']),
      logoUrl: json['logoUrl'] as String?,
      lastActivityAt: json['lastActivityAt'] != null
          ? _parseDateTime(json['lastActivityAt'])
          : null,
      rankingTier: json['rankingTier'] as String? ?? 'Intermediate',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      communityPoints: (json['communityPoints'] as num?)?.toInt() ?? 0,
      achievementCount: (json['achievementCount'] as num?)?.toInt() ?? 0,
      achievements: (json['achievements'] as List?)?.cast<String>(),
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Failed to parse date string: $value, using current time');
        return DateTime.now();
      }
    }
    
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    return DateTime.now();
  }

  /// Creates a CommunityModel from a Firestore document
  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Convert to entity (since this extends Community, it can be used directly)
  Community toEntity() => this;

  /// Convert the CommunityModel to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'leaderId': leaderId,
      'level': level.toString().split('.').last,
      'totalPlayers': totalPlayers,
      'points': points,
      'trophyCount': trophyCount,
      'followCount': followCount,
      'playerIds': playerIds,
      'followerIds': followerIds,
      'trophies': trophies
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'type': t.type.toString().split('.').last,
                'playerId': t.playerId,
                'wonAt': t.wonAt.toIso8601String(),
              })
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'logoUrl': logoUrl,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'rankingTier': rankingTier,
      'memberCount': memberCount,
      'communityPoints': communityPoints,
      'achievementCount': achievementCount,
      'achievements': achievements,
    };
  }

  /// Create a copy of this model with some fields updated
  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? leaderId,
    CommunityLevel? level,
    int? totalPlayers,
    int? points,
    int? trophyCount,
    int? followCount,
    List<String>? playerIds,
    List<String>? followerIds,
    List<Trophy>? trophies,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    String? rankingTier,
    int? memberCount,
    int? communityPoints,
    int? achievementCount,
    List<String>? achievements,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      leaderId: leaderId ?? this.leaderId,
      level: level ?? this.level,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      points: points ?? this.points,
      trophyCount: trophyCount ?? this.trophyCount,
      followCount: followCount ?? this.followCount,
      playerIds: playerIds ?? this.playerIds,
      followerIds: followerIds ?? this.followerIds,
      trophies: trophies ?? this.trophies,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      rankingTier: rankingTier ?? this.rankingTier,
      memberCount: memberCount ?? this.memberCount,
      communityPoints: communityPoints ?? this.communityPoints,
      achievementCount: achievementCount ?? this.achievementCount,
      achievements: achievements ?? this.achievements,
    );
  }
}

/// Model class for Trophy entity
class TrophyModel extends Trophy {
  const TrophyModel({
    required String id,
    required String name,
    required TrophyType type,
    required String playerId,
    required DateTime wonAt,
  }) : super(
          id: id,
          name: name,
          type: type,
          playerId: playerId,
          wonAt: wonAt,
        );

  /// Create TrophyModel from JSON
  factory TrophyModel.fromJson(Map<String, dynamic> json) {
    return TrophyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TrophyType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TrophyType.regional,
      ),
      playerId: json['playerId'] as String,
      wonAt: DateTime.parse(json['wonAt'] as String),
    );
  }

  /// Convert TrophyModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'playerId': playerId,
      'wonAt': wonAt.toIso8601String(),
    };
  }
} 