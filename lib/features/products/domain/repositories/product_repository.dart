import '../../../home/data/models/banner_model.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts({int page = 1, int limit = 20});
  Future<ProductEntity?> getProductById(String id);
  Future<List<BannerModel>> getBanners();
}
