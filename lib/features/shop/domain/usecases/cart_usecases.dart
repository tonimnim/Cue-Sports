import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cart_item.dart';
import '../repositories/shop_repository.dart';

// Parameter classes
class GetCartItemsParams {
  final String userId;

  const GetCartItemsParams({required this.userId});
}

class AddToCartParams {
  final CartItem cartItem;

  const AddToCartParams({required this.cartItem});
}

class UpdateCartItemParams {
  final CartItem cartItem;

  const UpdateCartItemParams({required this.cartItem});
}

class RemoveFromCartParams {
  final String userId;
  final String cartItemId;

  const RemoveFromCartParams({
    required this.userId,
    required this.cartItemId,
  });
}

class ClearCartParams {
  final String userId;

  const ClearCartParams({required this.userId});
}

// Use cases
class GetCartItemsUseCase implements UseCase<List<CartItem>, GetCartItemsParams> {
  final ShopRepository repository;

  GetCartItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItem>>> call(GetCartItemsParams params) async {
    return await repository.getCartItems(params.userId);
  }
}

class AddToCartUseCase implements UseCase<void, AddToCartParams> {
  final ShopRepository repository;

  AddToCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddToCartParams params) async {
    return await repository.addToCart(params.cartItem);
  }
}

class UpdateCartItemUseCase implements UseCase<void, UpdateCartItemParams> {
  final ShopRepository repository;

  UpdateCartItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCartItemParams params) async {
    return await repository.updateCartItem(params.cartItem);
  }
}

class RemoveFromCartUseCase implements UseCase<void, RemoveFromCartParams> {
  final ShopRepository repository;

  RemoveFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromCartParams params) async {
    return await repository.removeFromCart(params.userId, params.cartItemId);
  }
}

class ClearCartUseCase implements UseCase<void, ClearCartParams> {
  final ShopRepository repository;

  ClearCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ClearCartParams params) async {
    return await repository.clearCart(params.userId);
  }
} 