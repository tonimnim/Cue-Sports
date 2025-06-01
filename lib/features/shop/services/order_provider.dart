import 'package:flutter/foundation.dart';
import 'package:pool_billiard_app/features/shop/models/order.dart' as shop;
import 'package:pool_billiard_app/firebase/firebase_services.dart';

class OrderProvider with ChangeNotifier {
  // Use the Firebase service for data access
  final FirebaseServices _firebaseServices = FirebaseServices();
  
  // Use hardcoded user_id1 to match Firestore test data
  final String _userId = 'user_id1';
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load orders for the current user
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('[OrderProvider] Loading orders from Firestore for user: $_userId');
      
      // Get orders from Firebase
      final ordersSnapshot = await _firebaseServices.ordersCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('[OrderProvider] Fetched ${ordersSnapshot.docs.length} orders from Firestore');
      
      // Convert order documents to Maps for the UI
      _orders = ordersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Create a map with all the order data
        return {
          'id': doc.id,
          'orderNumber': data['orderNumber'] ?? '',
          'status': data['status'] ?? 'pending',
          'total': (data['total'] ?? 0).toDouble(),
          'paymentMethod': data['paymentMethod'] ?? '',
          'shippingAddress': data['shippingAddress'] ?? '',
          'notes': data['notes'] ?? '',
          'receiptNumber': data['receiptNumber'] ?? '',
          'createdAt': data['createdAt'] ?? DateTime.now(),
          // Use the items directly from the order if available
          'items': data['items'] ?? [],
        };
      }).toList();
      
      print('[OrderProvider] Converted ${_orders.length} orders for UI display');
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('[OrderProvider] ERROR in loadOrders: $e');
      print('[OrderProvider] Stack trace: $stackTrace');
      _error = 'Failed to load orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  // We now use real data from Firestore instead of sample data
  
  // Create a new order from cart items
  Future<bool> createOrder({
    required String cartId,
    required List<Map<String, dynamic>> items,
    required double total,
    required String address,
    required String paymentMethod,
    String? notes,
    String? receiptNumber,
    String status = 'Processing',
  }) async {
    try {
      print('[OrderProvider] createOrder starting with status: $status');
      // Format cart item IDs 
      final cartItemIds = items.map((item) => item['id'].toString()).toList();
      
      // Create order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
      
      print('[OrderProvider] Created order number: $orderNumber');
      
      // Create shop order data
      final orderData = {
        'userId': _userId,
        'orderNumber': orderNumber,
        'status': status,
        'total': total,
        'paymentMethod': paymentMethod,
        'shippingAddress': address,
        'notes': notes,
        'receiptNumber': receiptNumber,
        'itemIds': cartItemIds,
        'items': items, // Include actual item data directly in the order
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      
      print('[OrderProvider] Created shop order data with userId: $_userId');
      print('[OrderProvider] About to call Firebase to create new order...');
      
      // Add order to Firebase
      final docRef = await _firebaseServices.ordersCollection.add(orderData);
      
      print('[OrderProvider] Firebase returned orderId: ${docRef.id}');
      
      // Reload orders list
      await loadOrders();
      
      print('[OrderProvider] Order creation successful');
      return true;
    } catch (e, stackTrace) {
      print('[OrderProvider] ERROR in createOrder: $e');
      print('[OrderProvider] Stack trace: $stackTrace');
      _error = 'Failed to create order: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firebaseServices.ordersCollection.doc(orderId).update({
        'status': status,
        'updatedAt': DateTime.now(),
      });
      
      // Update local order status
      final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
      if (orderIndex >= 0) {
        _orders[orderIndex]['status'] = status;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to update order status: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Create an order from cart items
  Future<bool> createOrderFromCart({
    required List<Map<String, dynamic>> cartItems,
    required String status,
    required String paymentMethod,
    String? receiptNumber,
    String? notes,
  }) async {
    try {
      print('[OrderProvider] Starting createOrderFromCart...');
      print('[OrderProvider] Cart items count: ${cartItems.length}');
      print('[OrderProvider] Status: $status, Payment method: $paymentMethod');
      
      if (cartItems.isEmpty) {
        print('[OrderProvider] Error: Cart is empty, cannot create order');
        return false; // Can't create an order with no items
      }
      
      // Calculate total from cart items
      final total = cartItems.fold<double>(0, (sum, item) {
        final product = item['product'];
        final quantity = item['quantity'] as int;
        return sum + (product.price * quantity);
      });
      
      print('[OrderProvider] Calculated total: $total');
      
      // Format cart items for the order
      final items = cartItems.map((item) {
        final product = item['product'];
        final quantity = item['quantity'] as int;
        return {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': quantity,
          'imageUrl': product.imageUrl,
        };
      }).toList();
      
      print('[OrderProvider] Formatted ${items.length} items for order');
      
      // Create order
      final orderNotes = notes;
      
      print('[OrderProvider] Order notes: $orderNotes');
      print('[OrderProvider] Receipt number: $receiptNumber');
      print('[OrderProvider] Calling createOrder...');
          
      final result = await createOrder(
        cartId: DateTime.now().millisecondsSinceEpoch.toString(),
        items: items,
        total: total,
        address: 'Default Address', // In a real app, get from user profile
        paymentMethod: paymentMethod,
        notes: orderNotes,
        receiptNumber: receiptNumber, // Pass receipt number directly
        status: status, // Pass the status to createOrder
      );
      
      print('[OrderProvider] createOrder result: $result');
      return result;
    } catch (e, stackTrace) {
      print('[OrderProvider] ERROR in createOrderFromCart: $e');
      print('[OrderProvider] Stack trace: $stackTrace');
      _error = 'Failed to create order from cart: $e';
      notifyListeners();
      return false;
    }
  }
}
