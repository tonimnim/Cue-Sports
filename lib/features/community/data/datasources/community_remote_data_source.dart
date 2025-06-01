import '../models/community_model.dart';
import '../models/community_member_model.dart';
import '../models/community_post_model.dart';
import '../models/community_event_model.dart';
import '../../domain/entities/community_member.dart';

/// Interface for remote data source operations related to community features
/// Defines the contract for Firebase operations
abstract class CommunityRemoteDataSource {
  // ======== CORE COMMUNITY OPERATIONS ========
  
  /// Get all communities
  Future<List<CommunityModel>> getCommunities();
  
  /// Get community by ID
  Future<CommunityModel> getCommunityById(String id);
  
  /// Create a new community
  Future<CommunityModel> createCommunity({
    required String name,
    required String location,
    required String leaderId,
    String? description,
    String? logoUrl,
  });
  
  /// Update community
  Future<CommunityModel> updateCommunity(CommunityModel community);
  
  /// Delete community
  Future<bool> deleteCommunity(String communityId);

  // ======== COMMUNITY SEARCH & FILTERING ========
  
  /// Search communities
  Future<List<CommunityModel>> searchCommunities(String query);
  
  /// Get communities by location
  Future<List<CommunityModel>> getCommunityByLocation(String location);
  
  /// Get top ranked communities
  Future<List<CommunityModel>> getTopRankedCommunities({int limit = 10});
  
  /// Get popular communities
  Future<List<CommunityModel>> getPopularCommunities();

  // ======== USER-COMMUNITY RELATIONSHIPS ========
  
  /// Get user's community
  Future<CommunityModel?> getUserCommunity(String userId);
  
  /// Get all user communities
  Future<List<CommunityModel>> getUserCommunities(String userId);
  
  /// Check if user is community member
  Future<bool> isUserCommunityMember({
    required String communityId,
    required String userId,
  });
  
  /// Get community member count
  Future<int> getCommunityMemberCount(String communityId);
  
  /// Get community achievements
  Future<List<String>> getCommunityAchievements(String communityId);

  // ======== MEMBER MANAGEMENT ========
  
  /// Join community (returns member data)
  Future<CommunityMemberModel> joinCommunity(String communityId, String userId);
  
  /// Leave community
  Future<bool> leaveCommunity(String communityId, String userId);
  
  /// Get community members
  Future<List<CommunityMemberModel>> getCommunityMembers(String communityId);
  
  /// Update member role
  Future<CommunityMemberModel> updateMemberRole(
    String communityId, 
    String userId, 
    CommunityRole role
  );
  
  /// Remove member
  Future<bool> removeMember(String communityId, String userId);

  // ======== POST MANAGEMENT ========
  
  /// Create post
  Future<CommunityPostModel> createPost(CommunityPostModel post);
  
  /// Update post
  Future<CommunityPostModel> updatePost(CommunityPostModel post);
  
  /// Delete post
  Future<bool> deletePost(String postId);
  
  /// Get community posts
  Future<List<CommunityPostModel>> getCommunityPosts(
    String communityId, {
    int limit = 20, 
    String? lastPostId
  });
  
  /// Like post
  Future<bool> likePost(String postId, String userId);
  
  /// Unlike post
  Future<bool> unlikePost(String postId, String userId);
  
  /// Pin post
  Future<bool> pinPost(String postId);
  
  /// Unpin post
  Future<bool> unpinPost(String postId);

  // ======== EVENT MANAGEMENT ========
  
  /// Create event
  Future<CommunityEventModel> createEvent(CommunityEventModel event);
  
  /// Update event
  Future<CommunityEventModel> updateEvent(CommunityEventModel event);
  
  /// Delete event
  Future<bool> deleteEvent(String eventId);
  
  /// Get community events
  Future<List<CommunityEventModel>> getCommunityEvents(
    String communityId, {
    bool includeEnded = false
  });
  
  /// Register for event
  Future<bool> registerForEvent(String eventId, String userId);
  
  /// Unregister from event
  Future<bool> unregisterFromEvent(String eventId, String userId);
  
  /// Get user registered events
  Future<List<CommunityEventModel>> getUserRegisteredEvents(String userId);
  
  /// Cancel event
  Future<bool> cancelEvent(String eventId);
} 