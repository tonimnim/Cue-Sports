import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/services/logger_service.dart';
import '../domain/entities/community.dart';
import '../domain/entities/community_event.dart';
import '../domain/entities/community_post.dart';
import '../domain/entities/community_member.dart';
import '../domain/community_repository.dart';
import 'models/community_event_model.dart';
import 'models/community_post_model.dart';
import 'datasources/community_remote_data_source.dart';

/// Implementation of the CommunityRepository
///
/// Handles all community-related operations for players and fans
class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final LoggerService logger;

  CommunityRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<Community>>> getCommunities() async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting all communities');
        final communities = await remoteDataSource.getCommunities();
        return Right(communities.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting communities', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting communities', e);
        return Left(ServerFailure(message: 'Failed to get communities: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Community>> getCommunityById(String communityId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting community by ID: $communityId');
        final community = await remoteDataSource.getCommunityById(communityId);
        return Right(community.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when getting community by ID', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community by ID', e);
        return Left(ServerFailure(message: 'Failed to get community: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Community?>> getUserCommunity(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting user\'s community for user: $userId');
        final communities = await remoteDataSource.getUserCommunities(userId);
        if (communities.isEmpty) {
          return const Right(null);
        }
        // Get the first community (assuming user can be in one primary community)
        return Right(communities.first.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when getting user\'s community', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting user\'s community', e);
        return Left(ServerFailure(message: 'Failed to get user\'s community: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity({
    required String userId,
    required String communityId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId joining community $communityId');
        await remoteDataSource.joinCommunity(communityId, userId);
        return const Right(null);
      } on ServerException catch (e) {
        logger.e('Server failure when joining community', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when joining community', e);
        return Left(ServerFailure(message: 'Failed to join community: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, int>> getCommunityMemberCount(String communityId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting member count for community: $communityId');
        final members = await remoteDataSource.getCommunityMembers(communityId);
        return Right(members.length);
      } on ServerException catch (e) {
        logger.e('Server failure when getting community member count', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community member count', e);
        return Left(ServerFailure(message: 'Failed to get community member count: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getTopRankedCommunities({int limit = 10}) async {
    // This is equivalent to getPopularCommunities
    return await getPopularCommunities();
  }

  @override
  Future<Either<Failure, List<Community>>> searchCommunities(String query) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Searching communities with query: "$query"');
        final communities = await remoteDataSource.getCommunities();
        // Filter communities by name containing the query (case-insensitive)
        final filtered = communities.where((c) => 
          c.name.toLowerCase().contains(query.toLowerCase()) ||
          (c.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
        return Right(filtered.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when searching communities', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when searching communities', e);
        return Left(ServerFailure(message: 'Failed to search communities: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserCommunityMember({
    required String userId,
    required String communityId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Checking if user $userId is member of community $communityId');
        final userCommunities = await remoteDataSource.getUserCommunities(userId);
        return Right(userCommunities.contains(communityId));
      } on ServerException catch (e) {
        logger.e('Server failure when checking community membership', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when checking community membership', e);
        return Left(ServerFailure(message: 'Failed to check community membership: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCommunityAchievements(String communityId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting achievements for community: $communityId');
        final community = await remoteDataSource.getCommunityById(communityId);
        return Right(community.achievements ?? []);
      } on ServerException catch (e) {
        logger.e('Server failure when getting community achievements', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community achievements', e);
        return Left(ServerFailure(message: 'Failed to get community achievements: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunityByLocation(String location) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting communities by location: "$location"');
        final communities = await remoteDataSource.getCommunities();
        final filtered = communities.where((c) => 
          c.location.toLowerCase().contains(location.toLowerCase())
        ).toList();
        return Right(filtered.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting communities by location', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting communities by location', e);
        return Left(ServerFailure(message: 'Failed to get communities by location: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity({
    required String name,
    required String leaderId,
    required String location,
    String? description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Creating new community: $name with leader: $leaderId');
        // This would typically call the remoteDataSource.createCommunity method
        // However, since this functionality is primarily for the admin web app,
        // we'll implement a stub that throws an exception for now

        // In a full implementation, you would add a createCommunity method to
        // the remote data source and call it here

        return const Left(ServerFailure(
            message: 'Creating communities is only available through the admin web interface'));
      } on ServerException catch (e) {
        logger.e('Server failure when creating community', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when creating community', e);
        return Left(ServerFailure(message: 'Failed to create community: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // Additional required methods from interface

  @override
  Future<Either<Failure, Community>> updateCommunity(Community community) async {
    return const Left(ServerFailure(message: 'Update community not implemented in mobile app'));
  }

  @override
  Future<Either<Failure, bool>> deleteCommunity(String communityId) async {
    return const Left(ServerFailure(message: 'Delete community not implemented in mobile app'));
  }

  @override
  Future<Either<Failure, Community>> getCommunity(String communityId) async {
    return getCommunityById(communityId);
  }

  @override
  Future<Either<Failure, List<Community>>> getPopularCommunities() async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting popular communities');
        final communities = await remoteDataSource.getCommunities();
        // Sort by member count or points in descending order
        communities.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return Right(communities.take(10).map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting popular communities', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting popular communities', e);
        return Left(ServerFailure(message: 'Failed to get popular communities: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // Member Management
  @override
  Future<Either<Failure, bool>> leaveCommunity(String communityId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId leaving community $communityId');
        final result = await remoteDataSource.leaveCommunity(communityId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when leaving community', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when leaving community', e);
        return Left(ServerFailure(message: 'Failed to leave community: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(String communityId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting members for community: $communityId');
        final members = await remoteDataSource.getCommunityMembers(communityId);
        return Right(members.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting community members', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community members', e);
        return Left(ServerFailure(message: 'Failed to get community members: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CommunityMember>> updateMemberRole(String communityId, String userId, CommunityRole role) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Updating role for user $userId in community $communityId to ${role.name}');
        final memberModel = await remoteDataSource.updateMemberRole(communityId, userId, role);
        return Right(memberModel.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when updating member role', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when updating member role', e);
        return Left(ServerFailure(message: 'Failed to update member role: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeMember(String communityId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Removing user $userId from community $communityId');
        final result = await remoteDataSource.removeMember(communityId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when removing member', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when removing member', e);
        return Left(ServerFailure(message: 'Failed to remove member: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getUserCommunities(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting communities for user: $userId');
        final communities = await remoteDataSource.getUserCommunities(userId);
        return Right(communities.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting user communities', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting user communities', e);
        return Left(ServerFailure(message: 'Failed to get user communities: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // Post Management
  @override
  Future<Either<Failure, CommunityPost>> createPost(CommunityPost post) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Creating post in community: ${post.communityId}');
        final postModel = CommunityPostModel.fromEntity(post);
        final createdPost = await remoteDataSource.createPost(postModel);
        return Right(createdPost.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when creating post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when creating post', e);
        return Left(ServerFailure(message: 'Failed to create post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CommunityPost>> updatePost(CommunityPost post) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Updating post: ${post.id}');
        final postModel = CommunityPostModel.fromEntity(post);
        final updatedPost = await remoteDataSource.updatePost(postModel);
        return Right(updatedPost.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when updating post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when updating post', e);
        return Left(ServerFailure(message: 'Failed to update post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Deleting post: $postId');
        final result = await remoteDataSource.deletePost(postId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when deleting post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when deleting post', e);
        return Left(ServerFailure(message: 'Failed to delete post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityPost>>> getCommunityPosts(String communityId, {int limit = 20, String? lastPostId}) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting posts for community: $communityId');
        final posts = await remoteDataSource.getCommunityPosts(communityId, limit: limit, lastPostId: lastPostId);
        return Right(posts.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting community posts', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community posts', e);
        return Left(ServerFailure(message: 'Failed to get community posts: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> likePost(String postId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId liking post: $postId');
        final result = await remoteDataSource.likePost(postId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when liking post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when liking post', e);
        return Left(ServerFailure(message: 'Failed to like post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unlikePost(String postId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId unliking post: $postId');
        final result = await remoteDataSource.unlikePost(postId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when unliking post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when unliking post', e);
        return Left(ServerFailure(message: 'Failed to unlike post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> pinPost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Pinning post: $postId');
        final result = await remoteDataSource.pinPost(postId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when pinning post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when pinning post', e);
        return Left(ServerFailure(message: 'Failed to pin post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unpinPost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Unpinning post: $postId');
        final result = await remoteDataSource.unpinPost(postId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when unpinning post', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when unpinning post', e);
        return Left(ServerFailure(message: 'Failed to unpin post: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  // Event Management
  @override
  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Creating event in community: ${event.communityId}');
        final eventModel = CommunityEventModel.fromEntity(event);
        final createdEvent = await remoteDataSource.createEvent(eventModel);
        return Right(createdEvent.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when creating event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when creating event', e);
        return Left(ServerFailure(message: 'Failed to create event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CommunityEvent>> updateEvent(CommunityEvent event) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Updating event: ${event.id}');
        final eventModel = CommunityEventModel.fromEntity(event);
        final updatedEvent = await remoteDataSource.updateEvent(eventModel);
        return Right(updatedEvent.toEntity());
      } on ServerException catch (e) {
        logger.e('Server failure when updating event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when updating event', e);
        return Left(ServerFailure(message: 'Failed to update event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteEvent(String eventId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Deleting event: $eventId');
        final result = await remoteDataSource.deleteEvent(eventId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when deleting event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when deleting event', e);
        return Left(ServerFailure(message: 'Failed to delete event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getCommunityEvents(String communityId, {bool includeEnded = false}) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting events for community: $communityId');
        final events = await remoteDataSource.getCommunityEvents(communityId, includeEnded: includeEnded);
        return Right(events.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting community events', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting community events', e);
        return Left(ServerFailure(message: 'Failed to get community events: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> registerForEvent(String eventId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId registering for event: $eventId');
        final result = await remoteDataSource.registerForEvent(eventId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when registering for event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when registering for event', e);
        return Left(ServerFailure(message: 'Failed to register for event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unregisterFromEvent(String eventId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('User $userId unregistering from event: $eventId');
        final result = await remoteDataSource.unregisterFromEvent(eventId, userId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when unregistering from event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when unregistering from event', e);
        return Left(ServerFailure(message: 'Failed to unregister from event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getUserRegisteredEvents(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Getting registered events for user: $userId');
        final events = await remoteDataSource.getUserRegisteredEvents(userId);
        return Right(events.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        logger.e('Server failure when getting user registered events', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when getting user registered events', e);
        return Left(ServerFailure(message: 'Failed to get user registered events: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelEvent(String eventId) async {
    if (await networkInfo.isConnected) {
      try {
        logger.i('Cancelling event: $eventId');
        final result = await remoteDataSource.cancelEvent(eventId);
        return Right(result);
      } on ServerException catch (e) {
        logger.e('Server failure when cancelling event', e);
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Unexpected failure when cancelling event', e);
        return Left(ServerFailure(message: 'Failed to cancel event: $e'));
      }
    } else {
      logger.w('Network not available');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
