import 'package:flutter/foundation.dart';
import '../features/shop/domain/entities/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;
  double _totalPrice = 0.0;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  double get totalPrice => _totalPrice;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addItem(CartItem item) {
    final existingItemIndex = _items.indexWhere((i) => i.productId == item.productId);
    
    if (existingItemIndex >= 0) {
      final existingItem = _items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      _items[existingItemIndex] = updatedItem;
    } else {
      _items.add(item);
    }
    
    _calculateTotalPrice();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _calculateTotalPrice();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final itemIndex = _items.indexWhere((item) => item.productId == productId);
    if (itemIndex >= 0) {
      final currentItem = _items[itemIndex];
      final updatedItem = currentItem.copyWith(quantity: newQuantity);
      _items[itemIndex] = updatedItem;
      _calculateTotalPrice();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _totalPrice = 0;
    notifyListeners();
  }

  void _calculateTotalPrice() {
    _totalPrice = _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
} 