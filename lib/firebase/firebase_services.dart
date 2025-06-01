import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/firebase_options.dart';

class FirebaseServices {
  // Singleton pattern
  static final FirebaseServices _instance = FirebaseServices._internal();

  factory FirebaseServices() {
    return _instance;
  }

  FirebaseServices._internal();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Collection references for Firestore
  CollectionReference get usersCollection => firestore.collection('users');

  CollectionReference get playerProfilesCollection =>
      firestore.collection('playerProfiles');

  CollectionReference get paymentsCollection =>
      firestore.collection('payments');

  // Shop collections
  CollectionReference get productsCollection => firestore.collection('products');
  CollectionReference get ordersCollection => firestore.collection('orders');
  CollectionReference get cartsCollection => firestore.collection('carts');

  // Tournament collections
  CollectionReference get tournamentsCollection => firestore.collection('tournaments');
  CollectionReference get tournamentRegistrationsCollection => 
      firestore.collection('tournamentRegistrations');

  // Helper methods for Firestore operations
  Future<DocumentSnapshot> getUserDoc(String userId) async {
    return await usersCollection.doc(userId).get();
  }

  Future<DocumentSnapshot> getPlayerProfileDoc(String userId) async {
    return await playerProfilesCollection.doc(userId).get();
  }

  Future<void> createUserDoc(String userId, Map<String, dynamic> data) async {
    await usersCollection.doc(userId).set(data);
  }

  Future<void> updateUserDoc(String userId, Map<String, dynamic> data) async {
    await usersCollection.doc(userId).update(data);
  }

  Future<void> createPlayerProfileDoc(
      String userId, Map<String, dynamic> data) async {
    await playerProfilesCollection.doc(userId).set(data);
  }

  Future<void> updatePlayerProfileDoc(
      String userId, Map<String, dynamic> data) async {
    await playerProfilesCollection.doc(userId).update(data);
  }

  Future<QuerySnapshot> getUserByPhoneNumber(String phoneNumber) async {
    return await usersCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
  }

  Future<QuerySnapshot> getUserByEmail(String email) async {
    return await usersCollection
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
  }

  // Authentication helpers
  User? get currentUser => auth.currentUser;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<void> signOut() async {
    await auth.signOut();
  }
}
