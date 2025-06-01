import 'package:equatable/equatable.dart';
import 'trophy.dart';

/// Enum representing community levels
enum CommunityLevel {
  /// No regional/national cups
  local,
  
  /// Won regional cup
  regional,
  
  /// Won national cup
  national
}

/// Entity representing a pool billiards community
class Community extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String location;
  final String leaderId;
  final CommunityLevel level;
  final int totalPlayers;
  final int points;
  final int trophyCount;
  final int followCount;
  final List<String> playerIds;
  final List<String> followerIds;
  final List<Trophy> trophies;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final String rankingTier;
  final int memberCount;
  final int communityPoints;
  final int achievementCount;
  final List<String>? achievements;

  const Community({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.leaderId,
    required this.level,
    required this.totalPlayers,
    required this.points,
    required this.trophyCount,
    required this.followCount,
    required this.playerIds,
    required this.followerIds,
    required this.trophies,
    required this.createdAt,
    this.logoUrl,
    this.lastActivityAt,
    this.rankingTier = 'Intermediate',
    this.memberCount = 0,
    this.communityPoints = 0,
    this.achievementCount = 0,
    this.achievements,
  });

  /// Check if a user is following this community
  bool isFollowedBy(String userId) => followerIds.contains(userId);

  /// Check if a user is a player in this community
  bool hasPlayer(String userId) => playerIds.contains(userId);

  /// Check if a user is the leader of this community
  bool isLeader(String userId) => leaderId == userId;

  /// Get admin ID (for backward compatibility)
  String get adminId => leaderId;

  /// Check if community has achievements
  bool get hasAchievements => achievements != null && achievements!.isNotEmpty;

  /// Get the highest trophy type won by this community
  TrophyType? get highestTrophyType {
    if (trophies.isEmpty) return null;
    return trophies.map((t) => t.type).reduce((a, b) => a.index > b.index ? a : b);
  }

  /// Create a copy of this community with some fields updated
  Community copyWith({
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
    return Community(
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        leaderId,
        level,
        totalPlayers,
        points,
        trophyCount,
        followCount,
        playerIds,
        followerIds,
        trophies,
        logoUrl,
        createdAt,
        lastActivityAt,
        rankingTier,
        memberCount,
        communityPoints,
        achievementCount,
        achievements,
      ];
} 