import 'package:flutter/foundation.dart';
import '../features/shop/domain/entities/shop_order.dart';

class OrderProvider with ChangeNotifier {
  final List<ShopOrder> _orders = [];
  bool _isLoading = false;

  List<ShopOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addOrder(ShopOrder order) {
    _orders.insert(0, order); // Add new order at the beginning of the list
    notifyListeners();
  }

  void setOrders(List<ShopOrder> orders) {
    _orders.clear();
    _orders.addAll(orders);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex >= 0) {
      final currentOrder = _orders[orderIndex];
      final updatedOrder = currentOrder.copyWith(
        status: OrderStatus.values.firstWhere(
          (s) => s.toString().split('.').last == newStatus.toLowerCase(),
          orElse: () => OrderStatus.processing
        )
      );
      _orders[orderIndex] = updatedOrder;
      notifyListeners();
    }
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
} 