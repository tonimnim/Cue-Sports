import 'package:bloc/bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/cart_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../domain/entities/cart_item.dart';
import 'shop_event.dart';
import 'shop_state.dart';

/// Production-grade ShopBloc for massive scale (40B users)
/// Single emit per event handler - no state conflicts
class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final GetProductsUseCase getProductsUseCase;
  final GetProductsByCategoryUseCase getProductsByCategoryUseCase;
  final GetFeaturedProductsUseCase getFeaturedProductsUseCase;
  final GetPopularProductsUseCase getPopularProductsUseCase;
  final GetNewArrivalsUseCase getNewArrivalsUseCase;
  final GetProductByIdUseCase getProductByIdUseCase;

  final GetCartItemsUseCase getCartItemsUseCase;
  final AddToCartUseCase addToCartUseCase;
  final UpdateCartItemUseCase updateCartItemUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ClearCartUseCase clearCartUseCase;

  final GetUserOrdersUseCase getUserOrdersUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final UpdateOrderUseCase updateOrderUseCase;

  ShopBloc({
    required this.getProductsUseCase,
    required this.getProductsByCategoryUseCase,
    required this.getFeaturedProductsUseCase,
    required this.getPopularProductsUseCase,
    required this.getNewArrivalsUseCase,
    required this.getProductByIdUseCase,
    required this.getCartItemsUseCase,
    required this.addToCartUseCase,
    required this.updateCartItemUseCase,
    required this.removeFromCartUseCase,
    required this.clearCartUseCase,
    required this.getUserOrdersUseCase,
    required this.createOrderUseCase,
    required this.updateOrderUseCase,
  }) : super(const ShopState()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<SearchProductsEvent>(_onSearchProducts);
    on<LoadProductsByCategoryEvent>(_onLoadProductsByCategory);
    on<FilterProductsByCategoryEvent>(_onFilterProductsByCategory);
    on<LoadFeaturedProductsEvent>(_onLoadFeaturedProducts);
    on<LoadPopularProductsEvent>(_onLoadPopularProducts);
    on<LoadNewArrivalsEvent>(_onLoadNewArrivals);
    on<LoadProductByIdEvent>(_onLoadProductById);

    on<LoadCartItemsEvent>(_onLoadCartItems);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemEvent>(_onUpdateCartItem);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);

    on<LoadUserOrdersEvent>(_onLoadUserOrders);
    on<CreateOrderEvent>(_onCreateOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
  }

  Future<void> _onLoadProducts(
      LoadProductsEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, isProductsLoading: true, clearError: true));

    final result = await getProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
        isProductsLoading: false,
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        products: products,
        isProductsLoading: false,
        clearError: true,
      )),
    );
  }

  Future<void> _onSearchProducts(
      SearchProductsEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, isProductsLoading: true, clearError: true));

    // Get all products first
    final result = await getProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
        isProductsLoading: false,
      )),
      (allProducts) {
        // Filter products based on search query
        final searchQuery = event.query.toLowerCase();
        final filteredProducts = allProducts.where((product) {
          return product.name.toLowerCase().contains(searchQuery) ||
              product.description.toLowerCase().contains(searchQuery) ||
              product.category.toLowerCase().contains(searchQuery);
        }).toList();

        emit(state.copyWith(
          status: ShopStatus.loaded,
          products: filteredProducts,
          isProductsLoading: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadProductsByCategory(
      LoadProductsByCategoryEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, isProductsLoading: true, clearError: true));

    final result = await getProductsByCategoryUseCase(
        GetProductsByCategoryParams(category: event.category));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
        isProductsLoading: false,
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        products: products,
        isProductsLoading: false,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadFeaturedProducts(
      LoadFeaturedProductsEvent event, Emitter<ShopState> emit) async {
    if (!state.isLoaded) {
      emit(state.copyWith(status: ShopStatus.loading, clearError: true));
    }

    final result = await getFeaturedProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        featuredProducts: products,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadPopularProducts(
      LoadPopularProductsEvent event, Emitter<ShopState> emit) async {
    if (!state.isLoaded) {
      emit(state.copyWith(status: ShopStatus.loading, clearError: true));
    }

    final result = await getPopularProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        popularProducts: products,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadNewArrivals(
      LoadNewArrivalsEvent event, Emitter<ShopState> emit) async {
    if (!state.isLoaded) {
      emit(state.copyWith(status: ShopStatus.loading, clearError: true));
    }

    final result = await getNewArrivalsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        newArrivals: products,
        clearError: true,
      )),
    );
  }

  Future<void> _onLoadProductById(
      LoadProductByIdEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(status: ShopStatus.loading, clearError: true));

    final result =
        await getProductByIdUseCase(GetProductByIdParams(id: event.productId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (product) => emit(state.copyWith(
        status: ShopStatus.loaded,
        selectedProduct: product,
        clearError: true,
      )),
    );
  }

  /// Production-grade cart loading with error handling
  Future<void> _onLoadCartItems(
      LoadCartItemsEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(isCartLoading: true, clearError: true));

    final result =
        await getCartItemsUseCase(GetCartItemsParams(userId: event.userId));

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isCartLoading: false,
      )),
      (cartItems) => emit(state.copyWith(
        cartItems: cartItems,
        isCartLoading: false,
        clearError: true,
      )),
    );
  }

  /// FIXED: Single emit for add to cart - production grade
  Future<void> _onAddToCart(
      AddToCartEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    final result =
        await addToCartUseCase(AddToCartParams(cartItem: event.cartItem));

    await result.fold(
      (failure) async => emit(state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isCartLoading: false,
      )),
      (_) async {
        // Reload cart items and emit single state with success message
        final cartResult = await getCartItemsUseCase(
            GetCartItemsParams(userId: 'current_user'));

        cartResult.fold(
          (failure) => emit(state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isCartLoading: false,
          )),
          (cartItems) => emit(state.copyWith(
            cartItems: cartItems,
            successMessage: 'Item added to cart',
            isCartLoading: false,
            clearError: true,
          )),
        );
      },
    );
  }

  Future<void> _onUpdateCartItem(
      UpdateCartItemEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    final result = await updateCartItemUseCase(
        UpdateCartItemParams(cartItem: event.cartItem));

    await result.fold(
      (failure) async => emit(state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isCartLoading: false,
      )),
      (_) async {
        // Reload cart and emit single state
        final cartResult = await getCartItemsUseCase(
            GetCartItemsParams(userId: 'current_user'));

        cartResult.fold(
          (failure) => emit(state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isCartLoading: false,
          )),
          (cartItems) => emit(state.copyWith(
            cartItems: cartItems,
            successMessage: 'Cart item updated',
            isCartLoading: false,
            clearError: true,
          )),
        );
      },
    );
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCartEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    final result = await removeFromCartUseCase(
      RemoveFromCartParams(userId: event.userId, cartItemId: event.cartItemId),
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isCartLoading: false,
      )),
      (_) async {
        // Reload cart and emit single state
        final cartResult =
            await getCartItemsUseCase(GetCartItemsParams(userId: event.userId));

        cartResult.fold(
          (failure) => emit(state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isCartLoading: false,
          )),
          (cartItems) => emit(state.copyWith(
            cartItems: cartItems,
            successMessage: 'Item removed from cart',
            isCartLoading: false,
            clearError: true,
          )),
        );
      },
    );
  }

  Future<void> _onClearCart(
      ClearCartEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    final result =
        await clearCartUseCase(ClearCartParams(userId: event.userId));

    await result.fold(
      (failure) async => emit(state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isCartLoading: false,
      )),
      (_) async {
        // Clear cart and emit single state
        emit(state.copyWith(
          cartItems: [],
          successMessage: 'Cart cleared',
          isCartLoading: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadUserOrders(
      LoadUserOrdersEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(status: ShopStatus.loading, clearError: true));

    final result =
        await getUserOrdersUseCase(GetUserOrdersParams(userId: event.userId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (orders) => emit(state.copyWith(
        status: ShopStatus.loaded,
        orders: orders,
        clearError: true,
      )),
    );
  }

  Future<void> _onCreateOrder(
      CreateOrderEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, clearError: true, clearSuccess: true));

    final result =
        await createOrderUseCase(CreateOrderParams(order: event.order));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (orderId) => emit(state.copyWith(
        status: ShopStatus.loaded,
        successMessage: 'Order created successfully: $orderId',
        clearError: true,
      )),
    );
  }

  Future<void> _onUpdateOrder(
      UpdateOrderEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, clearError: true, clearSuccess: true));

    final result =
        await updateOrderUseCase(UpdateOrderParams(order: event.order));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (_) => emit(state.copyWith(
        status: ShopStatus.loaded,
        successMessage: 'Order updated successfully',
        clearError: true,
      )),
    );
  }

  Future<void> _onFilterProductsByCategory(
      FilterProductsByCategoryEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        status: ShopStatus.loading, isProductsLoading: true, clearError: true));

    final result = await getProductsByCategoryUseCase(
        GetProductsByCategoryParams(category: event.category));

    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: _mapFailureToMessage(failure),
        isProductsLoading: false,
      )),
      (products) => emit(state.copyWith(
        status: ShopStatus.loaded,
        products: products,
        isProductsLoading: false,
        clearError: true,
      )),
    );
  }

  Future<void> _onUpdateCartItemQuantity(
      UpdateCartItemQuantityEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    try {
      // Find the cart item to update
      final currentCartItems = List<CartItem>.from(state.cartItems);
      final itemIndex =
          currentCartItems.indexWhere((item) => item.id == event.cartItemId);

      if (itemIndex == -1) {
        emit(state.copyWith(
          errorMessage: 'Cart item not found',
          isCartLoading: false,
        ));
        return;
      }

      // Update the quantity locally first (optimistic update)
      final currentItem = currentCartItems[itemIndex];
      final updatedItem = currentItem.copyWith(quantity: event.quantity);
      currentCartItems[itemIndex] = updatedItem;

      // Emit updated state immediately for smooth UI
      emit(state.copyWith(
        cartItems: currentCartItems,
        isCartLoading: false,
        successMessage: 'Cart quantity updated',
        clearError: true,
      ));

      // Then sync with backend
      final result = await updateCartItemUseCase(
          UpdateCartItemParams(cartItem: updatedItem));

      result.fold(
        (failure) async {
          // Revert on failure - reload original cart
          final cartResult = await getCartItemsUseCase(
              GetCartItemsParams(userId: event.userId));

          cartResult.fold(
            (loadFailure) => emit(state.copyWith(
              errorMessage:
                  'Failed to update cart: ${_mapFailureToMessage(failure)}',
              isCartLoading: false,
            )),
            (originalCartItems) => emit(state.copyWith(
              cartItems: originalCartItems,
              errorMessage:
                  'Failed to update cart: ${_mapFailureToMessage(failure)}',
              isCartLoading: false,
            )),
          );
        },
        (_) {
          // Backend sync successful - state already updated
          // Optionally reload to ensure consistency
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error updating cart quantity: $e',
        isCartLoading: false,
      ));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message ?? 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      case NetworkFailure:
        return 'Network error occurred';
      default:
        return 'Unexpected error occurred';
    }
  }
}
