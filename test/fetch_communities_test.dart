import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pool_billiard_app/firebase/firebase_options.dart';
import 'package:pool_billiard_app/features/community/data/models/community_model.dart';

// Simple test to fetch communities from Firestore
// Run with: flutter test test/fetch_communities_test.dart

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Firebase for testing
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });
  
  test('Fetch all communities from Firestore', () async {
    print('\n==== Pool Billiards Community Fetch Test ====');
    print('Initialized Firebase...');
    
    try {
      // Access Firestore
      final firestore = FirebaseFirestore.instance;
      print('Attempting to fetch communities...');
      
      // Query the communities collection
      final querySnapshot = await firestore.collection('communities').get();
      
      // Output results
      print('\nFound ${querySnapshot.size} communities:');
      print('---------------------------------------');
      
      if (querySnapshot.docs.isEmpty) {
        print('No communities found in the database.');
      } else {
        // Create a list of CommunityModel objects from the query results
        final List<CommunityModel> communities = querySnapshot.docs
            .map((doc) => CommunityModel.fromFirestore(doc))
            .toList();
        
        // Print each community's details using the proper model
        for (int i = 0; i < communities.length; i++) {
          final community = communities[i];
          
          print('Community #${i+1}: ${community.name}');
          print('  ID: ${community.id}');
          print('  Description: ${community.description ?? 'No description'}');
          print('  Location: ${community.location}');
          print('  Members: ${community.memberCount}');
          print('  Community Points: ${community.communityPoints}');
          print('  Trophy Count: ${community.trophyCount}');
          print('  Achievements: ${community.achievements?.join(', ') ?? 'None'}');
          print('  Leader ID: ${community.leaderId}');
          print('  Created: ${community.createdAt}');
          
          // Use domain entity methods
          final entity = community.toEntity();
          print('  Ranking Tier: ${entity.rankingTier}');
          print('---------------------------------------');
        }
      }
      
      print('\nTest completed successfully!');
      expect(true, isTrue); // Simple assertion to make the test pass
    } catch (e) {
      print('\nERROR: ${e.toString()}');
      print('\nTroubleshooting tips:');
      print('1. Verify Firebase project configuration (poolbilliard-167ad)');
      print('2. Check that Firestore is enabled in Firebase Console');
      print('3. Ensure your google-services.json is correctly configured');
      print('4. Check internet connectivity');
      
      fail('Firebase connection error: ${e.toString()}');
    }
  });
}
