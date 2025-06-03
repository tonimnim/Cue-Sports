// Node.js script to write sample data to Firebase
// First, install required packages:
// npm install firebase-admin

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to download a service account key from Firebase Console:
// 1. Go to Firebase Console > Project Settings > Service Accounts
// 2. Click "Generate New Private Key"
// 3. Save the JSON file and update the path below

// Uncomment and update the path to your service account key
/*
const serviceAccount = require('./path-to-your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'poolbilliard-167ad'
});
*/

// For now, let's create a script that generates the data structure
// You can run this with Firebase Admin SDK once you have the service account key

const db = admin.firestore();

// Sample data
const tournaments = [
  {
    id: 'tournament1',
    name: 'Summer Championship 2024',
    organizerId: 'community1',
    startDate: new Date('2024-06-01'),
    endDate: new Date('2024-06-15'),
    status: 'in_progress',
    description: 'Annual summer pool championship',
    maxParticipants: 32,
    currentParticipants: 16,
    entryFee: 50.0,
    prizePool: 1600.0,
    venue: 'Main Sports Center',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'tournament2',
    name: 'Winter League 2024',
    organizerId: 'community2',
    startDate: new Date('2024-12-01'),
    endDate: new Date('2024-12-20'),
    status: 'upcoming',
    description: 'Winter league tournament',
    maxParticipants: 24,
    currentParticipants: 8,
    entryFee: 30.0,
    prizePool: 720.0,
    venue: 'Winter Arena',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'tournament3',
    name: 'Spring Open 2024',
    organizerId: 'community1',
    startDate: new Date('2024-03-01'),
    endDate: new Date('2024-03-10'),
    status: 'completed',
    description: 'Spring open championship',
    maxParticipants: 16,
    currentParticipants: 16,
    entryFee: 40.0,
    prizePool: 640.0,
    venue: 'Spring Arena',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

const matches = [
  // Player1's matches across different tournaments
  {
    id: 'match1',
    tournamentId: 'tournament1',
    round: 1,
    matchNumber: 1,
    player1Id: 'player1',
    player2Id: 'player2',
    status: 'completed',
    score: { player1: 5, player2: 3 },
    winnerId: 'player1',
    scheduledTime: new Date('2024-06-01T14:00:00'),
    startTime: new Date('2024-06-01T14:05:00'),
    endTime: new Date('2024-06-01T15:30:00'),
    venue: 'Main Hall',
    refereeId: 'referee1',
    organizerId: 'community1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'match2',
    tournamentId: 'tournament2',
    round: 1,
    matchNumber: 1,
    player1Id: 'player1',
    player2Id: 'player3',
    status: 'scheduled',
    scheduledTime: new Date('2024-12-01T10:00:00'),
    venue: 'Winter Arena',
    refereeId: 'referee2',
    organizerId: 'community2',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'match3',
    tournamentId: 'tournament1',
    round: 2,
    matchNumber: 1,
    player1Id: 'player1',
    player2Id: 'player4',
    status: 'completed',
    score: { player1: 5, player2: 2 },
    winnerId: 'player1',
    scheduledTime: new Date('2024-06-03T14:00:00'),
    startTime: new Date('2024-06-03T14:00:00'),
    endTime: new Date('2024-06-03T15:00:00'),
    venue: 'Main Hall',
    refereeId: 'referee1',
    organizerId: 'community1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'match4',
    tournamentId: 'tournament1',
    round: 3,
    matchNumber: 1,
    player1Id: 'player1',
    player2Id: 'player5',
    status: 'completed',
    score: { player1: 5, player2: 4 },
    winnerId: 'player1',
    scheduledTime: new Date('2024-06-05T14:00:00'),
    startTime: new Date('2024-06-05T14:00:00'),
    endTime: new Date('2024-06-05T15:45:00'),
    venue: 'Main Hall',
    refereeId: 'referee1',
    organizerId: 'community1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'match5',
    tournamentId: 'tournament1',
    round: 4,
    matchNumber: 1,
    player1Id: 'player1',
    player2Id: 'player6',
    status: 'in_progress',
    scheduledTime: new Date('2024-06-07T14:00:00'),
    startTime: new Date('2024-06-07T14:00:00'),
    venue: 'Main Hall',
    refereeId: 'referee1',
    organizerId: 'community1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  // Other matches for different scenarios
  {
    id: 'match6',
    tournamentId: 'tournament3',
    round: 1,
    matchNumber: 1,
    player1Id: 'player7',
    player2Id: 'player8',
    status: 'completed',
    score: { player1: 5, player2: 3 },
    winnerId: 'player7',
    scheduledTime: new Date('2024-03-01T10:00:00'),
    startTime: new Date('2024-03-01T10:00:00'),
    endTime: new Date('2024-03-01T11:30:00'),
    venue: 'Spring Arena',
    refereeId: 'referee3',
    organizerId: 'community1',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function writeSampleData() {
  try {
    console.log('🔥 Writing sample data to Firebase...');
    
    // Write tournaments
    console.log('\n📋 Writing tournaments...');
    const tournamentBatch = db.batch();
    
    for (const tournament of tournaments) {
      const docRef = db.collection('tournaments').doc(tournament.id);
      tournamentBatch.set(docRef, tournament);
      console.log(`  ✅ Queued tournament: ${tournament.name}`);
    }
    
    await tournamentBatch.commit();
    console.log('🎉 All tournaments written successfully!');
    
    // Write matches
    console.log('\n🏓 Writing matches...');
    const matchBatch = db.batch();
    
    for (const match of matches) {
      const docRef = db.collection('matches').doc(match.id);
      matchBatch.set(docRef, match);
      console.log(`  ✅ Queued match: ${match.id} (${match.status})`);
    }
    
    await matchBatch.commit();
    console.log('🎉 All matches written successfully!');
    
    // Run some test queries
    console.log('\n🔍 Running test queries...');
    
    // Get player1's matches
    const player1Matches = await db.collection('matches')
      .where('player1Id', '==', 'player1')
      .get();
    console.log(`  Player1 matches found: ${player1Matches.size}`);
    
    // Get tournament1 matches
    const tournament1Matches = await db.collection('matches')
      .where('tournamentId', '==', 'tournament1')
      .get();
    console.log(`  Tournament1 matches found: ${tournament1Matches.size}`);
    
    // Get completed matches
    const completedMatches = await db.collection('matches')
      .where('status', '==', 'completed')
      .get();
    console.log(`  Completed matches found: ${completedMatches.size}`);
    
    console.log('\n✨ All done! Check your Firebase console to see the data.');
    
  } catch (error) {
    console.error('❌ Error writing data:', error);
  }
}

// Uncomment this line to run the function when you have configured the Admin SDK
// writeSampleData();

console.log(`
📝 To use this script:

1. Install Firebase Admin SDK:
   npm install firebase-admin

2. Get your service account key:
   - Go to Firebase Console: https://console.firebase.google.com/
   - Select your project (poolbilliard-167ad)
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file

3. Update this script:
   - Uncomment the admin.initializeApp() section
   - Update the path to your service account key
   - Uncomment the writeSampleData() call at the bottom

4. Run the script:
   node write_firebase_data.js
`); 