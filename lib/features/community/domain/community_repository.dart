import 'package:dartz/dartz.dart';
import 'entities/community_member.dart';
import 'entities/community_post.dart';
import 'entities/community_event.dart';
import 'entities/community.dart';
import '../../../core/error/failures.dart';

/// Repository interface for Community operations
///
/// This defines operations related to communities in the Kenya Pool Billiards app
/// Follows Clean Architecture principles with clear separation of concerns
abstract class CommunityRepository {
  // ======== CORE COMMUNITY OPERATIONS ========
  
  /// Get all active communities
  Future<Either<Failure, List<Community>>> getCommunities();
  
  /// Get community by ID
  Future<Either<Failure, Community>> getCommunityById(String communityId);
  
  /// Create a new community
  Future<Either<Failure, Community>> createCommunity({
    required String name,
    required String leaderId,
    required String location,
    String? description,
  });
  
  /// Update community details
  Future<Either<Failure, Community>> updateCommunity(Community community);
  
  /// Delete a community
  Future<Either<Failure, bool>> deleteCommunity(String communityId);

  // ======== COMMUNITY SEARCH & FILTERING ========
  
  /// Search communities by name or location
  Future<Either<Failure, List<Community>>> searchCommunities(String query);
  
  /// Get communities by location
  Future<Either<Failure, List<Community>>> getCommunityByLocation(String location);
  
  /// Get top ranked communities
  Future<Either<Failure, List<Community>>> getTopRankedCommunities({int limit = 10});
  
  /// Get popular communities
  Future<Either<Failure, List<Community>>> getPopularCommunities();

  // ======== USER-COMMUNITY RELATIONSHIPS ========
  
  /// Get user's community (the one they're a member of)
  Future<Either<Failure, Community?>> getUserCommunity(String userId);
  
  /// Get all communities a user is associated with
  Future<Either<Failure, List<Community>>> getUserCommunities(String userId);
  
  /// Join a community
  Future<Either<Failure, void>> joinCommunity({
    required String userId, 
    required String communityId,
  });
  
  /// Leave a community
  Future<Either<Failure, bool>> leaveCommunity(String communityId, String userId);
  
  /// Check if user is a member of a specific community
  Future<Either<Failure, bool>> isUserCommunityMember({
    required String userId,
    required String communityId,
  });

  // ======== COMMUNITY MEMBERS MANAGEMENT ========
  
  /// Get community member count
  Future<Either<Failure, int>> getCommunityMemberCount(String communityId);
  
  /// Get all members of a community
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(String communityId);
  
  /// Update member role
  Future<Either<Failure, CommunityMember>> updateMemberRole(
    String communityId, 
    String userId, 
    CommunityRole role
  );
  
  /// Remove member from community
  Future<Either<Failure, bool>> removeMember(String communityId, String userId);

  // ======== COMMUNITY POSTS MANAGEMENT ========
  
  /// Create a new post
  Future<Either<Failure, CommunityPost>> createPost(CommunityPost post);
  
  /// Update an existing post
  Future<Either<Failure, CommunityPost>> updatePost(CommunityPost post);
  
  /// Delete a post
  Future<Either<Failure, bool>> deletePost(String postId);
  
  /// Get posts for a community
  Future<Either<Failure, List<CommunityPost>>> getCommunityPosts(
    String communityId, {
    int limit = 20, 
    String? lastPostId
  });
  
  /// Like a post
  Future<Either<Failure, bool>> likePost(String postId, String userId);
  
  /// Unlike a post
  Future<Either<Failure, bool>> unlikePost(String postId, String userId);
  
  /// Pin a post
  Future<Either<Failure, bool>> pinPost(String postId);
  
  /// Unpin a post
  Future<Either<Failure, bool>> unpinPost(String postId);

  // ======== COMMUNITY EVENTS MANAGEMENT ========
  
  /// Create a new event
  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event);
  
  /// Update an existing event
  Future<Either<Failure, CommunityEvent>> updateEvent(CommunityEvent event);
  
  /// Delete an event
  Future<Either<Failure, bool>> deleteEvent(String eventId);
  
  /// Get events for a community
  Future<Either<Failure, List<CommunityEvent>>> getCommunityEvents(
    String communityId, {
    bool includeEnded = false
  });
  
  /// Register user for an event
  Future<Either<Failure, bool>> registerForEvent(String eventId, String userId);
  
  /// Unregister user from an event
  Future<Either<Failure, bool>> unregisterFromEvent(String eventId, String userId);
  
  /// Get events user is registered for
  Future<Either<Failure, List<CommunityEvent>>> getUserRegisteredEvents(String userId);
  
  /// Cancel an event
  Future<Either<Failure, bool>> cancelEvent(String eventId);

  // ======== COMMUNITY ACHIEVEMENTS ========
  
  /// Get community achievements
  Future<Either<Failure, List<String>>> getCommunityAchievements(String communityId);
}
