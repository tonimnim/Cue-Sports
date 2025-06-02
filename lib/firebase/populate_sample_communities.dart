import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to populate sample communities in Firestore for testing
/// This should be run once to set up initial data
class PopulateSampleCommunities {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addSampleCommunities() async {
    try {
      print('🏓 Adding sample billiard communities...');

      final sampleCommunities = [
        {
          'name': 'Nairobi Pool Masters',
          'description':
              'Premier billiard community in Nairobi. Join us for weekly tournaments and skill development sessions.',
          'location': 'Nairobi, Kenya',
          'leaderId': 'leader1',
          'level': 'advanced',
          'totalPlayers': 45,
          'points': 2340,
          'trophyCount': 8,
          'followCount': 120,
          'playerIds': [],
          'followerIds': [],
          'trophies': [],
          'memberCount': 45,
          'communityPoints': 2340,
          'achievements': ['Tournament Champions 2024', 'Community Builder'],
          'rankingTier': 'Expert',
          'achievementCount': 2,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivityAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Mombasa Cue Sports',
          'description':
              'Coastal billiard enthusiasts united! Play by the beach and enjoy competitive pool in a relaxed atmosphere.',
          'location': 'Mombasa, Kenya',
          'leaderId': 'leader2',
          'level': 'intermediate',
          'totalPlayers': 32,
          'points': 1850,
          'trophyCount': 5,
          'followCount': 87,
          'playerIds': [],
          'followerIds': [],
          'trophies': [],
          'memberCount': 32,
          'communityPoints': 1850,
          'achievements': ['Coastal Champions'],
          'rankingTier': 'Advanced',
          'achievementCount': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivityAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Kisumu Billiard Club',
          'description':
              'Lakeside community of pool players. We focus on skill development and friendly competition.',
          'location': 'Kisumu, Kenya',
          'leaderId': 'leader3',
          'level': 'intermediate',
          'totalPlayers': 28,
          'points': 1420,
          'trophyCount': 3,
          'followCount': 65,
          'playerIds': [],
          'followerIds': [],
          'trophies': [],
          'memberCount': 28,
          'communityPoints': 1420,
          'achievements': [],
          'rankingTier': 'Intermediate',
          'achievementCount': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivityAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Nakuru Cue Masters',
          'description':
              'A growing community in the Rift Valley. Perfect for beginners and experienced players alike.',
          'location': 'Nakuru, Kenya',
          'leaderId': 'leader4',
          'level': 'beginner',
          'totalPlayers': 18,
          'points': 890,
          'trophyCount': 2,
          'followCount': 42,
          'playerIds': [],
          'followerIds': [],
          'trophies': [],
          'memberCount': 18,
          'communityPoints': 890,
          'achievements': ['Rising Stars'],
          'rankingTier': 'Beginner',
          'achievementCount': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivityAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Eldoret Pool League',
          'description':
              'High-altitude billiards! Join our community for competitive play and skill improvement sessions.',
          'location': 'Eldoret, Kenya',
          'leaderId': 'leader5',
          'level': 'intermediate',
          'totalPlayers': 22,
          'points': 1250,
          'trophyCount': 4,
          'followCount': 58,
          'playerIds': [],
          'followerIds': [],
          'trophies': [],
          'memberCount': 22,
          'communityPoints': 1250,
          'achievements': ['High Altitude Champions'],
          'rankingTier': 'Intermediate',
          'achievementCount': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivityAt': FieldValue.serverTimestamp(),
        }
      ];

      final batch = _firestore.batch();
      final communitiesRef = _firestore.collection('communities');

      for (final community in sampleCommunities) {
        final docRef = communitiesRef.doc();
        batch.set(docRef, community);
      }

      await batch.commit();
      print(
          '✅ Successfully added ${sampleCommunities.length} sample communities!');

      // Verify the communities were added
      final snapshot = await communitiesRef.get();
      print('📊 Total communities in database: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Error adding sample communities: $e');
      rethrow;
    }
  }

  /// Delete all communities (for testing/cleanup)
  static Future<void> clearAllCommunities() async {
    try {
      print('🗑️ Clearing all communities...');

      final snapshot = await _firestore.collection('communities').get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All communities cleared!');
    } catch (e) {
      print('❌ Error clearing communities: $e');
      rethrow;
    }
  }

  /// Check existing communities
  static Future<void> checkExistingCommunities() async {
    try {
      print('🔍 Checking existing communities...');

      final snapshot = await _firestore.collection('communities').get();
      print('📊 Found ${snapshot.docs.length} communities:');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
            '  - ${data['name']} (${data['location']}) - ${data['memberCount']} members');
      }
    } catch (e) {
      print('❌ Error checking communities: $e');
      rethrow;
    }
  }
}
