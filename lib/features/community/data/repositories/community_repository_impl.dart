import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/community_repository.dart';
import '../datasources/community_local_data_source.dart';
import '../datasources/community_remote_data_source.dart';
import '../models/community_model.dart';

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
  Future<Either<Failure, Community>> getCommunityById(String id) async {
    try {
      final community = await remoteDataSource.getCommunityById(id);
      return Right(community);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community by ID: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunitiesByLocation(
      String location) async {
    try {
      final communities =
          await remoteDataSource.getCommunityByLocation(location);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting communities by location: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> searchCommunities(
      String query) async {
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
  Future<Either<Failure, List<Community>>> getTopRankedCommunities(
      {int limit = 10}) async {
    try {
      final communities =
          await remoteDataSource.getTopRankedCommunities(limit: limit);
      return Right(communities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting top ranked communities: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community?>> getUserCommunity(String userId) async {
    try {
      // Validate userId before making the call
      if (userId.isEmpty) {
        logger.w('getUserCommunity called with empty userId');
        return const Right(null);
      }

      logger.i('Getting user community for userId: $userId');
      final community = await remoteDataSource.getUserCommunity(userId);
      logger.i('User community result: ${community?.name ?? 'null'}');
      return Right(community);
    } on ServerException catch (e) {
      logger.e('Server error getting user community: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting user community: $e');
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
  Future<Either<Failure, void>> leaveCommunity({
    required String userId,
    required String communityId,
  }) async {
    try {
      await remoteDataSource.leaveCommunity(communityId, userId);
      return const Right(null);
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

  @override
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(
      String communityId) async {
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
  Future<Either<Failure, int>> getCommunityMemberCount(
      String communityId) async {
    try {
      final members = await remoteDataSource.getCommunityMembers(communityId);
      return Right(members.length);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error getting community member count: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity({
    required String name,
    required String location,
    required String leaderId,
  }) async {
    try {
      // TODO: Implement community creation when needed
      throw const ServerException('Community creation not yet implemented');
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error creating community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Community>> updateCommunity(
      Community community) async {
    try {
      // TODO: Implement community update when needed
      throw const ServerException('Community update not yet implemented');
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
      // TODO: Implement community deletion when needed
      throw const ServerException('Community deletion not yet implemented');
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Error deleting community: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
