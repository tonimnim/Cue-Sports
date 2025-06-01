import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';
import 'package:pool_billiard_app/firebase/firebase_services.dart';
import 'dart:convert';
import 'dart:io';

/// A utility class to retrieve and manage product data from Firebase
class ProductDatastore {
  static List<Product> allProducts = [];
  static List<Product> featuredProducts = [];
  static List<Product> popularProducts = [];
  static List<Product> newArrivals = [];
  static Map<String, List<Product>> productsByCategory = {};
  static bool _isInitialized = false;
  
  /// Get products by category
  static List<Product> getProductsByCategory(String category) {
    return productsByCategory[category] ?? [];
  }
  
  /// Get top products by purchases
  static List<Product> getTopProductsByPurchases(int limit) {
    final sorted = List<Product>.from(allProducts)
      ..sort((a, b) => b.totalPurchases.compareTo(a.totalPurchases));
    return sorted.take(limit).toList();
  }
  
  /// Check if the datastore is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Initialize the datastore - must be called before using other methods
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ProductDatastore already initialized');
      return;
    }
    
    try {
      final firebaseServices = FirebaseServices();
      
      // Load all products
      final allProductsSnapshot = await firebaseServices.productsCollection.get();
      allProducts = allProductsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Load featured products
      final featuredSnapshot = await firebaseServices.productsCollection
          .where('isFeatured', isEqualTo: true)
          .get();
      featuredProducts = featuredSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Load popular products
      final popularSnapshot = await firebaseServices.productsCollection
          .where('isPopular', isEqualTo: true)
          .get();
      popularProducts = popularSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Load new arrivals
      final newArrivalsSnapshot = await firebaseServices.productsCollection
          .where('isNewArrival', isEqualTo: true)
          .get();
      newArrivals = newArrivalsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
      
      // Group products by category
      productsByCategory = {};
      for (final product in allProducts) {
        if (!productsByCategory.containsKey(product.category)) {
          productsByCategory[product.category] = [];
        }
        productsByCategory[product.category]!.add(product);
      }
      
      _isInitialized = true;
      debugPrint('ProductDatastore initialized with ${allProducts.length} products');
      
      // Export products data to JSON for reference in debug mode
      if (kDebugMode && allProducts.isNotEmpty) {
        try {
          final file = File('products_data.json');
          final jsonData = jsonEncode(allProducts.map((p) => p.toMap()).toList());
          await file.writeAsString(jsonData);
          debugPrint('Products data exported to products_data.json');
        } catch (e) {
          debugPrint('Error exporting products data to JSON: $e');
        }
      }
      
      return Future.value();
    } catch (e) {
      debugPrint('Error initializing ProductDatastore: $e');
      return Future.error(e);
    }
  }
  
  /// Print a summary of all products in the datastore (for debugging)
  static void printSummary() {
    debugPrint('=== ProductDatastore Summary ===');
    debugPrint('Total products: ${allProducts.length}');
    debugPrint('Featured products: ${featuredProducts.length}');
    debugPrint('Popular products: ${popularProducts.length}');
    debugPrint('New arrivals: ${newArrivals.length}');
    debugPrint('Categories: ${productsByCategory.keys.join(', ')}');
    
    for (final category in productsByCategory.keys) {
      debugPrint('$category: ${productsByCategory[category]!.length} products');
    }
    debugPrint('===============================');
  }
}
