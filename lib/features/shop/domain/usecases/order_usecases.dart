import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/shop_order.dart';
import '../repositories/shop_repository.dart';

// Parameter classes
class GetUserOrdersParams {
  final String userId;

  const GetUserOrdersParams({required this.userId});
}

class GetOrderByIdParams {
  final String orderId;

  const GetOrderByIdParams({required this.orderId});
}

class CreateOrderParams {
  final ShopOrder order;

  const CreateOrderParams({required this.order});
}

class UpdateOrderParams {
  final ShopOrder order;

  const UpdateOrderParams({required this.order});
}

// Use cases
class GetUserOrdersUseCase implements UseCase<List<ShopOrder>, GetUserOrdersParams> {
  final ShopRepository repository;

  GetUserOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<ShopOrder>>> call(GetUserOrdersParams params) async {
    return await repository.getUserOrders(params.userId);
  }
}

class GetOrderByIdUseCase implements UseCase<ShopOrder?, GetOrderByIdParams> {
  final ShopRepository repository;

  GetOrderByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ShopOrder?>> call(GetOrderByIdParams params) async {
    return await repository.getOrderById(params.orderId);
  }
}

class CreateOrderUseCase implements UseCase<String, CreateOrderParams> {
  final ShopRepository repository;

  CreateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateOrderParams params) async {
    return await repository.createOrder(params.order);
  }
}

class UpdateOrderUseCase implements UseCase<void, UpdateOrderParams> {
  final ShopRepository repository;

  UpdateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateOrderParams params) async {
    return await repository.updateOrder(params.order);
  }
} 