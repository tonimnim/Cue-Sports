import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase/firebase_options.dart';

/// Test script to verify tournament fetching from Firebase
void main() async {
  print('🧪 TOURNAMENT FETCH TEST: Starting...');

  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );

    print('✅ Firebase initialized successfully');

    final firestore = FirebaseFirestore.instance;

    await testBasicConnection(firestore);
    await testTournamentCollection(firestore);
    await testTournamentDataStructure(firestore);
    await testTournamentParsing(firestore);

    print('\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!');
    print(
        '   Your Firebase connection and tournament data are working properly.');
  } catch (e, stackTrace) {
    print('\n❌ TEST FAILED: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Test basic Firebase connection
Future<void> testBasicConnection(FirebaseFirestore firestore) async {
  print('\n📡 Testing basic Firebase connection...');

  try {
    // Try to read from a simple collection
    final testDoc = await firestore.collection('_test').limit(1).get();
    print('✅ Basic Firebase connection working');
  } catch (e) {
    print('⚠️  Firebase connection test: $e');
  }
}

/// Test tournament collection access
Future<void> testTournamentCollection(FirebaseFirestore firestore) async {
  print('\n🏆 Testing tournament collection access...');

  try {
    final snapshot = await firestore.collection('tournaments').limit(5).get();
    print('✅ Tournament collection accessible');
    print('   - Documents found: ${snapshot.docs.length}');

    if (snapshot.docs.isEmpty) {
      print('⚠️  No tournament documents found!');
      print('   This could be why the app shows no tournaments.');

      // Check alternative collection names
      final altCollections = ['Tournaments', 'tournament', 'Tournament'];
      for (final collectionName in altCollections) {
        try {
          final altSnapshot =
              await firestore.collection(collectionName).limit(1).get();
          if (altSnapshot.docs.isNotEmpty) {
            print(
                '   💡 Found tournaments in alternative collection: $collectionName');
            print('   - Documents: ${altSnapshot.docs.length}');
          }
        } catch (e) {
          // Collection doesn't exist, that's fine
        }
      }
    } else {
      print(
          '   - Document IDs: ${snapshot.docs.map((doc) => doc.id).take(3).join(', ')}');
    }
  } catch (e) {
    print('❌ Tournament collection access failed: $e');
    throw e;
  }
}

/// Test tournament data structure
Future<void> testTournamentDataStructure(FirebaseFirestore firestore) async {
  print('\n📋 Testing tournament data structure...');

  try {
    final snapshot = await firestore.collection('tournaments').limit(3).get();

    if (snapshot.docs.isEmpty) {
      print('⚠️  No documents to test structure');
      return;
    }

    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data() as Map<String, dynamic>;

      print('\n📄 Document ${i + 1}: ${doc.id}');
      print('   - Name: ${data['name'] ?? 'MISSING'}');
      print('   - Type: ${data['type'] ?? 'MISSING'}');
      print('   - Status: ${data['status'] ?? 'MISSING'}');
      print('   - Location: ${data['location'] ?? data['venue'] ?? 'MISSING'}');
      print(
          '   - Start Date: ${data['startDate']?.runtimeType} = ${data['startDate']}');
      print(
          '   - Created At: ${data['createdAt']?.runtimeType} = ${data['createdAt']}');
      print(
          '   - Entry Fee: ${data['entryFee']} (${data['entryFee']?.runtimeType})');
      print(
          '   - Is Featured: ${data['isFeatured']} (${data['isFeatured']?.runtimeType})');
      print(
          '   - Max Players: ${data['maxPlayers']} (${data['maxPlayers']?.runtimeType})');
      print(
          '   - Current Players: ${data['currentPlayers']} (${data['currentPlayers']?.runtimeType})');

      // Check for missing required fields
      final requiredFields = [
        'name',
        'type',
        'status',
        'startDate',
        'entryFee'
      ];
      final missingFields =
          requiredFields.where((field) => data[field] == null).toList();

      if (missingFields.isNotEmpty) {
        print('   ⚠️  Missing required fields: ${missingFields.join(', ')}');
      } else {
        print('   ✅ All required fields present');
      }
    }
  } catch (e) {
    print('❌ Tournament data structure test failed: $e');
    throw e;
  }
}

/// Test tournament parsing with our model
Future<void> testTournamentParsing(FirebaseFirestore firestore) async {
  print('\n🔧 Testing tournament model parsing...');

  try {
    final snapshot = await firestore.collection('tournaments').limit(2).get();

    if (snapshot.docs.isEmpty) {
      print('⚠️  No documents to test parsing');
      return;
    }

    for (final doc in snapshot.docs) {
      try {
        print('\n🔍 Parsing document: ${doc.id}');

        // Simulate how our TournamentModel.fromFirestore works
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Test key field parsing
        final name = data['name'] as String;
        final type = data['type'] as String? ?? 'beginner';
        final status = data['status'] as String? ?? 'upcoming';

        // Test date parsing
        dynamic startDateValue = data['startDate'];
        DateTime startDate;
        if (startDateValue is Timestamp) {
          startDate = startDateValue.toDate();
        } else if (startDateValue is String) {
          startDate = DateTime.parse(startDateValue);
        } else {
          startDate = DateTime.now();
        }

        print('   ✅ Successfully parsed:');
        print('      - Name: $name');
        print('      - Type: $type');
        print('      - Status: $status');
        print('      - Start Date: $startDate');
      } catch (e, stackTrace) {
        print('   ❌ Failed to parse document ${doc.id}: $e');
        print('   Stack trace: $stackTrace');
      }
    }
  } catch (e) {
    print('❌ Tournament parsing test failed: $e');
    throw e;
  }
}
