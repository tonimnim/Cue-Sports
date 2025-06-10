import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase/firebase_options.dart';

/// Script to create sample communities in Firebase with all required fields
/// Run this script to populate the database with properly structured community documents

void main() async {
  print('🚀 Starting community creation script...');

  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );

    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Get current timestamp
    final now = DateTime.now();
    final createdAt =
        now.subtract(const Duration(days: 30)); // Created 30 days ago

    // Create 4 sample communities with all required fields
    final communities = [
      {
        'id': 'downtown_players_001',
        'name': 'Downtown Players',
        'description':
            'Premier billiards community in downtown Nairobi. Weekly tournaments, professional coaching, and competitive gameplay for all skill levels.',
        'initials': 'DP',
        'logoUrl': null,
        'location': 'Downtown',
        'county': 'Nairobi',
        'memberCount': 45,
        'followerCount': 0, // Start with 0, will be updated when users follow
        'followers': [], // Empty list, will be populated when users follow
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'tags': [
          'Competitive',
          'Weekly Tournaments',
          'Professional Coaching',
          'Downtown'
        ],
        'skillLevel': 'All Levels',
        'adminUserId': 'admin_downtown_001',
        'membershipFee': 500.0,
      },
      {
        'id': 'eastside_eagles_002',
        'name': 'Eastside Eagles',
        'description':
            'Growing community focused on skill development and friendly competition. Perfect for intermediate players looking to improve their game.',
        'initials': 'EE',
        'logoUrl': null,
        'location': 'Kasarani',
        'county': 'Nairobi',
        'memberCount': 32,
        'followerCount': 0,
        'followers': [],
        'createdAt': createdAt.add(const Duration(days: 5)).toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'tags': [
          'Skill Development',
          'Friendly Competition',
          'Intermediate',
          'Kasarani'
        ],
        'skillLevel': 'Intermediate',
        'adminUserId': 'admin_eastside_002',
        'membershipFee': 400.0,
      },
      {
        'id': 'westlands_warriors_003',
        'name': 'Westlands Warriors',
        'description':
            'Elite community with top-tier facilities and advanced training programs. For serious players who want to compete at the highest level.',
        'initials': 'WW',
        'logoUrl': null,
        'location': 'Westlands',
        'county': 'Nairobi',
        'memberCount': 28,
        'followerCount': 0,
        'followers': [],
        'createdAt': createdAt.add(const Duration(days: 10)).toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'tags': ['Elite', 'Advanced Training', 'Top Facilities', 'Westlands'],
        'skillLevel': 'Advanced',
        'adminUserId': 'admin_westlands_003',
        'membershipFee': 800.0,
      },
      {
        'id': 'mombasa_sharks_004',
        'name': 'Mombasa Sharks',
        'description':
            'Coastal billiards community bringing together players from the beautiful coast. Relaxed atmosphere with serious gameplay.',
        'initials': 'MS',
        'logoUrl': null,
        'location': 'Diani',
        'county': 'Mombasa',
        'memberCount': 22,
        'followerCount': 0,
        'followers': [],
        'createdAt': createdAt.add(const Duration(days: 15)).toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'tags': ['Coastal', 'Relaxed Atmosphere', 'Beach Tournaments', 'Diani'],
        'skillLevel': 'All Levels',
        'adminUserId': 'admin_mombasa_004',
        'membershipFee': 350.0,
      },
    ];

    print('📝 Creating ${communities.length} communities...');

    // Add each community to the batch
    for (int i = 0; i < communities.length; i++) {
      final community = communities[i];
      final docRef =
          firestore.collection('communities').doc(community['id'] as String);

      batch.set(docRef, community);
      print('   ${i + 1}. ${community['name']} (${community['county']})');
    }

    // Execute the batch write
    print('💾 Writing to Firebase...');
    await batch.commit();

    print('✅ Successfully created ${communities.length} communities!');
    print('\n🎯 Communities created:');
    for (final community in communities) {
      print(
          '   • ${community['name']} - ${community['location']}, ${community['county']}');
      print(
          '     Members: ${community['memberCount']}, Skill: ${community['skillLevel']}');
    }

    print(
        '\n✨ All communities now have the complete field structure including:');
    print('   • followers: [] (empty array ready for user IDs)');
    print('   • followerCount: 0 (will increment when users follow)');
    print('   • All other required fields from Community model');

    print('\n🚀 Script completed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
 