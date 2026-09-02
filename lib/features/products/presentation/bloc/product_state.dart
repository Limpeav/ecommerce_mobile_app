import 'package:equatable/equatable.dart';
import '../../../home/data/models/banner_model.dart';
import '../../domain/entities/product_entity.dart';
import 'product_event.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<ProductEntity> allProducts;
  final List<BannerModel> banners;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  final String selectedCategory;
  final String searchQuery;
  final SortOption sortOption;
  final double maxPriceFilter;
  final double minRatingFilter;

  const ProductState({
    this.status = ProductStatus.initial,
    this.allProducts = const [],
    this.banners = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.errorMessage,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.sortOption = SortOption.featured,
    this.maxPriceFilter = 1000.0,
    this.minRatingFilter = 0.0,
  });

  bool get isLoading => status == ProductStatus.loading;

  List<String> get categories {
    final set = {'All'};
    for (var p in allProducts) {
      set.add(p.category);
    }
    return set.toList();
  }

  List<ProductEntity> get flashDeals => allProducts
      .where((p) =>
          p.discountPercentage > 0 &&
          p.originalPrice != null &&
          p.originalPrice! > p.price)
      .toList();

  List<ProductEntity> get featuredProducts =>
      allProducts.where((p) => p.rating >= 4.7).toList();

  List<ProductEntity> get filteredProducts {
    var list = allProducts.where((p) {
      final matchesCategory = selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesPrice = p.price <= maxPriceFilter;
      final matchesRating = p.rating >= minRatingFilter;

      return matchesCategory && matchesSearch && matchesPrice && matchesRating;
    }).toList();

    switch (sortOption) {
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.ratingHighToLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.featured:
        break;
    }

    return list;
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedCategory != 'All') count++;
    if (searchQuery.trim().isNotEmpty) count++;
    if (sortOption != SortOption.featured) count++;
    if (maxPriceFilter < 1000.0) count++;
    if (minRatingFilter > 0.0) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  ProductEntity? getProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProductState copyWith({
    ProductStatus? status,
    List<ProductEntity>? allProducts,
    List<BannerModel>? banners,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    String? selectedCategory,
    String? searchQuery,
    SortOption? sortOption,
    double? maxPriceFilter,
    double? minRatingFilter,
    bool clearError = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      banners: banners ?? this.banners,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      maxPriceFilter: maxPriceFilter ?? this.maxPriceFilter,
      minRatingFilter: minRatingFilter ?? this.minRatingFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allProducts,
        banners,
        isLoadingMore,
        hasMore,
        currentPage,
        errorMessage,
        selectedCategory,
        searchQuery,
        sortOption,
        maxPriceFilter,
        minRatingFilter,
      ];
}
