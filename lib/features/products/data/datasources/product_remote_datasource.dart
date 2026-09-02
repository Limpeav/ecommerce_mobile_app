import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/data/models/banner_model.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts({int page = 1, int limit = 20});
  Future<ProductModel?> fetchProductById(String id);
  Future<List<BannerModel>> fetchBanners();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    try {
      final url = '${ApiConstants.products}/$id';
      final dynamic data = await apiClient.get(
        url,
        timeout: const Duration(seconds: 15),
      );
      if (data is Map<String, dynamic>) {
        final product = ProductModel.fromJson(data);
        debugPrint('✅ Successfully fetched live product ${product.id} with ${product.reviews.length} reviews from backend API');
        return product;
      }
    } catch (e) {
      debugPrint('⚠️ Warning fetching live product $id from backend: $e');
    }
    return null;
  }

  @override
  Future<List<ProductModel>> fetchProducts({int page = 1, int limit = 20}) async {
    try {
      final url = '${ApiConstants.products}?page=$page&limit=$limit';
      final dynamic data = await apiClient.get(
        url,
        timeout: const Duration(seconds: 15),
      );
      
      List<dynamic>? list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        if (data['products'] is List) {
          list = data['products'] as List<dynamic>;
        } else if (data['data'] is List) {
          list = data['data'] as List<dynamic>;
        }
      }

      if (list != null && list.isNotEmpty) {
        final products = list
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('✅ Successfully fetched ${products.length} live products from backend database');
        return products;
      }
    } catch (e) {
      debugPrint('⚠️ Warning fetching live products from backend: $e. Falling back to local catalog.');
    }
    return getMockProductModels();
  }

  @override
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final dynamic data = await apiClient.get(
        ApiConstants.banners,
        timeout: const Duration(seconds: 15),
      );

      List<dynamic>? list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        if (data['banners'] is List) {
          list = data['banners'] as List<dynamic>;
        } else if (data['data'] is List) {
          list = data['data'] as List<dynamic>;
        }
      }

      if (list != null && list.isNotEmpty) {
        final banners = list
            .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
            .where((b) => b.isActive && b.image.isNotEmpty)
            .toList();
        banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        debugPrint('✅ Successfully fetched ${banners.length} live banners from backend');
        return banners;
      }
    } catch (e) {
      debugPrint('⚠️ Warning fetching live banners from backend: $e');
    }
    return const [];
  }

  static List<ProductModel> getMockProductModels() {
    return const [
      ProductModel(
        id: '6a6c6019382bd53f1e45a7b1',
        title: 'Sinhoon Newborn Baby Girl Romper Infant Letter Print Bodysuit 4Pcs Outfit',
        price: 11.99,
        originalPrice: 14.99,
        description:
            'Dress your little one in adorable comfort with this Baby Giraffe Long Sleeve Romper Gift Set. Crafted from soft, breathable organic cotton fabric.',
        category: 'Clothing',
        image: 'https://res.cloudinary.com/dykl9a88x/image/upload/v1785487381/uploads/wotonohxuloezawnxpbs.png',
        images: [
          'https://res.cloudinary.com/dykl9a88x/image/upload/v1785487381/uploads/wotonohxuloezawnxpbs.png',
        ],
        rating: 4.9,
        ratingCount: 128,
        availableColors: ['Warm Yellow', 'Pastel Pink', 'Mint Green'],
        availableSizes: ['0-3M', '3-6M', '6-12M'],
        isFlashDeal: true,
        discountPercentage: 20,
        stock: 25,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0a',
        title: 'BloomCare Ergonomic Sensory Baby Rattle & Teether Set',
        price: 12.00,
        originalPrice: 15.50,
        description:
            'BPA-free food-grade silicone baby rattle and teether designed to soothe sore gums and stimulate sensory motor skill development.',
        category: 'Toys',
        image: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        images: [
          'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        ],
        rating: 4.8,
        ratingCount: 94,
        availableColors: ['Multicolor', 'Pastel Sky', 'Natural Wood'],
        availableSizes: ['Standard'],
        isFlashDeal: false,
        discountPercentage: 15,
        stock: 30,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0b',
        title: 'Multi-Function Foldable Baby Diaper Travel Bag with Changing Bed Station',
        price: 34.50,
        originalPrice: 45.00,
        description:
            'Large capacity waterproof diaper backpack equipped with insulated bottle warmers, built-in expandable crib changing station, and USB charge port.',
        category: 'Travel & Gear',
        image: 'https://res.cloudinary.com/dykl9a88x/image/upload/v1785487381/uploads/wotonohxuloezawnxpbs.png',
        images: [
          'https://res.cloudinary.com/dykl9a88x/image/upload/v1785487381/uploads/wotonohxuloezawnxpbs.png',
        ],
        rating: 4.9,
        ratingCount: 152,
        availableColors: ['Navy Blue', 'Charcoal Grey', 'Soft Pink'],
        availableSizes: ['One Size'],
        isFlashDeal: true,
        discountPercentage: 23,
        stock: 18,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0c',
        title: 'Natural Anti-Colic Silicone Feeding Baby Bottle (240ml)',
        price: 15.99,
        originalPrice: 19.99,
        description:
            'Wide-neck ergonomic silicone baby bottle with ultra-soft breast-like nipple design to prevent colic and reflux.',
        category: 'Feeding',
        image: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        images: [
          'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        ],
        rating: 4.9,
        ratingCount: 110,
        availableColors: ['Sky Blue', 'Pastel Pink', 'Cream'],
        availableSizes: ['240ml', '300ml'],
        isFlashDeal: false,
        discountPercentage: 20,
        stock: 40,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0d',
        title: 'Organic Calming Baby Bubble Bath & Gentle Shampoo Duo',
        price: 18.50,
        originalPrice: 22.00,
        description:
            'Hypoallergenic tear-free baby wash infused with natural chamomile and lavender to soothe baby skin before bedtime.',
        category: 'Bath & Skin',
        image: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        images: [
          'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        ],
        rating: 4.8,
        ratingCount: 88,
        availableColors: ['Lavender Scent', 'Unscented'],
        availableSizes: ['500ml'],
        isFlashDeal: true,
        discountPercentage: 16,
        stock: 35,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0e',
        title: 'Solid Pine Convertible Rocking Baby Crib & Bassinet',
        price: 189.00,
        originalPrice: 249.00,
        description:
            'Sustainably sourced natural pine wood cradle with smooth rocking motion, locking wheels, and breathable mattress.',
        category: 'Furniture',
        image: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        images: [
          'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        ],
        rating: 4.9,
        ratingCount: 64,
        availableColors: ['Natural Pine', 'Pure White', 'Warm Walnut'],
        availableSizes: ['Standard Crib'],
        isFlashDeal: false,
        discountPercentage: 24,
        stock: 12,
      ),
      ProductModel(
        id: '6965df69241e5bb141e8bf0f',
        title: 'Soft-Sole Anti-Slip First Walker Baby Canvas Sneakers',
        price: 14.50,
        originalPrice: 18.00,
        description:
            'Breathable lightweight baby walking shoes with flexible non-slip rubber soles and easy-on elastic laces.',
        category: 'Shoes',
        image: 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        images: [
          'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
        ],
        rating: 4.9,
        ratingCount: 140,
        availableColors: ['Classic Navy', 'Soft Beige', 'Candy Pink'],
        availableSizes: ['0-6M', '6-12M', '12-18M'],
        isFlashDeal: true,
        discountPercentage: 19,
        stock: 22,
      ),
    ];
  }
}
