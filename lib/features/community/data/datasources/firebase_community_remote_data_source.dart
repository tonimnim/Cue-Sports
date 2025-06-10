import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../models/community_model.dart';
import '../models/community_member_model.dart';
import 'community_remote_data_source.dart';

class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseCommunityRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Collection references
  CollectionReference get _communitiesRef =>
      _firestore.collection('communities');

  // Helper method for member reference
  DocumentReference _memberRef(String communityId, String userId) =>
      _communitiesRef.doc(communityId).collection('members').doc(userId);

  @override
  Future<List<CommunityModel>> getCommunities() async {
    try {
      final snapshot = await _communitiesRef.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get communities: $e');
    }
  }

  @override
  Future<CommunityModel> getCommunityById(String id) async {
    try {
      final doc = await _communitiesRef.doc(id).get();
      if (!doc.exists) {
        throw const ServerException('Community not found');
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Community data is null');
      }

      return CommunityModel.fromJson({...data, 'id': doc.id});
    } catch (e) {
      throw ServerException('Failed to get community: $e');
    }
  }

  @override
  Future<List<CommunityModel>> searchCommunities(String query) async {
    try {
      print('🔍 DEBUG: Searching communities with query: "$query"');

      // Get all communities first (since Firestore doesn't support case-insensitive search well)
      final allCommunitiesSnapshot = await _communitiesRef.get();

      final allCommunities = allCommunitiesSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityModel>()
          .toList();

      print('📄 DEBUG: Total communities fetched: ${allCommunities.length}');

      // Filter communities locally for better search experience
      final queryLower = query.toLowerCase();
      final filteredCommunities = allCommunities.where((community) {
        final nameLower = community.name.toLowerCase();
        final locationLower = community.location.toLowerCase();

        final nameMatches = nameLower.contains(queryLower);
        final locationMatches = locationLower.contains(queryLower);

        return nameMatches || locationMatches;
      }).toList();

      print(
          '✅ DEBUG: Filtered communities found: ${filteredCommunities.length}');
      for (final community in filteredCommunities) {
        print('   - ${community.name} (${community.location})');
      }

      return filteredCommunities;
    } catch (e) {
      print('🔥 DEBUG: Search error: $e');
      throw ServerException('Failed to search communities: $e');
    }
  }

  @override
  Future<List<CommunityModel>> getCommunityByLocation(String location) async {
    try {
      final snapshot =
          await _communitiesRef.where('location', isEqualTo: location).get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get communities by location: $e');
    }
  }

  @override
  Future<List<CommunityModel>> getTopRankedCommunities({int limit = 10}) async {
    try {
      final snapshot = await _communitiesRef
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get top ranked communities: $e');
    }
  }

  @override
  Future<CommunityModel?> getUserCommunity(String userId) async {
    try {
      print('🔍 DEBUG: Getting user community for userId: $userId');

      // Get user document to find their community ID (for players)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ DEBUG: User document does not exist for userId: $userId');
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      print('📄 DEBUG: User data: $userData');

      final communityId = userData?['communityId'] as String?;
      print('🏢 DEBUG: User communityId: $communityId');

      // If user is a player (has communityId), return their community
      if (communityId != null && communityId.isNotEmpty) {
        print('✅ DEBUG: Fetching community with ID: $communityId');
        final community = await getCommunityById(communityId);
        print('🏢 DEBUG: Found community: ${community.name}');
        return community;
      }

      print('⚠️ DEBUG: User has no communityId or it is empty');
      // TODO: Follow functionality disabled for version 1
      // Fans will not have communities until follow is re-implemented in version 2
      return null;
    } catch (e) {
      print('🔥 DEBUG: Error getting user community: $e');
      throw ServerException('Failed to get user community: $e');
    }
  }

  @override
  Future<bool> isUserCommunityMember({
    required String communityId,
    required String userId,
  }) async {
    try {
      final memberDoc = await _memberRef(communityId, userId).get();
      return memberDoc.exists;
    } catch (e) {
      throw ServerException('Failed to check community membership: $e');
    }
  }

  @override
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      // Get user data for display name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final displayName = userData?['fullName'] as String? ?? 'Unknown User';

      final memberData = CommunityMemberModel(
        id: '$communityId-$userId',
        userId: userId,
        communityId: communityId,
        displayName: displayName,
        joinedAt: DateTime.now(),
        points: 0,
        rank: 0,
        achievements: const [],
        badges: const [],
      );

      await _memberRef(communityId, userId).set(memberData.toJson());
    } catch (e) {
      throw ServerException('Failed to join community: $e');
    }
  }

  @override
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _memberRef(communityId, userId).delete();
    } catch (e) {
      throw ServerException('Failed to leave community: $e');
    }
  }

  @override
  Future<List<CommunityMemberModel>> getCommunityMembers(
      String communityId) async {
    try {
      final snapshot =
          await _communitiesRef.doc(communityId).collection('members').get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityMemberModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityMemberModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get community members: $e');
    }
  }
}
