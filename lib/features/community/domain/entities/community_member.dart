import 'package:equatable/equatable.dart';

/// Role of a community member
enum CommunityRole {
  /// Regular member
  member,
  
  /// Community leader
  leader,
  
  /// Community moderator
  moderator,
}

/// Entity representing a member of a community
class CommunityMember extends Equatable {
  final String id;
  final String userId;
  final String communityId;
  final String displayName;
  final String? profileImageUrl;
  final CommunityRole role;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final int points;
  final int rank;
  final List<String> achievements;
  final List<String> badges;

  const CommunityMember({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.displayName,
    this.profileImageUrl,
    required this.role,
    required this.joinedAt,
    this.lastActiveAt,
    this.points = 0,
    this.rank = 0,
    this.achievements = const [],
    this.badges = const [],
  });

  /// Check if member is a leader
  bool get isLeader => role == CommunityRole.leader;

  /// Check if member is a moderator
  bool get isModerator => role == CommunityRole.moderator;

  /// Check if member has achievements
  bool get hasAchievements => achievements.isNotEmpty;

  /// Check if member has badges
  bool get hasBadges => badges.isNotEmpty;

  /// Create a copy of this member with some fields updated
  CommunityMember copyWith({
    String? id,
    String? userId,
    String? communityId,
    String? displayName,
    String? profileImageUrl,
    CommunityRole? role,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    int? points,
    int? rank,
    List<String>? achievements,
    List<String>? badges,
  }) {
    return CommunityMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        communityId,
        displayName,
        profileImageUrl,
        role,
        joinedAt,
        lastActiveAt,
        points,
        rank,
        achievements,
        badges,
      ];
} 