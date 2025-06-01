import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../entities/cart_item.dart';
import '../entities/shop_order.dart';

abstract class ShopRepository {
  // Product methods
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, List<Product>>> getProductsByCategory(String category);
  Future<Either<Failure, List<Product>>> getFeaturedProducts();
  Future<Either<Failure, List<Product>>> getPopularProducts();
  Future<Either<Failure, List<Product>>> getNewArrivals();
  Future<Either<Failure, Product?>> getProductById(String id);
  Future<Either<Failure, void>> updateProduct(Product product);

  // Cart methods
  Future<Either<Failure, List<CartItem>>> getCartItems(String userId);
  Future<Either<Failure, void>> addToCart(CartItem cartItem);
  Future<Either<Failure, void>> updateCartItem(CartItem cartItem);
  Future<Either<Failure, void>> removeFromCart(String userId, String cartItemId);
  Future<Either<Failure, void>> clearCart(String userId);

  // Order methods
  Future<Either<Failure, List<ShopOrder>>> getUserOrders(String userId);
  Future<Either<Failure, ShopOrder?>> getOrderById(String orderId);
  Future<Either<Failure, String>> createOrder(ShopOrder order);
  Future<Either<Failure, void>> updateOrder(ShopOrder order);
} 