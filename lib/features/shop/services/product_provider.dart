import 'package:flutter/foundation.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';
import 'package:pool_billiard_app/firebase/firebase_services.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _popularProducts = [];
  List<Product> _newArrivals = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Product> get allProducts => _allProducts;
  List<Product> get popularProducts => _popularProducts;
  List<Product> get newArrivals => _newArrivals;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String get error => _error;

  final FirebaseServices _firebaseServices = FirebaseServices();

  // Initialize and load products
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get all products from Firebase
      final allProductsSnapshot = await _firebaseServices.productsCollection.get();
      _allProducts = allProductsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Get popular products
      final popularSnapshot = await _firebaseServices.productsCollection
          .where('isPopular', isEqualTo: true)
          .get();
      _popularProducts = popularSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Get new arrivals
      final newArrivalsSnapshot = await _firebaseServices.productsCollection
          .where('isNewArrival', isEqualTo: true)
          .get();
      _newArrivals = newArrivalsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

      // Featured products - highest-rated products
      _featuredProducts = _allProducts
          .where((product) => product.rating >= 4.5)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      if (_featuredProducts.length > 5) {
        _featuredProducts = _featuredProducts.sublist(0, 5);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') {
      return _allProducts;
    }
    return _allProducts.where((product) => product.category == category).toList();
  }

  // Get popular products by category
  List<Product> getPopularProductsByCategory(String category) {
    if (category == 'All') {
      return _popularProducts;
    }
    return _popularProducts.where((product) => product.category == category).toList();
  }

  // Get new arrivals by category
  List<Product> getNewArrivalsByCategory(String category) {
    if (category == 'All') {
      return _newArrivals;
    }
    return _newArrivals.where((product) => product.category == category).toList();
  }

  // Get featured products by category
  List<Product> getFeaturedProductsByCategory(String category) {
    if (category == 'All') {
      return _featuredProducts;
    }
    return _featuredProducts.where((product) => product.category == category).toList();
  }
}