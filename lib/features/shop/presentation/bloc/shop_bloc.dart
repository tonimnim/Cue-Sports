import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/cart_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import 'shop_event.dart';
import 'shop_state.dart';

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
  }) : super(ShopInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadProductsByCategoryEvent>(_onLoadProductsByCategory);
    on<LoadFeaturedProductsEvent>(_onLoadFeaturedProducts);
    on<LoadPopularProductsEvent>(_onLoadPopularProducts);
    on<LoadNewArrivalsEvent>(_onLoadNewArrivals);
    on<LoadProductByIdEvent>(_onLoadProductById);

    on<LoadCartItemsEvent>(_onLoadCartItems);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemEvent>(_onUpdateCartItem);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);

    on<LoadUserOrdersEvent>(_onLoadUserOrders);
    on<CreateOrderEvent>(_onCreateOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
  }

  Future<void> _onLoadProducts(LoadProductsEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());

    final result = await getProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (products) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(products: products));
      },
    );
  }

  Future<void> _onLoadProductsByCategory(LoadProductsByCategoryEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());

    final result = await getProductsByCategoryUseCase(GetProductsByCategoryParams(category: event.category));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (products) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(products: products));
      },
    );
  }

  Future<void> _onLoadFeaturedProducts(LoadFeaturedProductsEvent event, Emitter<ShopState> emit) async {
    if (state is! ShopLoaded) {
      emit(ShopLoading());
    }

    final result = await getFeaturedProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (products) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(featuredProducts: products));
      },
    );
  }

  Future<void> _onLoadPopularProducts(LoadPopularProductsEvent event, Emitter<ShopState> emit) async {
    if (state is! ShopLoaded) {
      emit(ShopLoading());
    }

    final result = await getPopularProductsUseCase(NoParams());

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (products) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(popularProducts: products));
      },
    );
  }

  Future<void> _onLoadNewArrivals(LoadNewArrivalsEvent event, Emitter<ShopState> emit) async {
    if (state is! ShopLoaded) {
      emit(ShopLoading());
    }

    final result = await getNewArrivalsUseCase(NoParams());

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (products) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(newArrivals: products));
      },
    );
  }

  Future<void> _onLoadProductById(LoadProductByIdEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());

    final result = await getProductByIdUseCase(GetProductByIdParams(id: event.productId));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (product) => emit(ProductLoaded(product)),
    );
  }

  Future<void> _onLoadCartItems(LoadCartItemsEvent event, Emitter<ShopState> emit) async {
    final result = await getCartItemsUseCase(GetCartItemsParams(userId: event.userId));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (cartItems) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(cartItems: cartItems));
      },
    );
  }

  Future<void> _onAddToCart(AddToCartEvent event, Emitter<ShopState> emit) async {
    final result = await addToCartUseCase(AddToCartParams(cartItem: event.cartItem));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (_) => emit(const CartOperationSuccess('Item added to cart')),
    );
  }

  Future<void> _onUpdateCartItem(UpdateCartItemEvent event, Emitter<ShopState> emit) async {
    final result = await updateCartItemUseCase(UpdateCartItemParams(cartItem: event.cartItem));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (_) => emit(const CartOperationSuccess('Cart item updated')),
    );
  }

  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<ShopState> emit) async {
    final result = await removeFromCartUseCase(
      RemoveFromCartParams(userId: event.userId, cartItemId: event.cartItemId),
    );

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (_) => emit(const CartOperationSuccess('Item removed from cart')),
    );
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<ShopState> emit) async {
    final result = await clearCartUseCase(ClearCartParams(userId: event.userId));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (_) => emit(const CartOperationSuccess('Cart cleared')),
    );
  }

  Future<void> _onLoadUserOrders(LoadUserOrdersEvent event, Emitter<ShopState> emit) async {
    final result = await getUserOrdersUseCase(GetUserOrdersParams(userId: event.userId));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (orders) {
        final currentState = state is ShopLoaded ? state as ShopLoaded : const ShopLoaded();
        emit(currentState.copyWith(orders: orders));
      },
    );
  }

  Future<void> _onCreateOrder(CreateOrderEvent event, Emitter<ShopState> emit) async {
    final result = await createOrderUseCase(CreateOrderParams(order: event.order));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (orderId) => emit(OrderCreated(orderId)),
    );
  }

  Future<void> _onUpdateOrder(UpdateOrderEvent event, Emitter<ShopState> emit) async {
    final result = await updateOrderUseCase(UpdateOrderParams(order: event.order));

    result.fold(
      (failure) => emit(ShopError(_mapFailureToMessage(failure))),
      (_) => emit(OrderUpdated(event.order)),
    );
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