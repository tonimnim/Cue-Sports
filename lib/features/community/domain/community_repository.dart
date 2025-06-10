import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import 'entities/community.dart';
import 'entities/community_member.dart';

/// Repository interface for community operations
///
/// This defines operations related to communities in the Kenya Pool Billiards app
/// Follows Clean Architecture principles with clear separation of concerns
abstract class CommunityRepository {
  /// Get all communities
  Future<Either<Failure, List<Community>>> getCommunities();

  /// Get a specific community by ID
  Future<Either<Failure, Community>> getCommunityById(String id);

  /// Get communities by location
  Future<Either<Failure, List<Community>>> getCommunitiesByLocation(
      String location);

  /// Search communities by query
  Future<Either<Failure, List<Community>>> searchCommunities(String query);

  /// Get top ranked communities
  Future<Either<Failure, List<Community>>> getTopRankedCommunities(
      {int limit = 10});

  /// Get user's community (for players)
  Future<Either<Failure, Community?>> getUserCommunity(String userId);

  /// Join a community (for players)
  Future<Either<Failure, void>> joinCommunity({
    required String userId,
    required String communityId,
  });

  /// Leave a community (for players)
  Future<Either<Failure, void>> leaveCommunity({
    required String userId,
    required String communityId,
  });

  /// Check if user is a member of a specific community
  Future<Either<Failure, bool>> isUserCommunityMember({
    required String userId,
    required String communityId,
  });

  /// Get community members
  Future<Either<Failure, List<CommunityMember>>> getCommunityMembers(
      String communityId);
}
