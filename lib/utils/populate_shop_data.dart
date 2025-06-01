import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_services.dart';

class PopulateShopData {
  static Future<void> addSampleProducts() async {
    final FirebaseServices firebaseServices = FirebaseServices();
    
    // Sample products data
    final products = [
      {
        'name': 'Professional Pool Cue',
        'category': 'Pool Cues',
        'price': 149.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Pool+Cue',
        'isPopular': true,
        'isNewArrival': false,
        'isFeatured': true,
        'totalPurchases': 45,
        'description': 'High-quality professional pool cue made from premium maple wood. Perfect weight and balance for serious players.',
        'rating': 4.5,
        'isAvailable': true,
        'stockQuantity': 20,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Aramith Pool Ball Set',
        'category': 'Balls',
        'price': 89.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Pool+Balls',
        'isPopular': true,
        'isNewArrival': false,
        'isFeatured': false,
        'totalPurchases': 78,
        'description': 'Official Aramith pool ball set. Tournament quality balls with superior durability.',
        'rating': 4.8,
        'isAvailable': true,
        'stockQuantity': 15,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Premium Pool Table',
        'category': 'Tables',
        'price': 2499.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Pool+Table',
        'isPopular': false,
        'isNewArrival': true,
        'isFeatured': true,
        'totalPurchases': 5,
        'description': 'Professional 9-foot pool table with slate bed and premium felt. Perfect for tournaments.',
        'rating': 4.9,
        'isAvailable': true,
        'stockQuantity': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Chalk Pack (12 pieces)',
        'category': 'Accessories',
        'price': 12.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Chalk',
        'isPopular': false,
        'isNewArrival': true,
        'isFeatured': false,
        'totalPurchases': 125,
        'description': 'High-quality pool chalk for better cue tip grip. Pack of 12 pieces.',
        'rating': 4.2,
        'isAvailable': true,
        'stockQuantity': 50,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Cue Tip Replacement Kit',
        'category': 'Accessories',
        'price': 24.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Cue+Tips',
        'isPopular': true,
        'isNewArrival': false,
        'isFeatured': false,
        'totalPurchases': 32,
        'description': 'Complete cue tip replacement kit with adhesive and shaper tool.',
        'rating': 4.3,
        'isAvailable': true,
        'stockQuantity': 25,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Wooden Cue Rack',
        'category': 'Accessories',
        'price': 79.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Cue+Rack',
        'isPopular': false,
        'isNewArrival': false,
        'isFeatured': false,
        'totalPurchases': 18,
        'description': 'Elegant wooden wall-mounted cue rack. Holds up to 8 pool cues.',
        'rating': 4.1,
        'isAvailable': true,
        'stockQuantity': 12,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Tournament Quality Pool Balls',
        'category': 'Balls',
        'price': 129.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Tournament+Balls',
        'isPopular': false,
        'isNewArrival': true,
        'isFeatured': true,
        'totalPurchases': 8,
        'description': 'Official tournament pool balls used in professional competitions.',
        'rating': 5.0,
        'isAvailable': true,
        'stockQuantity': 8,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Beginner Pool Cue',
        'category': 'Pool Cues',
        'price': 49.99,
        'imageUrl': 'https://via.placeholder.com/300x300?text=Beginner+Cue',
        'isPopular': true,
        'isNewArrival': false,
        'isFeatured': false,
        'totalPurchases': 95,
        'description': 'Perfect starter cue for beginners. Good quality at an affordable price.',
        'rating': 4.0,
        'isAvailable': true,
        'stockQuantity': 30,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      print('Starting to add sample products...');
      
      for (int i = 0; i < products.length; i++) {
        await firebaseServices.productsCollection.add(products[i]);
        print('Added product ${i + 1}/${products.length}: ${products[i]['name']}');
      }
      
      print('Successfully added ${products.length} sample products to Firebase!');
    } catch (e) {
      print('Error adding sample products: $e');
    }
  }

  static Future<void> clearAllProducts() async {
    final FirebaseServices firebaseServices = FirebaseServices();
    
    try {
      print('Clearing all products...');
      final snapshot = await firebaseServices.productsCollection.get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('Successfully cleared ${snapshot.docs.length} products from Firebase!');
    } catch (e) {
      print('Error clearing products: $e');
    }
  }
} 