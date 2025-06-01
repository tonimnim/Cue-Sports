import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/community_member.dart';
import '../models/community_model.dart';
import '../models/community_member_model.dart';
import '../models/community_post_model.dart';
import '../models/community_event_model.dart';
import 'community_remote_data_source.dart';

/// Firebase implementation of the CommunityRemoteDataSource
class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseCommunityRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Collection references
  CollectionReference get _communitiesRef => _firestore.collection('communities');
  CollectionReference get _postsRef => _firestore.collection('community_posts');
  CollectionReference get _eventsRef => _firestore.collection('community_events');

  // Helper method to get community member reference
  DocumentReference _memberRef(String communityId, String userId) {
    return _communitiesRef.doc(communityId).collection('members').doc(userId);
  }

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
  Future<CommunityModel> getCommunityById(String communityId) async {
    try {
      final doc = await _communitiesRef.doc(communityId).get();
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
  Future<CommunityModel> createCommunity({
    required String name,
    required String location,
    required String leaderId,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final communityData = {
        'name': name,
        'location': location,
        'leaderId': leaderId,
        'description': description,
        'logoUrl': logoUrl,
        'level': 'local',
        'totalPlayers': 0,
        'points': 0,
        'trophyCount': 0,
        'followCount': 0,
        'playerIds': <String>[],
        'followerIds': <String>[],
        'trophies': <Map<String, dynamic>>[],
        'createdAt': DateTime.now().toIso8601String(),
        'lastActivityAt': DateTime.now().toIso8601String(),
        'rankingTier': 'Intermediate',
        'memberCount': 0,
        'communityPoints': 0,
        'achievementCount': 0,
        'achievements': <String>[],
      };

      final docRef = await _communitiesRef.add(communityData);
      return CommunityModel.fromJson({...communityData, 'id': docRef.id});
    } catch (e) {
      throw ServerException('Failed to create community: $e');
    }
  }

  @override
  Future<CommunityModel> updateCommunity(CommunityModel community) async {
    try {
      await _communitiesRef.doc(community.id).update(community.toJson());
      return community;
    } catch (e) {
      throw ServerException('Failed to update community: $e');
    }
  }

  @override
  Future<bool> deleteCommunity(String communityId) async {
    try {
      await _communitiesRef.doc(communityId).delete();
      return true;
    } catch (e) {
      throw ServerException('Failed to delete community: $e');
    }
  }

  @override
  Future<CommunityMemberModel> joinCommunity(String communityId, String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const ServerException('User not authenticated');

      // Get user data to retrieve display name
      String displayName = 'Unknown User';
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          displayName = userData?['displayName'] as String? ??
              userData?['name'] as String? ??
              user.displayName ??
              user.email?.split('@').first ??
              'User';
        } else {
          // Fallback to Firebase Auth user data
          displayName = user.displayName ??
              user.email?.split('@').first ??
              'User';
        }
      } catch (e) {
        // If user data fetch fails, use Firebase Auth fallback
        displayName = user.displayName ??
            user.email?.split('@').first ??
            'User';
      }

      final memberData = CommunityMemberModel(
        id: '$communityId-$userId',
        userId: userId,
        communityId: communityId,
        displayName: displayName,
        role: CommunityRole.member,
        joinedAt: DateTime.now(),
        points: 0,
        rank: 0,
        achievements: const [],
        badges: const [],
      );

      await _memberRef(communityId, userId).set(memberData.toJson());
      return memberData;
    } catch (e) {
      throw ServerException('Failed to join community: $e');
    }
  }

  @override
  Future<bool> leaveCommunity(String communityId, String userId) async {
    try {
      await _memberRef(communityId, userId).delete();
      return true;
    } catch (e) {
      throw ServerException('Failed to leave community: $e');
    }
  }

  @override
  Future<List<CommunityMemberModel>> getCommunityMembers(String communityId) async {
    try {
      final snapshot = await _communitiesRef
          .doc(communityId)
          .collection('members')
          .get();

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

  @override
  Future<CommunityMemberModel> updateMemberRole(
    String communityId,
    String userId,
    CommunityRole role,
  ) async {
    try {
      final memberRef = _memberRef(communityId, userId);
      final memberDoc = await memberRef.get();

      if (!memberDoc.exists) {
        throw const ServerException('Member not found');
      }

      final memberData = memberDoc.data() as Map<String, dynamic>?;
      if (memberData == null) {
        throw const ServerException('Member data is null');
      }

      final updatedMember = CommunityMemberModel.fromJson({...memberData, 'id': memberDoc.id})
          .copyWith(role: role);

      await memberRef.update({'role': role.toString().split('.').last});
      return updatedMember;
    } catch (e) {
      throw ServerException('Failed to update member role: $e');
    }
  }

  @override
  Future<bool> removeMember(String communityId, String userId) async {
    try {
      await _memberRef(communityId, userId).delete();
      return true;
    } catch (e) {
      throw ServerException('Failed to remove member: $e');
    }
  }

  @override
  Future<List<CommunityModel>> getUserCommunities(String userId) async {
    try {
      // Get communities where user is a member
      final snapshot = await _communitiesRef
          .where('playerIds', arrayContains: userId)
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
      throw ServerException('Failed to get user communities: $e');
    }
  }

  @override
  Future<CommunityPostModel> createPost(CommunityPostModel post) async {
    try {
      final docRef = _postsRef.doc();
      final postWithId = post.copyWith(id: docRef.id);
      await docRef.set(postWithId.toJson());
      return postWithId;
    } catch (e) {
      throw ServerException('Failed to create post: $e');
    }
  }

  @override
  Future<CommunityPostModel> updatePost(CommunityPostModel post) async {
    try {
      await _postsRef.doc(post.id).update(post.toJson());
      return post;
    } catch (e) {
      throw ServerException('Failed to update post: $e');
    }
  }

  @override
  Future<bool> deletePost(String postId) async {
    try {
      await _postsRef.doc(postId).delete();
      return true;
    } catch (e) {
      throw ServerException('Failed to delete post: $e');
    }
  }

  @override
  Future<List<CommunityPostModel>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    String? lastPostId,
  }) async {
    try {
      Query query = _postsRef
          .where('communityId', isEqualTo: communityId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastDoc = await _postsRef.doc(lastPostId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityPostModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityPostModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get community posts: $e');
    }
  }

  @override
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _postsRef.doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      throw ServerException('Failed to like post: $e');
    }
  }

  @override
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _postsRef.doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      throw ServerException('Failed to unlike post: $e');
    }
  }

  @override
  Future<bool> pinPost(String postId) async {
    try {
      await _postsRef.doc(postId).update({'isPinned': true});
      return true;
    } catch (e) {
      throw ServerException('Failed to pin post: $e');
    }
  }

  @override
  Future<bool> unpinPost(String postId) async {
    try {
      await _postsRef.doc(postId).update({'isPinned': false});
      return true;
    } catch (e) {
      throw ServerException('Failed to unpin post: $e');
    }
  }

  @override
  Future<CommunityEventModel> createEvent(CommunityEventModel event) async {
    try {
      final docRef = _eventsRef.doc();
      final eventWithId = event.copyWith(id: docRef.id);
      await docRef.set(eventWithId.toJson());
      return eventWithId;
    } catch (e) {
      throw ServerException('Failed to create event: $e');
    }
  }

  @override
  Future<CommunityEventModel> updateEvent(CommunityEventModel event) async {
    try {
      await _eventsRef.doc(event.id).update(event.toJson());
      return event;
    } catch (e) {
      throw ServerException('Failed to update event: $e');
    }
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _eventsRef.doc(eventId).delete();
      return true;
    } catch (e) {
      throw ServerException('Failed to delete event: $e');
    }
  }

  @override
  Future<List<CommunityEventModel>> getCommunityEvents(
    String communityId, {
    bool includeEnded = false,
  }) async {
    try {
      Query query = _eventsRef
          .where('communityId', isEqualTo: communityId)
          .orderBy('startTime', descending: false);

      if (!includeEnded) {
        query = query.where('endTime', isGreaterThanOrEqualTo: DateTime.now().toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityEventModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityEventModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get community events: $e');
    }
  }

  @override
  Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      final eventDoc = await _eventsRef.doc(eventId).get();
      final eventData = eventDoc.data() as Map<String, dynamic>?;
      if (eventData == null) {
        throw const ServerException('Event data is null');
      }
      
      final event = CommunityEventModel.fromJson({...eventData, 'id': eventDoc.id});

      // Check if event is full by comparing participants count to maxParticipants
      final participantsCount = event.participants.length;
      final isFull = participantsCount >= event.maxParticipants;

      if (isFull) {
        // Add to waitlist if the event is full
        await _eventsRef.doc(eventId).update({
          'waitlist': FieldValue.arrayUnion([userId]),
        });
      } else {
        // Add to participants if spots are available
        await _eventsRef.doc(eventId).update({
          'participants': FieldValue.arrayUnion([userId]),
        });
      }
      return true;
    } catch (e) {
      throw ServerException('Failed to register for event: $e');
    }
  }

  @override
  Future<bool> unregisterFromEvent(String eventId, String userId) async {
    try {
      final batch = _firestore.batch();
      final eventRef = _eventsRef.doc(eventId);

      // Remove from participants
      batch.update(eventRef, {
        'participants': FieldValue.arrayRemove([userId]),
      });

      // Remove from waitlist if present
      batch.update(eventRef, {
        'waitlist': FieldValue.arrayRemove([userId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      throw ServerException('Failed to unregister from event: $e');
    }
  }

  @override
  Future<List<CommunityEventModel>> getUserRegisteredEvents(String userId) async {
    try {
      final snapshot = await _eventsRef
          .where('participants', arrayContains: userId)
          .orderBy('startTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityEventModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityEventModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get user registered events: $e');
    }
  }

  @override
  Future<bool> cancelEvent(String eventId) async {
    try {
      await _eventsRef.doc(eventId).update({'isCancelled': true});
      return true;
    } catch (e) {
      throw ServerException('Failed to cancel event: $e');
    }
  }

  @override
  Future<List<CommunityModel>> searchCommunities(String query) async {
    try {
      // Search by name (case-insensitive)
      final nameQuery = await _communitiesRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      // Search by location (case-insensitive)
      final locationQuery = await _communitiesRef
          .where('location', isGreaterThanOrEqualTo: query)
          .where('location', isLessThan: query + 'z')
          .get();

      final allDocs = {...nameQuery.docs, ...locationQuery.docs};
      
      return allDocs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return CommunityModel.fromJson({...data, 'id': doc.id});
          })
          .where((model) => model != null)
          .cast<CommunityModel>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to search communities: $e');
    }
  }

  @override
  Future<List<CommunityModel>> getCommunityByLocation(String location) async {
    try {
      final snapshot = await _communitiesRef
          .where('location', isEqualTo: location)
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
      throw ServerException('Failed to get communities by location: $e');
    }
  }

  @override
  Future<List<CommunityModel>> getTopRankedCommunities({int limit = 10}) async {
    try {
      final snapshot = await _communitiesRef
          .orderBy('points', descending: true)
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
  Future<List<CommunityModel>> getPopularCommunities() async {
    try {
      final snapshot = await _communitiesRef
          .orderBy('followCount', descending: true)
          .limit(20)
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
      throw ServerException('Failed to get popular communities: $e');
    }
  }

  @override
  Future<CommunityModel?> getUserCommunity(String userId) async {
    try {
      // Get user document to find their community ID
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final communityId = userData?['communityId'] as String?;
      
      if (communityId == null) {
        return null;
      }

      return await getCommunityById(communityId);
    } catch (e) {
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
  Future<int> getCommunityMemberCount(String communityId) async {
    try {
      final snapshot = await _communitiesRef
          .doc(communityId)
          .collection('members')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw ServerException('Failed to get community member count: $e');
    }
  }

  @override
  Future<List<String>> getCommunityAchievements(String communityId) async {
    try {
      final doc = await _communitiesRef.doc(communityId).get();
      if (!doc.exists) {
        throw const ServerException('Community not found');
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }

      final achievements = data['achievements'] as List?;
      return achievements?.cast<String>() ?? [];
    } catch (e) {
      throw ServerException('Failed to get community achievements: $e');
    }
  }
} 