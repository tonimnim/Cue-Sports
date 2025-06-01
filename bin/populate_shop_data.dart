import 'package:firebase_core/firebase_core.dart';
import '../lib/utils/populate_shop_data.dart';
import '../lib/firebase/firebase_options.dart';

Future<void> main() async {
  print('Initializing Firebase...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Firebase initialized successfully!');
  print('Populating shop data...');
  
  // Add sample products
  await PopulateShopData.addSampleProducts();
  
  print('Done! You can now test the shop functionality.');
} 