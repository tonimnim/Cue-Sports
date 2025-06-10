import 'package:cloud_firestore/cloud_firestore.dart';
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
      final snapshot = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get();

      final List<CartItemModel> cartItems = [];

      for (final doc in snapshot.docs) {
        cartItems.add(CartItemModel.fromFirestore(doc));
      }

      return cartItems;
    } catch (e) {
      throw ServerException('Failed to get cart items: $e');
    }
  }

  @override
  Future<void> addToCart(CartItemModel cartItem) async {
    try {
      // Use consistent user ID approach - for MVP we'll use 'current_user'
      // In production, this would use proper user authentication
      final userId = 'current_user';

      // Check if item already exists in cart
      final existingItems = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: cartItem.productId)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // Update existing item quantity
        final existingDoc = existingItems.docs.first;
        final existingData = existingDoc.data();
        final newQuantity = (existingData['quantity'] ?? 0) + cartItem.quantity;

        await existingDoc.reference.update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await _firebaseServices.cartsCollection
            .doc(userId)
            .collection('items')
            .add(cartItem.toFirestore());
      }
    } catch (e) {
      throw ServerException('Failed to add to cart: $e');
    }
  }

  @override
  Future<void> updateCartItem(CartItemModel cartItem) async {
    try {
      // Use consistent user ID approach - for MVP we'll use 'current_user'
      final userId = 'current_user';

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
      final batch = _firebaseServices.firestore.batch();
      final cartItems = await _firebaseServices.cartsCollection
          .doc(userId)
          .collection('items')
          .get();

      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
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
      final docRef =
          await _firebaseServices.ordersCollection.add(order.toFirestore());
      return docRef.id;
    } catch (e) {
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
