import 'package:equatable/equatable.dart';

/// Community entity representing a billiards community
class Community extends Equatable {
  final String id;
  final String name;
  final String description;
  final String initials; // e.g., "EP", "KP"
  final String? logoUrl;

  // Location (No GPS coordinates - just county and location)
  final String location; // e.g., "Embakasi", "Downtown"
  final String county; // e.g., "Nairobi", "Mombasa"

  // Metrics & Status
  final int memberCount; // Only for players who joined
  final int followerCount; // For fans who follow
  final List<String> followers; // List of user IDs who follow this community
  final DateTime createdAt;
  final DateTime lastActivityAt;

  // Categorization
  final List<String> tags; // ["Competitive", "Embakasi", "Weekly Events"]

  // Admin & Management
  final String adminUserId; // Only one admin per community

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.initials,
    this.logoUrl,
    required this.location,
    required this.county,
    required this.memberCount,
    required this.followerCount,
    this.followers = const [], // Default to empty list
    required this.createdAt,
    required this.lastActivityAt,
    required this.tags,
    required this.adminUserId,
  });

  /// Create a copy of this community with some fields updated
  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? initials,
    String? logoUrl,
    String? location,
    String? county,
    int? memberCount,
    int? followerCount,
    List<String>? followers,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    List<String>? tags,
    String? adminUserId,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      initials: initials ?? this.initials,
      logoUrl: logoUrl ?? this.logoUrl,
      location: location ?? this.location,
      county: county ?? this.county,
      memberCount: memberCount ?? this.memberCount,
      followerCount: followerCount ?? this.followerCount,
      followers: followers ?? this.followers,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      tags: tags ?? this.tags,
      adminUserId: adminUserId ?? this.adminUserId,
    );
  }

  // TODO: Follow functionality removed for version 1
  // Will be re-implemented in version 2 with proper follow system

  /// Check if a user is following this community
  /// Always returns false since follow functionality is disabled
  bool isFollowedBy(String userId) {
    return false; // Follow functionality disabled
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        initials,
        logoUrl,
        location,
        county,
        memberCount,
        followerCount,
        followers,
        createdAt,
        lastActivityAt,
        tags,
        adminUserId,
      ];

  @override
  String toString() {
    return 'Community{id: $id, name: $name, location: $location, county: $county, memberCount: $memberCount, followerCount: $followerCount}';
  }
}
