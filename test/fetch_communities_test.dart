import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pool_billiard_app/firebase/firebase_options.dart';
import 'package:pool_billiard_app/features/community/data/models/community_model.dart';

// Simple test to fetch communities from Firestore
// Run with: flutter test test/fetch_communities_test.dart

void main() {
  group('Community Fetch Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      // Note: This would require proper Firebase test configuration
      // For now, this is just the structure
    });

    test('Fetch communities from Firestore', () async {
      try {
        print('\n==== Pool Billiards Community Fetch Test ====');

        // Initialize Firestore
        final firestore = FirebaseFirestore.instance;

        // Fetch communities collection
        print('🔍 Fetching communities from Firestore...');
        final querySnapshot = await firestore.collection('communities').get();

        print('📊 Found ${querySnapshot.docs.length} communities in database');

        if (querySnapshot.docs.isEmpty) {
          print('⚠️ No communities found. Database may be empty.');
          print('💡 Use the Database Setup Screen to add sample communities.');
          return;
        }

        // Create a list of CommunityModel objects from the query results
        final List<CommunityModel> communities = querySnapshot.docs
            .map((doc) => CommunityModel.fromFirestore(doc))
            .toList();

        // Print each community's details using the proper model
        print('\n📋 Communities List:');
        for (int i = 0; i < communities.length; i++) {
          final community = communities[i];

          print('Community #${i + 1}: ${community.name}');
          print('  ID: ${community.id}');
          print('  Description: ${community.description ?? 'No description'}');
          print('  Location: ${community.location}');
          print('  Members: ${community.memberCount}');
          print('  Community Points: ${community.communityPoints}');
          print('  Trophy Count: ${community.trophyCount}');
          print(
              '  Achievements: ${community.achievements?.join(', ') ?? 'None'}');
          print('  Leader ID: ${community.leaderId}');
          print('  Created: ${community.createdAt}');
          print('');

          // Test conversion to entity
          final entity = community.toEntity();
          print('  ✅ Successfully converted to entity: ${entity.name}');
          print('');
        }

        print('✅ Community fetch test completed successfully!');
      } catch (e, stackTrace) {
        print('❌ Error fetching communities: $e');
        print('🔥 Stack trace: $stackTrace');

        // Common issues and suggestions
        print('\n🛠️ Troubleshooting suggestions:');
        print('1. Check Firebase configuration (google-services.json)');
        print('2. Verify Firestore security rules allow reading communities');
        print('3. Ensure internet connectivity');
        print('4. Run the Database Setup Screen to add sample data');
        print('5. Check if Firebase project is properly initialized');

        rethrow;
      }
    });
  });
}
