import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/community_repository.dart';
import '../datasources/community_local_data_source.dart';
import '../datasources/community_remote_data_source.dart';
import '../models/community_model.dart';
import '../models/community_event_model.dart';
import '../models/community_post_model.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;
  final CommunityLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;

  CommunityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  // ======== CORE COMMUNITY OPERATIONS ========

  @override
  Future<Either<Failure, List<Community>>> getCommunities() async {
    try {
      if (await networkInfo.isConnected) {
        final communities = await remoteDataSource.getCommunities();
        await localDataSource.cacheCommunities(communities);
        return Right(communities);
      } else {
        final cachedCommunities = await localDataSource.getCachedCommunities();
        return Right(cachedCommunities);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      logger.e('Unexpected error in getCommunities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> getCommunityById(String communityId) async {
    try {
      final community = await remoteDataSource.getCommunityById(communityId);
      return Right(community);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community by ID: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity({
    required String name,
    required String leaderId,
    required String location,
    String? description,
  }) async {
    try {
      final community = await remoteDataSource.createCommunity(
        name: name,
        location: location,
        leaderId: leaderId,
        description: description,
      );
      return Right(community);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error creating community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> updateCommunity(Community community) async {
    try {
      final communityModel = CommunityModel(
        id: community.id,
        name: community.name,
        description: community.description,
        location: community.location,
        leaderId: community.leaderId,
        level: community.level,
        totalPlayers: community.totalPlayers,
        points: community.points,
        trophyCount: community.trophyCount,
        followCount: community.followCount,
        playerIds: community.playerIds,
        followerIds: community.followerIds,
        trophies: community.trophies,
        createdAt: community.createdAt,
        logoUrl: community.logoUrl,
        lastActivityAt: community.lastActivityAt,
        rankingTier: community.rankingTier,
        memberCount: community.memberCount,
        communityPoints: community.communityPoints,
        achievementCount: community.achievementCount,
        achievements: community.achievements,
      );
      final updatedCommunity = await remoteDataSource.updateCommunity(communityModel);
      return Right(updatedCommunity);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error updating community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCommunity(String communityId) async {
    try {
      await remoteDataSource.deleteCommunity(communityId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error deleting community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== COMMUNITY SEARCH & FILTERING ========

  @override
  Future<Either<Failure, List<Community>>> searchCommunities(String query) async {
    try {
      final communities = await remoteDataSource.searchCommunities(query);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error searching communities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunityByLocation(String location) async {
    try {
      final communities = await remoteDataSource.getCommunityByLocation(location);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting communities by location: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getTopRankedCommunities({int limit = 10}) async {
    try {
      final communities = await remoteDataSource.getTopRankedCommunities(limit: limit);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting top ranked communities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getPopularCommunities() async {
    try {
      final communities = await remoteDataSource.getPopularCommunities();
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting popular communities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== USER-COMMUNITY RELATIONSHIPS ========

  @override
  Future<Either<Failure, Community?>> getUserCommunity(String userId) async {
    try {
      final community = await remoteDataSource.getUserCommunity(userId);
      return Right(community);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting user community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getUserCommunities(String userId) async {
    try {
      final communities = await remoteDataSource.getUserCommunities(userId);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting user communities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity({
    required String userId,
    required String communityId,
  }) async {
    try {
      await remoteDataSource.joinCommunity(communityId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error joining community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> leaveCommunity(String communityId, String userId) async {
    try {
      await remoteDataSource.leaveCommunity(communityId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error leaving community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserCommunityMember({
    required String userId,
    required String communityId,
  }) async {
    try {
      final isMember = await remoteDataSource.isUserCommunityMember(
        communityId: communityId,
        userId: userId,
      );
      return Right(isMember);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error checking community membership: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== COMMUNITY MEMBERS MANAGEMENT ========

  @override
  Future<Either<Failure, int>> getCommunityMemberCount(String communityId) async {
    try {
      final count = await remoteDataSource.getCommunityMemberCount(communityId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community member count: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(String communityId) async {
    try {
      final members = await remoteDataSource.getCommunityMembers(communityId);
      return Right(members);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community members: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommunityMember>> updateMemberRole(
    String communityId,
    String userId,
    CommunityRole role,
  ) async {
    try {
      final member = await remoteDataSource.updateMemberRole(communityId, userId, role);
      return Right(member);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error updating member role: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> removeMember(String communityId, String userId) async {
    try {
      await remoteDataSource.removeMember(communityId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error removing member: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== COMMUNITY POSTS MANAGEMENT ========

  @override
  Future<Either<Failure, CommunityPost>> createPost(CommunityPost post) async {
    try {
      final postModel = CommunityPostModel(
        id: post.id,
        communityId: post.communityId,
        authorId: post.authorId,
        title: post.title,
        content: post.content,
        type: post.type,
        attachments: post.attachments,
        imageUrls: post.imageUrls,
        tags: post.tags,
        likes: post.likes,
        likedBy: post.likedBy,
        likesCount: post.likesCount,
        commentCount: post.commentCount,
        isLocked: post.isLocked,
        isPinned: post.isPinned,
        isActive: post.isActive,
        isEdited: post.isEdited,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      );
      final createdPost = await remoteDataSource.createPost(postModel);
      return Right(createdPost);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error creating post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommunityPost>> updatePost(CommunityPost post) async {
    try {
      final postModel = CommunityPostModel(
        id: post.id,
        communityId: post.communityId,
        authorId: post.authorId,
        title: post.title,
        content: post.content,
        type: post.type,
        attachments: post.attachments,
        imageUrls: post.imageUrls,
        tags: post.tags,
        likes: post.likes,
        likedBy: post.likedBy,
        likesCount: post.likesCount,
        commentCount: post.commentCount,
        isLocked: post.isLocked,
        isPinned: post.isPinned,
        isActive: post.isActive,
        isEdited: post.isEdited,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      );
      final updatedPost = await remoteDataSource.updatePost(postModel);
      return Right(updatedPost);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error updating post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error deleting post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommunityPost>>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    String? lastPostId,
  }) async {
    try {
      final posts = await remoteDataSource.getCommunityPosts(
        communityId,
        limit: limit,
        lastPostId: lastPostId,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community posts: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> likePost(String postId, String userId) async {
    try {
      await remoteDataSource.likePost(postId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error liking post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unlikePost(String postId, String userId) async {
    try {
      await remoteDataSource.unlikePost(postId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error unliking post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> pinPost(String postId) async {
    try {
      await remoteDataSource.pinPost(postId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error pinning post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unpinPost(String postId) async {
    try {
      await remoteDataSource.unpinPost(postId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error unpinning post: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== COMMUNITY EVENTS MANAGEMENT ========

  @override
  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event) async {
    try {
      final eventModel = CommunityEventModel(
        id: event.id,
        communityId: event.communityId,
        title: event.title,
        description: event.description,
        organizerId: event.organizerId,
        createdBy: event.createdBy,
        startTime: event.startTime,
        endTime: event.endTime,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        type: event.type,
        eventType: event.eventType,
        status: event.status,
        venue: event.venue,
        venueAddress: event.venueAddress,
        location: event.location,
        maxParticipants: event.maxParticipants,
        participants: event.participants,
        registeredParticipants: event.registeredParticipants,
        waitlist: event.waitlist,
        isPrivate: event.isPrivate,
        requiresRegistration: event.requiresRegistration,
        isActive: event.isActive,
        entryFee: event.entryFee,
        prizePool: event.prizePool,
        prizes: event.prizes,
        coverImageUrl: event.coverImageUrl,
        imageUrl: event.imageUrl,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
      final createdEvent = await remoteDataSource.createEvent(eventModel);
      return Right(createdEvent);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error creating event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommunityEvent>> updateEvent(CommunityEvent event) async {
    try {
      final eventModel = CommunityEventModel(
        id: event.id,
        communityId: event.communityId,
        title: event.title,
        description: event.description,
        organizerId: event.organizerId,
        createdBy: event.createdBy,
        startTime: event.startTime,
        endTime: event.endTime,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        type: event.type,
        eventType: event.eventType,
        status: event.status,
        venue: event.venue,
        venueAddress: event.venueAddress,
        location: event.location,
        maxParticipants: event.maxParticipants,
        participants: event.participants,
        registeredParticipants: event.registeredParticipants,
        waitlist: event.waitlist,
        isPrivate: event.isPrivate,
        requiresRegistration: event.requiresRegistration,
        isActive: event.isActive,
        entryFee: event.entryFee,
        prizePool: event.prizePool,
        prizes: event.prizes,
        coverImageUrl: event.coverImageUrl,
        imageUrl: event.imageUrl,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
      final updatedEvent = await remoteDataSource.updateEvent(eventModel);
      return Right(updatedEvent);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error updating event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteEvent(String eventId) async {
    try {
      await remoteDataSource.deleteEvent(eventId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error deleting event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getCommunityEvents(
    String communityId, {
    bool includeEnded = false,
  }) async {
    try {
      final events = await remoteDataSource.getCommunityEvents(
        communityId,
        includeEnded: includeEnded,
      );
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community events: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> registerForEvent(String eventId, String userId) async {
    try {
      await remoteDataSource.registerForEvent(eventId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error registering for event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unregisterFromEvent(String eventId, String userId) async {
    try {
      await remoteDataSource.unregisterFromEvent(eventId, userId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error unregistering from event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getUserRegisteredEvents(String userId) async {
    try {
      final events = await remoteDataSource.getUserRegisteredEvents(userId);
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting user registered events: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelEvent(String eventId) async {
    try {
      await remoteDataSource.cancelEvent(eventId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error canceling event: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ======== COMMUNITY ACHIEVEMENTS ========

  @override
  Future<Either<Failure, List<String>>> getCommunityAchievements(String communityId) async {
    try {
      final achievements = await remoteDataSource.getCommunityAchievements(communityId);
      return Right(achievements);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community achievements: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
} 