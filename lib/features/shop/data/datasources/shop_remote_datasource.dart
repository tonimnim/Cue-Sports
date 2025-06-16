import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../../firebase/firebase_services.dart';
import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/shop_order_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/shop_order.dart';

abstract class ShopRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> getFeaturedProducts();
  Future<List<ProductModel>> getPopularProducts();
  Future<List<ProductModel>> getNewArrivals();
  Future<ProductModel?> getProductById(String id);
  Future<void> updateProduct(ProductModel product);

  Future<List<CartItemModel>> getCartItems(String userId);
  Future<void> addToCart(CartItemModel cartItem);
  Future<void> updateCartItem(CartItemModel cartItem);
  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> clearCart(String userId);

  Future<List<ShopOrderModel>> getUserOrders(String userId);
  Future<ShopOrderModel?> getOrderById(String orderId);
  Future<String> createOrder(ShopOrderModel order);
  Future<void> updateOrder(ShopOrderModel order);
}

class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  final FirebaseServices _firebaseServices;
  final Logger _logger = Logger();

  ShopRemoteDataSourceImpl(this._firebaseServices);

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firebaseServices.productsCollection.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firebaseServices.productsCollection
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get products by category: $e');
    }
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot = await _firebaseServices.productsCollection
          .where('isFeatured', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get featured products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getPopularProducts() async {
    try {
      final snapshot = await _firebaseServices.productsCollection
          .where('isPopular', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get popular products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getNewArrivals() async {
    try {
      final snapshot = await _firebaseServices.productsCollection
          .where('isNewArrival', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get new arrivals: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _firebaseServices.productsCollection.doc(id).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to get product by id: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firebaseServices.productsCollection
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e) {
      throw ServerException('Failed to update product: $e');
    }
  }

  @override
  Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      _logger.i('Getting cart items for user: $userId');
      final snapshot = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get();

      _logger.i('Found ${snapshot.docs.length} cart items in Firestore for user: $userId');
      final List<CartItemModel> cartItems = [];

      for (final doc in snapshot.docs) {
        final item = CartItemModel.fromFirestore(doc);
        _logger.d('Cart item from Firestore: ID=${doc.id}, ProductID=${item.productId}, Name=${item.name}, Quantity=${item.quantity}');
        cartItems.add(item);
      }

      _logger.i('Successfully retrieved ${cartItems.length} cart items for user: $userId');
      return cartItems;
    } catch (e) {
      _logger.e('Failed to get cart items for user: $userId, error: $e');
      throw ServerException('Failed to get cart items: $e');
    }
  }

  @override
  Future<void> addToCart(CartItemModel cartItem) async {
    try {
      // Get current user ID from Firebase Auth
      final userId = _firebaseServices.auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw ServerException('User not authenticated');
      }

      // Check if item already exists in cart
      final existingItems = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: cartItem.productId)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // Update existing item quantity
        final existingItem = existingItems.docs.first;
        final existingData = existingItem.data();
        final existingQuantity = existingData['quantity'] as int? ?? 0;
        
        await _firebaseServices.cartsCollection
            .doc(userId)
            .collection('items')
            .doc(existingItem.id)
            .update({
          'quantity': existingQuantity + cartItem.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await _firebaseServices.cartsCollection
            .doc(userId)
            .collection('items')
            .add(cartItem.toFirestore());
      }

      final userIdForLog = userId; // Store in local variable for logging
      _logger.i('Successfully added item to cart for user: $userIdForLog, ProductID=${cartItem.productId}, Quantity=${cartItem.quantity}');
    } catch (e) {
      final userIdForLog = _firebaseServices.auth.currentUser?.uid ?? 'unknown';
      _logger.e('Failed to add item to cart for user: $userIdForLog, ProductID=${cartItem.productId}, Quantity=${cartItem.quantity}, error: $e');
      throw ServerException('Failed to add to cart: $e');
    }
  }

  @override
  Future<void> updateCartItem(CartItemModel cartItem) async {
    try {
      // Get current user ID from Firebase Auth
      final userId = _firebaseServices.auth.currentUser?.uid ?? '';

      await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .doc(cartItem.id)
          .update(cartItem.toFirestore());
    } catch (e) {
      throw ServerException('Failed to update cart item: $e');
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .doc(cartItemId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to remove from cart: $e');
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      _logger.i('Clearing cart for user: $userId');
      final batch = _firebaseServices.firestore.batch();
      final cartItems = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .get();

      _logger.i('Found ${cartItems.docs.length} items to clear from cart for user: $userId');
      
      for (final doc in cartItems.docs) {
        _logger.d('Deleting cart item: ${doc.id} for user: $userId');
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.i('Successfully cleared ${cartItems.docs.length} items from cart for user: $userId');
    } catch (e) {
      _logger.e('Failed to clear cart for user: $userId, error: $e');
      throw ServerException('Failed to clear cart: $e');
    }
  }

  @override
  Future<List<ShopOrderModel>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firebaseServices.ordersCollection
          .where('userId', isEqualTo: userId)
          .get();

      final List<ShopOrderModel> orders = [];

      for (final doc in snapshot.docs) {
        orders.add(ShopOrderModel.fromFirestore(doc));
      }

      return orders;
    } catch (e) {
      throw ServerException('Failed to get user orders: $e');
    }
  }

  @override
  Future<ShopOrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firebaseServices.ordersCollection.doc(orderId).get();
      if (!doc.exists) return null;

      return ShopOrderModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to get order by id: $e');
    }
  }

  @override
  Future<String> createOrder(ShopOrderModel order) async {
    try {
      // Check if an order with the same ID already exists to prevent duplicates
      if (order.id.isNotEmpty) {
        final existingOrder = await _firebaseServices.ordersCollection.doc(order.id).get();
        if (existingOrder.exists) {
          _logger.w('Order with ID ${order.id} already exists. Returning existing ID.');
          return order.id;
        }
      }
      
      // Use a transaction for atomicity
      String orderId = '';
      await _firebaseServices.firestore.runTransaction((transaction) async {
        // Create a document reference with the provided ID or generate a new one
        final docRef = order.id.isNotEmpty
            ? _firebaseServices.ordersCollection.doc(order.id)
            : _firebaseServices.ordersCollection.doc();
        
        // Set the order data in the transaction
        transaction.set(docRef, order.toFirestore());
        
        // Store the document ID for return
        orderId = docRef.id;
      });
      
      _logger.i('Successfully created order with ID: $orderId');
      return orderId;
    } catch (e) {
      _logger.e('Failed to create order: $e');
      throw ServerException('Failed to create order: $e');
    }
  }

  @override
  Future<void> updateOrder(ShopOrderModel order) async {
    try {
      await _firebaseServices.ordersCollection
          .doc(order.id)
          .update(order.toFirestore());
    } catch (e) {
      throw ServerException('Failed to update order: $e');
    }
  }
}
