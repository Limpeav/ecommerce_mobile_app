import '../../../home/data/models/banner_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductEntity>> getProducts({int page = 1, int limit = 20}) async {
    return await remoteDataSource.fetchProducts(page: page, limit: limit);
  }

  @override
  Future<ProductEntity?> getProductById(String id) async {
    final liveProduct = await remoteDataSource.fetchProductById(id);
    if (liveProduct != null) {
      return liveProduct;
    }
    final products = await remoteDataSource.fetchProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BannerModel>> getBanners() async {
    return await remoteDataSource.fetchBanners();
  }
}
