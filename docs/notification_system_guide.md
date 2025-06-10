# Notification System Guide for Web App

## Overview
This document provides guidance for implementing notifications in the web app that will be received by the mobile app users.

## Firebase Collections Structure

### 1. `notifications` - Main notification documents
Each notification document contains:
```javascript
{
  "recipientId": "user_id",           // Required: ID of user receiving notification
  "recipientType": "player|fan|user", // Required: Type of recipient
  "type": "NOTIFICATION_TYPE",        // Required: Notification type (see types below)
  "title": "Notification Title",     // Required: Display title
  "message": "Notification message", // Required: Display message
  "read": false,                     // Required: Read status (default: false)
  "createdAt": "2024-01-01T12:00:00Z", // Required: ISO timestamp
  "priority": "high|medium|low",     // Required: Priority level
  "category": "community|tournament|payment|shop|admin|match|system",
  "data": {                          // Required: Additional data object
    "action": "open_community",      // Optional: Action to trigger
    "communityId": "community_123",  // Context-specific data
    // ... other relevant data
  }
}
```

### 2. `notification_types` - Notification type definitions and templates
Template definitions for each notification type (created by script).

### 3. `notification_settings` - User notification preferences
User preferences for receiving notifications.

## Priority Notification Types for MVP

### HIGH PRIORITY ⚡

#### 1. COMMUNITY_UPDATE
**Purpose**: Community leaders send updates to members and followers
```javascript
{
  "type": "COMMUNITY_UPDATE",
  "title": "{communityName} Update",
  "message": "{your_custom_message}",
  "priority": "high",
  "category": "community",
  "data": {
    "communityId": "community_id",
    "communityName": "Community Name",
    "action": "open_community"
  }
}
```

#### 2. PAYMENT_SUCCESS
**Purpose**: Confirm successful payments
```javascript
{
  "type": "PAYMENT_SUCCESS",
  "title": "Payment Successful",
  "message": "Your payment of KSh {amount} has been processed successfully",
  "priority": "high",
  "category": "payment",
  "data": {
    "paymentId": "payment_123",
    "amount": 500.0,
    "action": "open_payment_history"
  }
}
```

#### 3. TOURNAMENT_NEW
**Purpose**: Announce new tournaments
```javascript
{
  "type": "TOURNAMENT_NEW",
  "title": "New Tournament: {tournamentName}",
  "message": "Registration opens {registrationDate}. Entry fee: KSh {entryFee}",
  "priority": "high",
  "category": "tournament",
  "data": {
    "tournamentId": "tournament_123",
    "tournamentName": "Tournament Name",
    "entryFee": 1000.0,
    "registrationDate": "2024-01-15T09:00:00Z",
    "action": "open_tournament"
  }
}
```

#### 4. TOURNAMENT_REGISTRATION_OPEN
**Purpose**: Notify when tournament registration opens
```javascript
{
  "type": "TOURNAMENT_REGISTRATION_OPEN",
  "title": "Registration Open: {tournamentName}",
  "message": "Register now! Limited spots available.",
  "priority": "high",
  "category": "tournament",
  "data": {
    "tournamentId": "tournament_123",
    "tournamentName": "Tournament Name",
    "action": "register_tournament"
  }
}
```

### MEDIUM PRIORITY ⭐

#### 5. MATCH_RESULT
```javascript
{
  "type": "MATCH_RESULT",
  "title": "Match Result",
  "message": "{winner} defeated {loser} in {tournamentName}",
  "priority": "medium",
  "category": "match",
  "data": {
    "matchId": "match_123",
    "winner": "Player Name",
    "loser": "Player Name",
    "tournamentName": "Tournament Name",
    "action": "view_match_details"
  }
}
```

#### 6. SHOP_ORDER_UPDATE
```javascript
{
  "type": "SHOP_ORDER_UPDATE",
  "title": "Order Update",
  "message": "Your order #{orderNumber} is now {status}",
  "priority": "medium",
  "category": "shop",
  "data": {
    "orderId": "order_123",
    "orderNumber": "ORD001",
    "status": "processing|shipped|delivered",
    "action": "view_order"
  }
}
```

#### 7. ADMIN_MESSAGE
**Purpose**: General admin announcements
```javascript
{
  "type": "ADMIN_MESSAGE",
  "title": "Your Custom Title",
  "message": "Your custom message",
  "priority": "medium",
  "category": "admin",
  "data": {
    "action": "custom_action_or_null"
  }
}
```

#### 8. PLAYER_UPGRADE_PROMPT
**Purpose**: Encourage fans to upgrade to players
```javascript
{
  "type": "PLAYER_UPGRADE_PROMPT",
  "title": "Become a Player Today!",
  "message": "Join {communityName} as a player and participate in tournaments",
  "priority": "medium",
  "category": "admin",
  "data": {
    "communityId": "community_123",
    "communityName": "Community Name",
    "action": "upgrade_to_player"
  }
}
```

## Implementation Guide

### 1. Sending Notifications from Web App

#### Node.js/Firebase Admin SDK Example:
```javascript
const admin = require('firebase-admin');

async function sendNotification(notification) {
  try {
    // Add to Firestore
    await admin.firestore().collection('notifications').add({
      recipientId: notification.recipientId,
      recipientType: notification.recipientType,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      read: false,
      createdAt: new Date().toISOString(),
      priority: notification.priority,
      category: notification.category,
      data: notification.data
    });

    console.log('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// Example usage:
await sendNotification({
  recipientId: 'user_123',
  recipientType: 'player',
  type: 'COMMUNITY_UPDATE',
  title: 'Downtown Players Update',
  message: 'New training session this Wednesday!',
  priority: 'high',
  category: 'community',
  data: {
    communityId: 'downtown_players_001',
    communityName: 'Downtown Players',
    action: 'open_community'
  }
});
```

### 2. Sending to Multiple Recipients

#### Send to all community members:
```javascript
async function sendCommunityNotification(communityId, notification) {
  // Get all community members
  const members = await admin.firestore()
    .collection('users')
    .where('communityId', '==', communityId)
    .get();

  const batch = admin.firestore().batch();
  
  members.docs.forEach(memberDoc => {
    const notificationRef = admin.firestore().collection('notifications').doc();
    batch.set(notificationRef, {
      ...notification,
      recipientId: memberDoc.id,
      recipientType: memberDoc.data().userType, // 'player' or 'fan'
      read: false,
      createdAt: new Date().toISOString()
    });
  });

  await batch.commit();
}
```

#### Send to all fans (encourage upgrade):
```javascript
async function sendToAllFans(notification) {
  const fans = await admin.firestore()
    .collection('users')
    .where('userType', '==', 'fan')
    .get();

  const batch = admin.firestore().batch();
  
  fans.docs.forEach(fanDoc => {
    const notificationRef = admin.firestore().collection('notifications').doc();
    batch.set(notificationRef, {
      ...notification,
      recipientId: fanDoc.id,
      recipientType: 'fan'
    });
  });

  await batch.commit();
}
```

### 3. Respecting User Preferences

Before sending, check user notification settings:
```javascript
async function canSendNotification(userId, category, priority) {
  const settingsDoc = await admin.firestore()
    .collection('notification_settings')
    .doc(userId)
    .get();

  if (!settingsDoc.exists) return true; // Default: allow all

  const settings = settingsDoc.data().settings;
  
  // Check if category is enabled
  if (!settings.categories[category]) return false;
  
  // Check if priority is enabled
  if (!settings.priorities[priority]) return false;
  
  // Check quiet hours
  if (settings.quietHours?.enabled) {
    const now = new Date();
    const currentTime = now.toTimeString().slice(0, 5); // HH:mm
    const start = settings.quietHours.startTime;
    const end = settings.quietHours.endTime;
    
    if (start > end) { // Crosses midnight
      if (currentTime >= start || currentTime <= end) return false;
    } else {
      if (currentTime >= start && currentTime <= end) return false;
    }
  }
  
  return true;
}
```

## Web App Integration Examples

### Community Leader Dashboard
```javascript
// Send community update
async function sendCommunityUpdate(communityId, title, message) {
  await sendCommunityNotification(communityId, {
    type: 'COMMUNITY_UPDATE',
    title: `${communityName} Update`,
    message: message,
    priority: 'high',
    category: 'community',
    data: {
      communityId: communityId,
      communityName: communityName,
      action: 'open_community'
    }
  });
}
```

### Tournament Management
```javascript
// Create new tournament notification
async function notifyNewTournament(tournament) {
  // Send to all players and fans
  await sendToMultipleRecipients(['player', 'fan'], {
    type: 'TOURNAMENT_NEW',
    title: `New Tournament: ${tournament.name}`,
    message: `Registration opens ${tournament.registrationDate}. Entry fee: KSh ${tournament.entryFee}`,
    priority: 'high',
    category: 'tournament',
    data: {
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      entryFee: tournament.entryFee,
      registrationDate: tournament.registrationDate,
      action: 'open_tournament'
    }
  });
}
```

### Payment Processing
```javascript
// Send payment success notification
async function notifyPaymentSuccess(userId, paymentData) {
  await sendNotification({
    recipientId: userId,
    recipientType: 'player', // or determine from user data
    type: 'PAYMENT_SUCCESS',
    title: 'Payment Successful',
    message: `Your payment of KSh ${paymentData.amount} has been processed successfully`,
    priority: 'high',
    category: 'payment',
    data: {
      paymentId: paymentData.id,
      amount: paymentData.amount,
      action: 'open_payment_history'
    }
  });
}
```

### Shop Order Updates
```javascript
// Send order status update
async function notifyOrderUpdate(userId, order) {
  await sendNotification({
    recipientId: userId,
    recipientType: 'user',
    type: 'SHOP_ORDER_UPDATE',
    title: 'Order Update',
    message: `Your order #${order.number} is now ${order.status}`,
    priority: 'medium',
    category: 'shop',
    data: {
      orderId: order.id,
      orderNumber: order.number,
      status: order.status,
      action: 'view_order'
    }
  });
}
```

## Best Practices

1. **Always include required fields**: recipientId, type, title, message, priority, category
2. **Use appropriate priority levels**: High for urgent notifications, medium for important updates
3. **Respect user preferences**: Check notification settings before sending
4. **Include relevant data**: Add context information in the data object
5. **Use consistent timestamps**: Always use ISO 8601 format
6. **Batch operations**: Use Firestore batch writes for multiple notifications
7. **Error handling**: Always wrap notification sends in try-catch blocks
8. **Rate limiting**: Avoid spamming users with too many notifications

## Testing

Run the setup script first:
```bash
dart run bin/create_notifications.dart
```

Then test sending notifications from your web app and verify they appear in the mobile app.

## Support

For questions about the notification system integration, check:
1. Firebase console for notification documents
2. Mobile app logs for notification handling
3. This documentation for correct data structures 