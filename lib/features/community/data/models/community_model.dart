import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/community.dart';

/// Model class for communities
class CommunityModel extends Community {
  const CommunityModel({
    required String id,
    required String name,
    required String description,
    required String initials,
    String? logoUrl,
    required String location,
    required String county,
    required int memberCount,
    required int followerCount,
    List<String> followers = const [],
    required DateTime createdAt,
    required DateTime lastActivityAt,
    required List<String> tags,
    required String adminUserId,
  }) : super(
          id: id,
          name: name,
          description: description,
          initials: initials,
          logoUrl: logoUrl,
          location: location,
          county: county,
          memberCount: memberCount,
          followerCount: followerCount,
          followers: followers,
          createdAt: createdAt,
          lastActivityAt: lastActivityAt,
          tags: tags,
          adminUserId: adminUserId,
        );

  /// Create a CommunityModel from a JSON map
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      location: json['location'] as String? ?? '',
      county: json['county'] as String? ?? '',
      memberCount: _safeInt(json['memberCount']),
      followerCount: _safeInt(json['followerCount']),
      followers: _safeStringList(json['followers']),
      createdAt: _safeDateTime(json['createdAt']) ?? DateTime.now(),
      lastActivityAt: _safeDateTime(json['lastActivityAt']) ?? DateTime.now(),
      tags: _safeStringList(json['tags']),
      adminUserId: json['adminUserId'] as String? ?? '',
    );
  }

  /// Convert this model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'initials': initials,
      'logoUrl': logoUrl,
      'location': location,
      'county': county,
      'memberCount': memberCount,
      'followerCount': followerCount,
      'followers': followers,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'tags': tags,
      'adminUserId': adminUserId,
    };
  }

  /// Create a CommunityModel from a Community entity
  factory CommunityModel.fromEntity(Community community) {
    return CommunityModel(
      id: community.id,
      name: community.name,
      description: community.description,
      initials: community.initials,
      logoUrl: community.logoUrl,
      location: community.location,
      county: community.county,
      memberCount: community.memberCount,
      followerCount: community.followerCount,
      followers: community.followers,
      createdAt: community.createdAt,
      lastActivityAt: community.lastActivityAt,
      tags: community.tags,
      adminUserId: community.adminUserId,
    );
  }

  /// Convert this model to a Community entity
  Community toEntity() {
    return Community(
      id: id,
      name: name,
      description: description,
      initials: initials,
      logoUrl: logoUrl,
      location: location,
      county: county,
      memberCount: memberCount,
      followerCount: followerCount,
      followers: followers,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      tags: tags,
      adminUserId: adminUserId,
    );
  }

  /// Helper method to safely parse integers
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper method to safely parse doubles
  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper method to safely parse string lists
  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Helper method to safely parse DateTime
  static DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
