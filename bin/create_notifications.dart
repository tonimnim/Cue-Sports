import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase/firebase_options.dart';

/// Script to create notification system structure and sample notifications
/// This sets up the essential notification types for the MVP
/// Run with: flutter run --target=bin/create_notifications.dart

void main() async {
  print('🚀 Starting notification system setup...');

  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );

    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Create notification types first
    await _createNotificationTypes(firestore, now);

    // Create sample notifications
    await _createSampleNotifications(firestore, now);

    // Create notification settings
    await _createNotificationSettings(firestore, now);

    print('\n✨ Notification system setup completed successfully!');
    print('\n🎯 Collections created:');
    print(
        '   • notification_types - Notification type definitions & templates');
    print('   • notifications - Sample notification documents');
    print('   • notification_settings - User notification preferences');
    print('\n📱 Ready for web app integration!');
    print(
        '   Your web app engineer can now send notifications using the structure defined.');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Create notification types collection with all supported notification types
Future<void> _createNotificationTypes(
    FirebaseFirestore firestore, DateTime now) async {
  print('📝 Creating notification types...');

  final notificationTypes = [
    // HIGH PRIORITY NOTIFICATIONS
    {
      'id': 'COMMUNITY_UPDATE',
      'name': 'Community Update',
      'description': 'Updates from community leaders to members and followers',
      'priority': 'high',
      'category': 'community',
      'allowedSenders': ['community_admin', 'community_leader'],
      'recipientTypes': ['players', 'fans', 'all'],
      'template': {
        'title': '{communityName} Update',
        'message': '{message}',
        'action': 'open_community',
      },
    },
    {
      'id': 'PAYMENT_SUCCESS',
      'name': 'Payment Success',
      'description': 'Confirmation when payments are successful',
      'priority': 'high',
      'category': 'payment',
      'allowedSenders': ['system'],
      'recipientTypes': ['user'],
      'template': {
        'title': 'Payment Successful',
        'message':
            'Your payment of KSh {amount} has been processed successfully',
        'action': 'open_payment_history',
      },
    },
    {
      'id': 'TOURNAMENT_NEW',
      'name': 'New Tournament',
      'description': 'Notification when new tournaments are created',
      'priority': 'high',
      'category': 'tournament',
      'allowedSenders': ['admin', 'tournament_organizer'],
      'recipientTypes': ['players', 'fans', 'all'],
      'template': {
        'title': 'New Tournament: {tournamentName}',
        'message':
            'Registration opens {registrationDate}. Entry fee: KSh {entryFee}',
        'action': 'open_tournament',
      },
    },
    {
      'id': 'TOURNAMENT_REGISTRATION_OPEN',
      'name': 'Tournament Registration Open',
      'description': 'When tournament registration opens',
      'priority': 'high',
      'category': 'tournament',
      'allowedSenders': ['system'],
      'recipientTypes': ['players'],
      'template': {
        'title': 'Registration Open: {tournamentName}',
        'message': 'Register now! Limited spots available.',
        'action': 'register_tournament',
      },
    },

    // MEDIUM PRIORITY NOTIFICATIONS
    {
      'id': 'MATCH_RESULT',
      'name': 'Match Result',
      'description': 'Match results and tournament updates',
      'priority': 'medium',
      'category': 'match',
      'allowedSenders': ['system', 'referee', 'admin'],
      'recipientTypes': ['players', 'fans'],
      'template': {
        'title': 'Match Result',
        'message': '{winner} defeated {loser} in {tournamentName}',
        'action': 'view_match_details',
      },
    },
    {
      'id': 'SHOP_ORDER_UPDATE',
      'name': 'Shop Order Update',
      'description': 'Updates on shop orders (processing, shipped, delivered)',
      'priority': 'medium',
      'category': 'shop',
      'allowedSenders': ['system', 'shop_admin'],
      'recipientTypes': ['user'],
      'template': {
        'title': 'Order Update',
        'message': 'Your order #{orderNumber} is now {status}',
        'action': 'view_order',
      },
    },
    {
      'id': 'ADMIN_MESSAGE',
      'name': 'Admin Message',
      'description':
          'Messages from admins to encourage upgrades or general announcements',
      'priority': 'medium',
      'category': 'admin',
      'allowedSenders': ['admin', 'super_admin'],
      'recipientTypes': ['fans', 'players', 'all'],
      'template': {
        'title': '{title}',
        'message': '{message}',
        'action': '{action}',
      },
    },
    {
      'id': 'PLAYER_UPGRADE_PROMPT',
      'name': 'Player Upgrade Prompt',
      'description': 'Encourage fans to upgrade to players',
      'priority': 'medium',
      'category': 'admin',
      'allowedSenders': ['admin'],
      'recipientTypes': ['fans'],
      'template': {
        'title': 'Become a Player Today!',
        'message':
            'Join {communityName} as a player and participate in tournaments',
        'action': 'upgrade_to_player',
      },
    },

    // SYSTEM NOTIFICATIONS
    {
      'id': 'NEW_PLAYER',
      'name': 'New Player Registration',
      'description': 'Notify community admin when new player joins',
      'priority': 'low',
      'category': 'system',
      'allowedSenders': ['system'],
      'recipientTypes': ['community_admin'],
      'template': {
        'title': 'New Player Registration',
        'message': '{playerName} has joined your community as a player',
        'action': 'view_community_members',
      },
    },
  ];

  final batch = firestore.batch();

  for (final notificationType in notificationTypes) {
    final docRef = firestore
        .collection('notification_types')
        .doc(notificationType['id'] as String);

    batch.set(docRef, {
      ...notificationType,
      'createdAt': now.toIso8601String(),
      'isActive': true,
    });
  }

  await batch.commit();
  print('✅ Created ${notificationTypes.length} notification types');
}

/// Create sample notifications to demonstrate the structure
Future<void> _createSampleNotifications(
    FirebaseFirestore firestore, DateTime now) async {
  print('📝 Creating sample notifications...');

  // Sample notifications for different users and scenarios
  final sampleNotifications = [
    // Community update notification
    {
      'recipientId': 'sample_player_001', // Would be real user ID
      'recipientType': 'player',
      'type': 'COMMUNITY_UPDATE',
      'title': 'Downtown Players Update',
      'message':
          'New weekly training sessions every Wednesday at 7 PM. Come improve your skills!',
      'read': false,
      'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'data': {
        'communityId': 'downtown_players_001',
        'communityName': 'Downtown Players',
        'action': 'open_community',
      },
      'priority': 'high',
      'category': 'community',
    },

    // Payment success notification
    {
      'recipientId': 'sample_player_001',
      'recipientType': 'player',
      'type': 'PAYMENT_SUCCESS',
      'title': 'Payment Successful',
      'message':
          'Your community membership payment of KSh 500 has been processed successfully',
      'read': false,
      'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'data': {
        'paymentId': 'payment_12345',
        'amount': 500.0,
        'action': 'open_payment_history',
      },
      'priority': 'high',
      'category': 'payment',
    },

    // Tournament notification
    {
      'recipientId': 'sample_player_001',
      'recipientType': 'player',
      'type': 'TOURNAMENT_NEW',
      'title': 'New Tournament: Nairobi Open Championship',
      'message': 'Registration opens tomorrow at 9 AM. Entry fee: KSh 1,000',
      'read': false,
      'createdAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      'data': {
        'tournamentId': 'tournament_001',
        'tournamentName': 'Nairobi Open Championship',
        'entryFee': 1000.0,
        'registrationDate': now.add(const Duration(days: 1)).toIso8601String(),
        'action': 'open_tournament',
      },
      'priority': 'high',
      'category': 'tournament',
    },

    // Admin message to fan
    {
      'recipientId': 'sample_fan_001',
      'recipientType': 'fan',
      'type': 'PLAYER_UPGRADE_PROMPT',
      'title': 'Become a Player Today!',
      'message':
          'Join Downtown Players as a player and participate in exciting tournaments!',
      'read': false,
      'createdAt': now.subtract(const Duration(hours: 6)).toIso8601String(),
      'data': {
        'communityId': 'downtown_players_001',
        'communityName': 'Downtown Players',
        'action': 'upgrade_to_player',
      },
      'priority': 'medium',
      'category': 'admin',
    },

    // Shop order update
    {
      'recipientId': 'sample_player_001',
      'recipientType': 'player',
      'type': 'SHOP_ORDER_UPDATE',
      'title': 'Order Update',
      'message':
          'Your order #ORD001 is now being processed and will be shipped soon',
      'read': true,
      'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      'data': {
        'orderId': 'ORD001',
        'orderNumber': 'ORD001',
        'status': 'processing',
        'action': 'view_order',
      },
      'priority': 'medium',
      'category': 'shop',
    },
  ];

  final batch = firestore.batch();

  for (final notification in sampleNotifications) {
    final docRef = firestore.collection('notifications').doc();
    batch.set(docRef, notification);
  }

  await batch.commit();
  print('✅ Created ${sampleNotifications.length} sample notifications');
}

/// Create notification settings for users
Future<void> _createNotificationSettings(
    FirebaseFirestore firestore, DateTime now) async {
  print('📝 Creating notification settings...');

  final notificationSettings = [
    {
      'userId': 'sample_player_001',
      'settings': {
        'pushNotifications': true,
        'emailNotifications': false,
        'categories': {
          'community': true,
          'tournament': true,
          'payment': true,
          'shop': true,
          'admin': true,
          'match': true,
        },
        'priorities': {
          'high': true,
          'medium': true,
          'low': false,
        },
        'quietHours': {
          'enabled': true,
          'startTime': '22:00',
          'endTime': '07:00',
        },
      },
      'updatedAt': now.toIso8601String(),
    },
    {
      'userId': 'sample_fan_001',
      'settings': {
        'pushNotifications': true,
        'emailNotifications': true,
        'categories': {
          'community': true,
          'tournament': true,
          'payment': true,
          'shop': false,
          'admin': true,
          'match': false,
        },
        'priorities': {
          'high': true,
          'medium': true,
          'low': false,
        },
        'quietHours': {
          'enabled': false,
        },
      },
      'updatedAt': now.toIso8601String(),
    },
  ];

  final batch = firestore.batch();

  for (final setting in notificationSettings) {
    final docRef = firestore
        .collection('notification_settings')
        .doc(setting['userId'] as String);
    batch.set(docRef, setting);
  }

  await batch.commit();
  print(
      '✅ Created notification settings for ${notificationSettings.length} users');
}
