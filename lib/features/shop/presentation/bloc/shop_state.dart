import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/shop_order.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopLoaded extends ShopState {
  final List<Product> products;
  final List<Product> featuredProducts;
  final List<Product> popularProducts;
  final List<Product> newArrivals;
  final List<CartItem> cartItems;
  final List<ShopOrder> orders;

  const ShopLoaded({
    this.products = const [],
    this.featuredProducts = const [],
    this.popularProducts = const [],
    this.newArrivals = const [],
    this.cartItems = const [],
    this.orders = const [],
  });

  ShopLoaded copyWith({
    List<Product>? products,
    List<Product>? featuredProducts,
    List<Product>? popularProducts,
    List<Product>? newArrivals,
    List<CartItem>? cartItems,
    List<ShopOrder>? orders,
  }) {
    return ShopLoaded(
      products: products ?? this.products,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      popularProducts: popularProducts ?? this.popularProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      cartItems: cartItems ?? this.cartItems,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [
        products,
        featuredProducts,
        popularProducts,
        newArrivals,
        cartItems,
        orders,
      ];
}

class ShopError extends ShopState {
  final String message;

  const ShopError(this.message);

  @override
  List<Object> get props => [message];
}

// Specific states for different operations
class ProductLoaded extends ShopState {
  final Product? product;

  const ProductLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class CartOperationSuccess extends ShopState {
  final String message;

  const CartOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class OrderCreated extends ShopState {
  final String orderId;

  const OrderCreated(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class OrderUpdated extends ShopState {
  final ShopOrder order;

  const OrderUpdated(this.order);

  @override
  List<Object> get props => [order];
} 