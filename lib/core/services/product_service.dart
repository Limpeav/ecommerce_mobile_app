import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../network/api_client.dart';

class ProductService {
  final ProductRemoteDataSource _remoteDataSource =
      ProductRemoteDataSourceImpl(apiClient: ApiClient());

  Future<List<ProductEntity>> fetchProducts() async {
    return await _remoteDataSource.fetchProducts();
  }

  static List<ProductEntity> getMockProducts() {
    return ProductRemoteDataSourceImpl.getMockProductModels();
  }
}
