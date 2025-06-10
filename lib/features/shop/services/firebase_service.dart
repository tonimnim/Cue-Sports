import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';
import 'package:pool_billiard_app/features/shop/models/category.dart';
import 'package:pool_billiard_app/features/shop/models/cart_item.dart';
import 'package:pool_billiard_app/features/shop/models/order.dart';
import 'package:pool_billiard_app/core/services/logger_service.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;

class FirebaseService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final LoggerService _logger = di.sl<LoggerService>();

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // User ID from authentication
  String? get userId => 'user001';

  // PRODUCTS

  // Add a product
  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).set({
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'rating': product.rating,
        'isPopular': product.isPopular,
        'isNewArrival': product.isNewArrival,
        'isFeatured': product.isFeatured,
        'totalPurchases': product.totalPurchases,
      });
    } catch (e) {
      _logger.e('Error adding product: $e');
      throw Exception('Failed to add product');
    }
  }

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final firestore.QuerySnapshot snapshot =
          await _firestore.collection('products').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting products: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting products by category: $e');
      return [];
    }
  }

  // Get popular products
  Future<List<Product>> getPopularProducts() async {
    try {
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('isPopular', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting popular products: $e');
      return [];
    }
  }

  // Get new arrivals
  Future<List<Product>> getNewArrivals() async {
    try {
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('isNewArrival', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting new arrivals: $e');
      return [];
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting featured products: $e');
      return [];
    }
  }

  // CATEGORIES

  // Add a category
  Future<void> addCategory(ProductCategory category) async {
    try {
      await _firestore.collection('categories').doc(category.id).set({
        'name': category.name,
      });
    } catch (e) {
      _logger.e('Error adding category: $e');
      throw Exception('Failed to add category');
    }
  }

  // Get all categories
  Future<List<ProductCategory>> getCategories() async {
    try {
      final firestore.QuerySnapshot snapshot =
          await _firestore.collection('categories').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductCategory(
          id: doc.id,
          name: data['name'] ?? '',
        );
      }).toList();
    } catch (e) {
      _logger.e('Error getting categories: $e');
      return [];
    }
  }

  // Get category by ID
  Future<ProductCategory?> getCategoryById(String categoryId) async {
    try {
      final firestore.DocumentSnapshot doc =
          await _firestore.collection('categories').doc(categoryId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return ProductCategory(
        id: doc.id,
        name: data['name'] ?? '',
      );
    } catch (e) {
      _logger.e('Error getting category by ID: $e');
      return null;
    }
  }

  // Update category
  Future<void> updateCategory(ProductCategory category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update({
        'name': category.name,
      });
    } catch (e) {
      _logger.e('Error updating category: $e');
      throw Exception('Failed to update category');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      _logger.e('Error deleting category: $e');
      throw Exception('Failed to delete category');
    }
  }

  // Get products by category ID
  Future<List<Product>> getProductsByCategoryId(String categoryId) async {
    try {
      // First get the category name
      final category = await getCategoryById(categoryId);
      if (category == null) {
        return [];
      }

      // Then get products with that category name
      return await getProductsByCategory(category.name);
    } catch (e) {
      _logger.e('Error getting products by category ID: $e');
      return [];
    }
  }

  // CART

  // Add product to cart
  Future<void> addToCart(String productId, int quantity) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check if product exists
      final firestore.DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      // Check if item is already in cart
      final firestore.QuerySnapshot cartItemSnapshot = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: productId)
          .get();

      if (cartItemSnapshot.docs.isNotEmpty) {
        // Update quantity if already in cart
        final String cartItemId = cartItemSnapshot.docs.first.id;
        final int currentQuantity =
            cartItemSnapshot.docs.first['quantity'] as int;

        await _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(cartItemId)
            .update({
          'quantity': currentQuantity + quantity,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .add({
          'productId': productId,
          'quantity': quantity,
          'addedAt': firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.e('Error adding to cart: $e');
      throw Exception('Failed to add to cart');
    }
  }

  // Add cart item (full object)
  Future<String> addCartItem(CartItemModel cartItem, String userId) async {
    try {
      // Check if product exists
      final firestore.DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(cartItem.productId).get();

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      // Create cart item in Firestore
      final docRef = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .add(cartItem.toMap());

      return docRef.id;
    } catch (e) {
      _logger.e('Error adding cart item: $e');
      throw Exception('Failed to add cart item');
    }
  }

  // Get cart items for a user (model-based)
  Future<List<CartItemModel>> getCartItemsModel(String userId) async {
    try {
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CartItemModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Error getting cart items: $e');
      return [];
    }
  }

  // Update cart item
  Future<void> updateCartItem(CartItemModel cartItem, String userId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(cartItem.id)
          .update(cartItem.toMap());
    } catch (e) {
      _logger.e('Error updating cart item: $e');
      throw Exception('Failed to update cart item');
    }
  }

  // Remove cart item
  Future<void> removeCartItem(String userId, String cartItemId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(cartItemId)
          .delete();
    } catch (e) {
      _logger.e('Error removing cart item: $e');
      throw Exception('Failed to remove cart item');
    }
  }

  // Clear user's cart
  Future<void> clearCart(String userId) async {
    try {
      final firestore.QuerySnapshot cartItems = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      _logger.e('Error clearing cart: $e');
      throw Exception('Failed to clear cart');
    }
  }

  // Get cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    if (userId == null) {
      return [];
    }

    try {
      final firestore.QuerySnapshot cartSnapshot = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final List<Map<String, dynamic>> cartItems = [];

      for (final doc in cartSnapshot.docs) {
        final cartData = doc.data() as Map<String, dynamic>;
        final productId = cartData['productId'];

        // Get product details
        final firestore.DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(productId).get();
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;

          cartItems.add({
            'id': doc.id,
            'quantity': cartData['quantity'] ?? 1,
            'product': Product(
              id: productDoc.id,
              name: productData['name'] ?? '',
              description: productData['description'] ?? '',
              price: (productData['price'] ?? 0).toDouble(),
              imageUrl:
                  productData['imageUrl'] ?? 'assets/images/placeholder.png',
              category: productData['category'] ?? 'Uncategorized',
              rating: (productData['rating'] ?? 0).toDouble(),
              isPopular: productData['isPopular'] ?? false,
              isNewArrival: productData['isNewArrival'] ?? false,
            ),
          });
        }
      }

      return cartItems;
    } catch (e) {
      _logger.e('Error getting cart items: $e');
      return [];
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(productId)
          .delete();
    } catch (e) {
      _logger.e('Error removing item from cart: $e');
      throw Exception('Failed to remove product from cart');
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        await removeFromCart(productId);
      } else {
        // Update quantity
        await _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(productId)
            .update({
          'quantity': quantity,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.e('Error updating cart item quantity: $e');
      throw Exception('Failed to update cart item quantity');
    }
  }

  // ORDERS

  // Create an order
  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    required String address,
    String? notes,
  }) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create order document
      final orderRef = _firestore.collection('orders').doc();

      await orderRef.set({
        'userId': userId,
        'orderNumber': DateTime.now().millisecondsSinceEpoch.toString(),
        'status': 'Processing',
        'total': total,
        'paymentMethod': paymentMethod,
        'address': address,
        'notes': notes,
        'createdAt': firestore.FieldValue.serverTimestamp(),
      });

      // Add items to order
      for (final item in items) {
        await orderRef.collection('items').add({
          'productId': item['product'].id,
          'name': item['product'].name,
          'price': item['product'].price,
          'quantity': item['quantity'],
          'imageUrl': item['product'].imageUrl,
        });
      }

      // Clear cart after successful order
      final cartItems = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return orderRef.id;
    } catch (e) {
      _logger.e('Error creating order: $e');
      throw Exception('Failed to create order');
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    if (userId == null) {
      return [];
    }

    try {
      final firestore.QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> orders = [];

      for (final doc in orderSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get order items
        final firestore.QuerySnapshot itemsSnapshot =
            await doc.reference.collection('items').get();
        final List<Map<String, dynamic>> items =
            itemsSnapshot.docs.map((itemDoc) {
          final itemData = itemDoc.data() as Map<String, dynamic>;
          return {
            'id': itemDoc.id,
            'productId': itemData['productId'],
            'name': itemData['name'],
            'price': itemData['price'],
            'quantity': itemData['quantity'],
            'imageUrl': itemData['imageUrl'],
          };
        }).toList();

        orders.add({
          'id': doc.id,
          'orderNumber': data['orderNumber'],
          'status': data['status'],
          'total': data['total'],
          'paymentMethod': data['paymentMethod'],
          'address': data['address'],
          'notes': data['notes'],
          'createdAt': data['createdAt'],
          'items': items,
        });
      }

      return orders;
    } catch (e) {
      _logger.e('Error getting user orders: $e');
      return [];
    }
  }

  // Get order details
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    if (userId == null) {
      return null;
    }

    try {
      final firestore.DocumentSnapshot orderDoc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        return null;
      }

      final data = orderDoc.data() as Map<String, dynamic>;

      // Verify the order belongs to the current user
      if (data['userId'] != userId) {
        throw Exception('Unauthorized access to order');
      }

      // Get order items
      final firestore.QuerySnapshot itemsSnapshot =
          await orderDoc.reference.collection('items').get();
      final List<Map<String, dynamic>> items =
          itemsSnapshot.docs.map((itemDoc) {
        final itemData = itemDoc.data() as Map<String, dynamic>;
        return {
          'id': itemDoc.id,
          'productId': itemData['productId'],
          'name': itemData['name'],
          'price': itemData['price'],
          'quantity': itemData['quantity'],
          'imageUrl': itemData['imageUrl'],
        };
      }).toList();

      return {
        'id': orderDoc.id,
        'orderNumber': data['orderNumber'],
        'status': data['status'],
        'total': data['total'],
        'paymentMethod': data['paymentMethod'],
        'address': data['address'],
        'notes': data['notes'],
        'createdAt': data['createdAt'],
        'items': items,
      };
    } catch (e) {
      _logger.e('Error getting order details: $e');
      return null;
    }
  }

  // ORDERS (New Model-based Methods)

  // Create a new order
  Future<String> createNewOrder(Order order) async {
    try {
      _logger.i('Creating new order with user ID: ${order.userId}');
      _logger.i('Order items count: ${order.items.length}');
      _logger.i('Order receipt number: ${order.receiptNumber}');

      // Make sure userId is set to our test user
      final orderToSave = Order(
        id: order.id,
        userId: 'user_id1', // Hardcode for testing
        orderNumber: order.orderNumber,
        status: order.status,
        total: order.total,
        paymentMethod: order.paymentMethod,
        shippingAddress: order.shippingAddress,
        notes: order.notes,
        receiptNumber: order.receiptNumber,
        items: order.items,
        createdAt: order.createdAt,
      );

      // Add order to Firestore and get the document reference
      final docRef =
          await _firestore.collection('orders').add(orderToSave.toMap());
      _logger.i('Order created with ID: ${docRef.id}');

      // Verify the order was saved by retrieving it
      final savedDoc =
          await _firestore.collection('orders').doc(docRef.id).get();
      if (savedDoc.exists) {
        _logger.i('Order verified in database');
        final savedData = savedDoc.data();
        _logger.i('Saved order user ID: ${savedData!['userId']}');
      } else {
        _logger.w('WARNING: Order not found immediately after creation');
      }

      // Return the document ID
      return docRef.id;
    } catch (e, stackTrace) {
      _logger.e('Error creating order: $e');
      _logger.e('Stack trace: $stackTrace');
      return '';
    }
  }

  // Get orders for a user (model-based)
  Future<List<Order>> getUserOrdersModel(String userId) async {
    // Use actual user ID from authentication
    try {
      _logger.i('Getting orders for userId: $userId');
      // First try a simple query without complex filters
      final firestore.QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get(); // Removed orderBy to avoid issues with timestamp fields

      _logger.i('Got ${snapshot.docs.length} orders from Firestore');

      if (snapshot.docs.isEmpty) {
        // Let's try without filtering by userId for testing
        _logger.i('No orders found for user, trying to get all orders...');
        final allOrdersSnapshot = await _firestore.collection('orders').get();
        _logger.i(
            'Found ${allOrdersSnapshot.docs.length} total orders in database');

        if (allOrdersSnapshot.docs.isNotEmpty) {
          // Log some information about the first order to help diagnose the issue
          final firstOrder = allOrdersSnapshot.docs.first;
          final firstOrderData = firstOrder.data();
          _logger.i('First order: ${firstOrder.id}');
          _logger.i('First order userId: ${firstOrderData['userId']}');
        }
      }

      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        _logger.i('Processing order: ${doc.id}');
        return Order.fromMap(data, doc.id);
      }).toList();

      _logger.i('Returning ${orders.length} orders to OrderProvider');
      return orders;
    } catch (e, stackTrace) {
      _logger.e('Error getting user orders: $e');
      _logger.e('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final firestore.DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Order.fromMap(data, doc.id);
    } catch (e) {
      _logger.e('Error getting order: $e');
      return null;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
    } catch (e) {
      _logger.e('Error updating order status: $e');
      throw Exception('Failed to update order status');
    }
  }

  // Get all cart items for an order
  Future<List<CartItemModel>> getOrderCartItems(Order order) async {
    try {
      // Order already has the items, just return them
      return order.items;
    } catch (e) {
      _logger.e('Error getting order cart items: $e');
      return [];
    }
  }
}
