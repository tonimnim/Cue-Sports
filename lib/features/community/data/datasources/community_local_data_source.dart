import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_model.dart';
import '../models/community_member_model.dart';

/// Interface for local data source operations related to community features
/// Handles caching of community data for offline access
abstract class CommunityLocalDataSource {
  // Community caching
  Future<List<CommunityModel>> getCachedCommunities();
  Future<void> cacheCommunities(List<CommunityModel> communities);
  Future<void> clearCachedCommunities();

  // Member caching
  Future<List<CommunityMemberModel>> getCachedMembers(String communityId);
  Future<void> cacheMembers(
      String communityId, List<CommunityMemberModel> members);
  Future<void> clearCachedMembers(String communityId);

  // User community caching
  Future<CommunityModel?> getCachedUserCommunity(String userId);
  Future<void> cacheUserCommunity(String userId, CommunityModel? community);
  Future<void> clearCachedUserCommunity(String userId);
}

/// Implementation of CommunityLocalDataSource using SharedPreferences
class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  final SharedPreferences _sharedPreferences;

  CommunityLocalDataSourceImpl({required SharedPreferences sharedPreferences})
      : _sharedPreferences = sharedPreferences;

  static const String _communitiesKey = 'cached_communities';
  static const String _membersKeyPrefix = 'cached_members_';
  static const String _userCommunityKeyPrefix = 'cached_user_community_';

  @override
  Future<List<CommunityModel>> getCachedCommunities() async {
    try {
      final jsonString = _sharedPreferences.getString(_communitiesKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => CommunityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheCommunities(List<CommunityModel> communities) async {
    try {
      final jsonString =
          json.encode(communities.map((c) => c.toJson()).toList());
      await _sharedPreferences.setString(_communitiesKey, jsonString);
    } catch (e) {
      // Ignore caching errors
    }
  }

  @override
  Future<void> clearCachedCommunities() async {
    await _sharedPreferences.remove(_communitiesKey);
  }

  @override
  Future<List<CommunityMemberModel>> getCachedMembers(
      String communityId) async {
    try {
      final jsonString =
          _sharedPreferences.getString('$_membersKeyPrefix$communityId');
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) =>
              CommunityMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheMembers(
      String communityId, List<CommunityMemberModel> members) async {
    try {
      final jsonString = json.encode(members.map((m) => m.toJson()).toList());
      await _sharedPreferences.setString(
          '$_membersKeyPrefix$communityId', jsonString);
    } catch (e) {
      // Ignore caching errors
    }
  }

  @override
  Future<void> clearCachedMembers(String communityId) async {
    await _sharedPreferences.remove('$_membersKeyPrefix$communityId');
  }

  @override
  Future<CommunityModel?> getCachedUserCommunity(String userId) async {
    try {
      final jsonString =
          _sharedPreferences.getString('$_userCommunityKeyPrefix$userId');
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return CommunityModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserCommunity(
      String userId, CommunityModel? community) async {
    try {
      if (community == null) {
        await _sharedPreferences.remove('$_userCommunityKeyPrefix$userId');
      } else {
        final jsonString = json.encode(community.toJson());
        await _sharedPreferences.setString(
            '$_userCommunityKeyPrefix$userId', jsonString);
      }
    } catch (e) {
      // Ignore caching errors
    }
  }

  @override
  Future<void> clearCachedUserCommunity(String userId) async {
    await _sharedPreferences.remove('$_userCommunityKeyPrefix$userId');
  }
}
