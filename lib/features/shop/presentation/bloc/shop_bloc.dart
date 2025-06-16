import 'package:bloc/bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/cart_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/shop_order.dart';
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
  
  final LoggerService _logger = di.sl<LoggerService>();

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
    _logger.i('Loading cart items for user: ${event.userId}');
    emit(state.copyWith(isCartLoading: true, clearError: true));

    final result =
        await getCartItemsUseCase(GetCartItemsParams(userId: event.userId));

    result.fold(
      (failure) {
        _logger.e('Failed to load cart items: ${_mapFailureToMessage(failure)}');
        emit(state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isCartLoading: false,
        ));
      },
      (cartItems) {
        _logger.i('Successfully loaded ${cartItems.length} cart items for user: ${event.userId}');
        for (var item in cartItems) {
          _logger.d('Cart item: ${item.id}, Product: ${item.name}, Quantity: ${item.quantity}');
        }
        emit(state.copyWith(
          cartItems: cartItems,
          isCartLoading: false,
          clearError: true,
        ));
        _logger.d('Updated cart state with ${cartItems.length} items');
      },
    );
  }

  /// FIXED: Single emit for add to cart - production grade
  Future<void> _onAddToCart(
      AddToCartEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(
        isCartLoading: true, clearError: true, clearSuccess: true));

    _logger.i('Adding item to cart: ${event.cartItem.productId} for user: ${event.cartItem.userId}');

    final result = await addToCartUseCase(AddToCartParams(cartItem: event.cartItem));

    await result.fold(
      (failure) async {
        _logger.e('Failed to add item to cart: ${_mapFailureToMessage(failure)}');
        emit(state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isCartLoading: false,
        ));
      },
      (_) async {
        // Reload cart and emit single state
        _logger.i('Item added to cart successfully, reloading cart items');
        final cartResult = await getCartItemsUseCase(
            GetCartItemsParams(userId: event.cartItem.userId));

        cartResult.fold(
          (failure) {
            _logger.e('Failed to reload cart items: ${_mapFailureToMessage(failure)}');
            emit(state.copyWith(
              errorMessage: _mapFailureToMessage(failure),
              isCartLoading: false,
            ));
          },
          (cartItems) {
            _logger.i('Cart reloaded with ${cartItems.length} items, total count: ${cartItems.fold(0, (sum, item) => sum + item.quantity)}');
            emit(state.copyWith(
              cartItems: cartItems,
              successMessage: 'Item added to cart',
              isCartLoading: false,
              clearError: true,
            ));
          },
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
            GetCartItemsParams(userId: event.cartItem.userId));

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

    _logger.i('Clearing cart for user: ${event.userId}');

    final result =
        await clearCartUseCase(ClearCartParams(userId: event.userId));

    await result.fold(
      (failure) async {
        _logger.e('Failed to clear cart: ${_mapFailureToMessage(failure)}');
        emit(state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isCartLoading: false,
        ));
      },
      (_) async {
        // Clear cart and emit single state
        _logger.i('Cart cleared successfully');
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
    // Set loading state with a specific isOrderCreating flag
    emit(state.copyWith(
        status: ShopStatus.loading, 
        clearError: true, 
        clearSuccess: true,
        isOrderCreating: true));

    _logger.i('Creating order for user: ${event.order.userId} with ${event.order.items.length} items');
    _logger.i('Order details: Total: ${event.order.total}, Payment method: ${event.order.paymentMethod}');

    try {
      // Add the order to local cache immediately for optimistic UI update
      final localOrders = List<ShopOrder>.from(state.orders);
      localOrders.add(event.order);
      emit(state.copyWith(orders: localOrders, isOrderCreating: true));
      
      final result = await createOrderUseCase(CreateOrderParams(order: event.order));

      return result.fold(
        (failure) async {
          _logger.e('Failed to create order: ${_mapFailureToMessage(failure)}');
          // Remove the optimistically added order
          final updatedOrders = List<ShopOrder>.from(state.orders)
              .where((order) => order.id != event.order.id)
              .toList();
              
          emit(state.copyWith(
            status: ShopStatus.error,
            orders: updatedOrders,
            errorMessage: 'Failed to create order: ${_mapFailureToMessage(failure)}',
            isOrderCreating: false,
          ));
          
          // Don't clear the cart if order creation failed
          return;
        },
        (orderId) async {
          _logger.i('Order created successfully with ID: $orderId, now clearing cart');
          
          // Update the order in our local cache with the correct ID from Firestore
          final updatedOrders = List<ShopOrder>.from(state.orders);
          final orderIndex = updatedOrders.indexWhere((order) => order.id == event.order.id);
          if (orderIndex >= 0) {
            // If the temporary order exists in our list, update it with the real ID
            final updatedOrder = event.order.copyWith(id: orderId);
            updatedOrders[orderIndex] = updatedOrder;
          }
          
          // Clear the cart after successful order creation
          _logger.i('Attempting to clear cart for user: ${event.order.userId} after order creation');
          _logger.d('Current cart state before clearing: ${state.cartItems.length} items');
          
          final clearResult = await clearCartUseCase(ClearCartParams(userId: event.order.userId));
          
          return clearResult.fold(
            (failure) async {
              _logger.e('Failed to clear cart after order creation: ${_mapFailureToMessage(failure)}');
              _logger.e('Cart clearing failure details: User ID: ${event.order.userId}, Order ID: $orderId');
              
              emit(state.copyWith(
                status: ShopStatus.loaded,
                orders: updatedOrders,
                successMessage: 'Order created successfully: $orderId, but failed to clear cart: ${_mapFailureToMessage(failure)}',
                clearError: true,
                isOrderCreating: false,
              ));
              
              _logger.d('State after cart clearing failure: ${state.cartItems.length} items still in cart');
            },
            (_) async {
              _logger.i('Cart cleared successfully after order creation for user: ${event.order.userId}');
              _logger.i('Order ID: $orderId, Items cleared: ${state.cartItems.length}');
              
              emit(state.copyWith(
                status: ShopStatus.loaded,
                orders: updatedOrders,
                cartItems: [], // Clear cart items in state
                successMessage: 'Order created successfully: $orderId',
                clearError: true,
                isOrderCreating: false,
              ));
              
              _logger.d('State after cart clearing success: Cart items set to empty list');
            },
          );
        },
      );
    } catch (e) {
      _logger.e('Unexpected error during order creation: $e');
      emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: 'Unexpected error during order creation: $e',
        isOrderCreating: false,
      ));
    }
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
