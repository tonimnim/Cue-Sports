import '../../domain/entities/community_member.dart';

/// Model class for community members
class CommunityMemberModel extends CommunityMember {
  const CommunityMemberModel({
    required String id,
    required String userId,
    required String communityId,
    required String displayName,
    String? profileImageUrl,
    required DateTime joinedAt,
    DateTime? lastActiveAt,
    int points = 0,
    int rank = 0,
    List<String> achievements = const [],
    List<String> badges = const [],
  }) : super(
          id: id,
          userId: userId,
          communityId: communityId,
          displayName: displayName,
          profileImageUrl: profileImageUrl,
          joinedAt: joinedAt,
          lastActiveAt: lastActiveAt,
          points: points,
          rank: rank,
          achievements: achievements,
          badges: badges,
        );

  /// Create a CommunityMemberModel from a map
  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      communityId: json['communityId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      points: json['points'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      badges: List<String>.from(json['badges'] as List? ?? []),
    );
  }

  /// Create a CommunityMemberModel from a CommunityMember entity
  factory CommunityMemberModel.fromEntity(CommunityMember entity) {
    return CommunityMemberModel(
      id: entity.id,
      userId: entity.userId,
      communityId: entity.communityId,
      displayName: entity.displayName,
      profileImageUrl: entity.profileImageUrl,
      joinedAt: entity.joinedAt,
      lastActiveAt: entity.lastActiveAt,
      points: entity.points,
      rank: entity.rank,
      achievements: entity.achievements,
      badges: entity.badges,
    );
  }

  /// Convert to entity (since this extends CommunityMember, it can be used directly)
  CommunityMember toEntity() => this;

  /// Convert the CommunityMemberModel to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'communityId': communityId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'points': points,
      'rank': rank,
      'achievements': achievements,
      'badges': badges,
    };
  }

  /// Create a copy of this model with some fields updated
  CommunityMemberModel copyWith({
    String? id,
    String? userId,
    String? communityId,
    String? displayName,
    String? profileImageUrl,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    int? points,
    int? rank,
    List<String>? achievements,
    List<String>? badges,
  }) {
    return CommunityMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
    );
  }
}
