import 'package:flutter/foundation.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;

  // Calculate total price of all items in cart
  double get totalPrice {
    return _items.fold(0, (total, item) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      return total + (product.price * quantity);
    });
  }
  
  // Get total number of items in cart
  int get itemCount {
    return _items.fold(0, (total, item) {
      return total + (item['quantity'] as int);
    });
  }

  // Load cart items (using local storage instead of Firebase)
  Future<void> loadCartItems() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // In a real app, we would load from local storage or a database
      // For now, we're just using an empty list
      // _items is already initialized as an empty list
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading cart items: $e');
    }
  }

  // Add product to cart
  Future<void> addToCart(Product product, [int quantity = 1]) async {
    try {
      // Check if the product is already in the cart
      final existingItemIndex = _items.indexWhere(
        (item) => (item['product'] as Product).id == product.id
      );
      
      if (existingItemIndex >= 0) {
        // Update quantity if the product is already in the cart
        _items[existingItemIndex]['quantity'] = _items[existingItemIndex]['quantity'] + quantity;
      } else {
        // Add new product to cart
        _items.add({
          'product': product,
          'quantity': quantity,
        });
      }
      
      notifyListeners();
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      _items.removeWhere((item) => (item['product'] as Product).id == productId);
      notifyListeners();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        await removeFromCart(productId);
      } else {
        // Find the item and update its quantity
        final index = _items.indexWhere(
          (item) => (item['product'] as Product).id == productId
        );
        
        if (index >= 0) {
          _items[index]['quantity'] = quantity;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
      rethrow;
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      _items = [];
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}
