import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/community.dart';
import '../entities/community_event.dart';
import '../entities/community_post.dart';

/// Repository interface for community operations
abstract class CommunityRepository {
  /// Get all communities
  Future<Either<Failure, List<Community>>> getCommunities();

  /// Get a specific community by ID
  Future<Either<Failure, Community>> getCommunityById(String communityId);

  /// Get the community that a user belongs to
  Future<Either<Failure, Community?>> getUserCommunity(String userId);

  /// Join a community
  Future<Either<Failure, void>> joinCommunity({
    required String userId,
    required String communityId,
  });

  /// Get the number of members in a community
  Future<Either<Failure, int>> getCommunityMemberCount(String communityId);

  /// Get top ranked communities
  Future<Either<Failure, List<Community>>> getTopRankedCommunities({
    int limit = 10,
  });

  /// Search communities by name or location
  Future<Either<Failure, List<Community>>> searchCommunities(String query);

  /// Check if a user is a member of a community
  Future<Either<Failure, bool>> isUserCommunityMember({
    required String userId,
    required String communityId,
  });

  /// Get communities by location
  Future<Either<Failure, List<Community>>> getCommunityByLocation(String location);

  /// Create a new community
  Future<Either<Failure, Community>> createCommunity({
    required String name,
    required String location,
    required String leaderId,
  });

  /// Update an existing community
  Future<Either<Failure, Community>> updateCommunity(Community community);

  /// Delete a community
  Future<Either<Failure, bool>> deleteCommunity(String communityId);

  /// Get community events
  Future<Either<Failure, List<CommunityEvent>>> getCommunityEvents(
    String communityId, {
    bool includeEnded = false,
  });

  /// Create a new event
  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event);

  /// Update an existing event
  Future<Either<Failure, CommunityEvent>> updateEvent(CommunityEvent event);

  /// Delete an event
  Future<Either<Failure, bool>> deleteEvent(String eventId);

  /// Register for an event
  Future<Either<Failure, bool>> registerForEvent(String eventId, String userId);

  /// Unregister from an event
  Future<Either<Failure, bool>> unregisterFromEvent(String eventId, String userId);

  /// Get user's registered events
  Future<Either<Failure, List<CommunityEvent>>> getUserRegisteredEvents(String userId);

  /// Cancel an event
  Future<Either<Failure, bool>> cancelEvent(String eventId);

  /// Get community posts
  Future<Either<Failure, List<CommunityPost>>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    String? lastPostId,
  });

  /// Create a new post
  Future<Either<Failure, CommunityPost>> createPost(CommunityPost post);

  /// Update an existing post
  Future<Either<Failure, CommunityPost>> updatePost(CommunityPost post);

  /// Delete a post
  Future<Either<Failure, bool>> deletePost(String postId);

  /// Like a post
  Future<Either<Failure, bool>> likePost(String postId, String userId);

  /// Unlike a post
  Future<Either<Failure, bool>> unlikePost(String postId, String userId);

  /// Pin a post
  Future<Either<Failure, bool>> pinPost(String postId);

  /// Unpin a post
  Future<Either<Failure, bool>> unpinPost(String postId);
} 