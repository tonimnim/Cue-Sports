import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/shop_order.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object> get props => [];
}

// Product events
class LoadProductsEvent extends ShopEvent {}

class LoadProductsByCategoryEvent extends ShopEvent {
  final String category;

  const LoadProductsByCategoryEvent(this.category);

  @override
  List<Object> get props => [category];
}

class LoadFeaturedProductsEvent extends ShopEvent {}

class LoadPopularProductsEvent extends ShopEvent {}

class LoadNewArrivalsEvent extends ShopEvent {}

class LoadProductByIdEvent extends ShopEvent {
  final String productId;

  const LoadProductByIdEvent(this.productId);

  @override
  List<Object> get props => [productId];
}

// Cart events
class LoadCartItemsEvent extends ShopEvent {
  final String userId;

  const LoadCartItemsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddToCartEvent extends ShopEvent {
  final CartItem cartItem;

  const AddToCartEvent(this.cartItem);

  @override
  List<Object> get props => [cartItem];
}

class UpdateCartItemEvent extends ShopEvent {
  final CartItem cartItem;

  const UpdateCartItemEvent(this.cartItem);

  @override
  List<Object> get props => [cartItem];
}

class RemoveFromCartEvent extends ShopEvent {
  final String userId;
  final String cartItemId;

  const RemoveFromCartEvent(this.userId, this.cartItemId);

  @override
  List<Object> get props => [userId, cartItemId];
}

class ClearCartEvent extends ShopEvent {
  final String userId;

  const ClearCartEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

// Order events
class LoadUserOrdersEvent extends ShopEvent {
  final String userId;

  const LoadUserOrdersEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class CreateOrderEvent extends ShopEvent {
  final ShopOrder order;

  const CreateOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}

class UpdateOrderEvent extends ShopEvent {
  final ShopOrder order;

  const UpdateOrderEvent(this.order);

  @override
  List<Object> get props => [order];
} 