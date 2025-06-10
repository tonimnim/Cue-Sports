import 'package:equatable/equatable.dart';

/// Entity representing a fan following a community
class CommunityFollower extends Equatable {
  final String id;
  final String userId; // Fan user ID
  final String communityId;
  final DateTime followedAt;
  final bool receiveNotifications;

  const CommunityFollower({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.followedAt,
    this.receiveNotifications = true,
  });

  /// Create a copy of this follower with some fields updated
  CommunityFollower copyWith({
    String? id,
    String? userId,
    String? communityId,
    DateTime? followedAt,
    bool? receiveNotifications,
  }) {
    return CommunityFollower(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      followedAt: followedAt ?? this.followedAt,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        communityId,
        followedAt,
        receiveNotifications,
      ];

  @override
  String toString() {
    return 'CommunityFollower{id: $id, userId: $userId, communityId: $communityId, followedAt: $followedAt}';
  }
}
