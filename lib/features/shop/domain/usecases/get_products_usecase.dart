import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/shop_repository.dart';

class GetProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ShopRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getProducts();
  }
}

// Use case parameter classes
class GetProductsByCategoryParams {
  final String category;

  const GetProductsByCategoryParams({required this.category});
}

class GetProductByIdParams {
  final String id;

  const GetProductByIdParams({required this.id});
}

class GetProductsByCategoryUseCase implements UseCase<List<Product>, GetProductsByCategoryParams> {
  final ShopRepository repository;

  GetProductsByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetProductsByCategoryParams params) async {
    return await repository.getProductsByCategory(params.category);
  }
}

class GetFeaturedProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ShopRepository repository;

  GetFeaturedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getFeaturedProducts();
  }
}

class GetPopularProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ShopRepository repository;

  GetPopularProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getPopularProducts();
  }
}

class GetNewArrivalsUseCase implements UseCase<List<Product>, NoParams> {
  final ShopRepository repository;

  GetNewArrivalsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getNewArrivals();
  }
}

class GetProductByIdUseCase implements UseCase<Product?, GetProductByIdParams> {
  final ShopRepository repository;

  GetProductByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Product?>> call(GetProductByIdParams params) async {
    return await repository.getProductById(params.id);
  }
}