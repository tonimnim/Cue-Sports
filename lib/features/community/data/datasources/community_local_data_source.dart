import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../models/community_event_model.dart';

abstract class CommunityLocalDataSource {
  /// Gets the cached list of communities
  Future<List<CommunityModel>> getCachedCommunities();

  /// Caches the list of communities
  Future<void> cacheCommunities(List<CommunityModel> communities);

  /// Gets the cached list of community events
  Future<List<CommunityEventModel>> getCachedEvents(String communityId);

  /// Caches the list of community events
  Future<void> cacheEvents(String communityId, List<CommunityEventModel> events);

  /// Gets the cached list of community posts
  Future<List<CommunityPostModel>> getCachedPosts(String communityId);

  /// Caches the list of community posts
  Future<void> cachePosts(String communityId, List<CommunityPostModel> posts);

  /// Clears all cached data
  Future<void> clearCache();
}

class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  final SharedPreferences sharedPreferences;

  CommunityLocalDataSourceImpl({required this.sharedPreferences});

  static const _communitiesKey = 'CACHED_COMMUNITIES';
  static const _eventsKeyPrefix = 'CACHED_EVENTS_';
  static const _postsKeyPrefix = 'CACHED_POSTS_';

  @override
  Future<List<CommunityModel>> getCachedCommunities() async {
    try {
      final jsonString = sharedPreferences.getString(_communitiesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((item) => CommunityModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw const CacheException('No cached communities found');
    } catch (e) {
      throw const CacheException('Failed to parse cached communities');
    }
  }

  @override
  Future<void> cacheCommunities(List<CommunityModel> communities) async {
    try {
      final jsonString = json.encode(communities.map((c) => c.toJson()).toList());
      await sharedPreferences.setString(_communitiesKey, jsonString);
    } catch (e) {
      throw const CacheException('Failed to cache communities');
    }
  }

  @override
  Future<List<CommunityEventModel>> getCachedEvents(String communityId) async {
    try {
      final jsonString = sharedPreferences.getString('$_eventsKeyPrefix$communityId');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((item) => CommunityEventModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw const CacheException('No cached events found');
    } catch (e) {
      throw const CacheException('Failed to parse cached events');
    }
  }

  @override
  Future<void> cacheEvents(String communityId, List<CommunityEventModel> events) async {
    try {
      final jsonString = json.encode(events.map((e) => e.toJson()).toList());
      await sharedPreferences.setString('$_eventsKeyPrefix$communityId', jsonString);
    } catch (e) {
      throw const CacheException('Failed to cache events');
    }
  }

  @override
  Future<List<CommunityPostModel>> getCachedPosts(String communityId) async {
    try {
      final jsonString = sharedPreferences.getString('$_postsKeyPrefix$communityId');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((item) => CommunityPostModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw const CacheException('No cached posts found');
    } catch (e) {
      throw const CacheException('Failed to parse cached posts');
    }
  }

  @override
  Future<void> cachePosts(String communityId, List<CommunityPostModel> posts) async {
    try {
      final jsonString = json.encode(posts.map((p) => p.toJson()).toList());
      await sharedPreferences.setString('$_postsKeyPrefix$communityId', jsonString);
    } catch (e) {
      throw const CacheException('Failed to cache posts');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final keys = sharedPreferences.getKeys();
      for (final key in keys) {
        if (key == _communitiesKey ||
            key.startsWith(_eventsKeyPrefix) ||
            key.startsWith(_postsKeyPrefix)) {
          await sharedPreferences.remove(key);
        }
      }
    } catch (e) {
      throw const CacheException('Failed to clear cache');
    }
  }
} 