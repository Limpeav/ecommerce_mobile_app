import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<List<ProductEntity>> call({int page = 1, int limit = 20}) async {
    return await repository.getProducts(page: page, limit: limit);
  }
}
