import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/shop_order.dart';

/// Production-grade state management for massive scale (40B users)
/// Single unified state pattern - eliminates multiple emits and state conflicts
class ShopState extends Equatable {
  final ShopStatus status;
  final List<Product> products;
  final List<Product> featuredProducts;
  final List<Product> popularProducts;
  final List<Product> newArrivals;
  final List<CartItem> cartItems;
  final List<ShopOrder> orders;
  final Product? selectedProduct;
  final String? successMessage;
  final String? errorMessage;
  final bool isCartLoading;
  final bool isProductsLoading;
  final int cartItemCount;

  const ShopState({
    this.status = ShopStatus.initial,
    this.products = const [],
    this.featuredProducts = const [],
    this.popularProducts = const [],
    this.newArrivals = const [],
    this.cartItems = const [],
    this.orders = const [],
    this.selectedProduct,
    this.successMessage,
    this.errorMessage,
    this.isCartLoading = false,
    this.isProductsLoading = false,
    this.cartItemCount = 0,
  });

  /// High-performance copyWith optimized for production scale
  ShopState copyWith({
    ShopStatus? status,
    List<Product>? products,
    List<Product>? featuredProducts,
    List<Product>? popularProducts,
    List<Product>? newArrivals,
    List<CartItem>? cartItems,
    List<ShopOrder>? orders,
    Product? selectedProduct,
    String? successMessage,
    String? errorMessage,
    bool? isCartLoading,
    bool? isProductsLoading,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    final newCartItems = cartItems ?? this.cartItems;
    return ShopState(
      status: status ?? this.status,
      products: products ?? this.products,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      popularProducts: popularProducts ?? this.popularProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      cartItems: newCartItems,
      orders: orders ?? this.orders,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCartLoading: isCartLoading ?? this.isCartLoading,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
      cartItemCount:
          newCartItems.fold<int>(0, (total, item) => total + item.quantity),
    );
  }

  /// Performance-optimized equality check for massive scale
  @override
  List<Object?> get props => [
        status,
        products.length,
        featuredProducts.length,
        popularProducts.length,
        newArrivals.length,
        cartItems.length,
        orders.length,
        selectedProduct?.id,
        successMessage,
        errorMessage,
        isCartLoading,
        isProductsLoading,
        cartItemCount,
      ];

  /// Convenience getters for UI
  bool get isLoading =>
      status == ShopStatus.loading || isCartLoading || isProductsLoading;
  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
  bool get isLoaded => status == ShopStatus.loaded;
  bool get isEmpty => products.isEmpty && featuredProducts.isEmpty;
}

/// Simplified status enum for production reliability
enum ShopStatus {
  initial,
  loading,
  loaded,
  error,
}
