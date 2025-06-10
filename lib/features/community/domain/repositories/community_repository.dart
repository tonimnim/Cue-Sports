import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/community.dart';

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

  /// Leave a community
  Future<Either<Failure, void>> leaveCommunity({
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
  Future<Either<Failure, List<Community>>> getCommunitiesByLocation(
      String location);

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

  // TODO: Community events and posts features to be implemented in future versions
  // These features are not yet available but may be added later
}
