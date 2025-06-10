import '../models/community_model.dart';
import '../models/community_member_model.dart';

/// Interface for remote data source operations related to community features
/// Defines the contract for Firebase operations
abstract class CommunityRemoteDataSource {
  // ======== CORE COMMUNITY OPERATIONS ========

  /// Get all communities
  Future<List<CommunityModel>> getCommunities();

  /// Get community by ID
  Future<CommunityModel> getCommunityById(String id);

  // ======== COMMUNITY SEARCH & FILTERING ========

  /// Search communities
  Future<List<CommunityModel>> searchCommunities(String query);

  /// Get communities by location
  Future<List<CommunityModel>> getCommunityByLocation(String location);

  /// Get top ranked communities
  Future<List<CommunityModel>> getTopRankedCommunities({int limit = 10});

  // ======== USER-COMMUNITY RELATIONSHIPS ========

  /// Get user's community
  Future<CommunityModel?> getUserCommunity(String userId);

  /// Check if user is community member
  Future<bool> isUserCommunityMember({
    required String communityId,
    required String userId,
  });

  // ======== MEMBER MANAGEMENT ========

  /// Join community (for players)
  Future<void> joinCommunity(String communityId, String userId);

  /// Leave community (for players)
  Future<void> leaveCommunity(String communityId, String userId);

  /// Get community members
  Future<List<CommunityMemberModel>> getCommunityMembers(String communityId);
}
