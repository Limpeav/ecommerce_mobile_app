import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/banner_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final ProductRepository? productRepository;

  static const int _pageSize = 20;

  ProductBloc({
    required this.getProductsUseCase,
    this.productRepository,
  }) : super(const ProductState()) {
    on<ProductLoadRequested>(_onProductLoadRequested);
    on<ProductLoadMoreRequested>(_onProductLoadMoreRequested);
    on<ProductRefreshRequested>(_onProductRefreshRequested);
    on<ProductCategorySelected>(_onProductCategorySelected);
    on<ProductSearchChanged>(_onProductSearchChanged);
    on<ProductSortChanged>(_onProductSortChanged);
    on<ProductPriceFilterChanged>(_onProductPriceFilterChanged);
    on<ProductRatingFilterChanged>(_onProductRatingFilterChanged);
    on<ProductFiltersReset>(_onProductFiltersReset);
    on<ProductAddReviewRequested>(_onProductAddReviewRequested);

    // Automatically trigger initial load
    add(const ProductLoadRequested());
  }

  Future<void> _onProductLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(
      status: ProductStatus.loading,
      currentPage: 1,
      hasMore: true,
      clearError: true,
    ));

    try {
      final futures = <Future<dynamic>>[
        getProductsUseCase(page: 1, limit: _pageSize),
        if (productRepository != null)
          productRepository!.getBanners()
        else
          Future.value(<BannerModel>[]),
      ];

      final results = await Future.wait(futures);
      final products = results[0] as List<ProductEntity>;
      final banners = results[1] as List<BannerModel>;

      emit(state.copyWith(
        status: ProductStatus.success,
        allProducts: products,
        banners: banners,
        currentPage: 1,
        hasMore: products.length >= _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onProductLoadMoreRequested(
    ProductLoadMoreRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final newProducts = await getProductsUseCase(page: nextPage, limit: _pageSize);

      if (newProducts.isEmpty) {
        emit(state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        ));
      } else {
        final existingIds = state.allProducts.map((p) => p.id).toSet();
        final distinctNew = newProducts.where((p) => !existingIds.contains(p.id)).toList();

        final updatedList = List<ProductEntity>.from(state.allProducts)..addAll(distinctNew);

        emit(state.copyWith(
          isLoadingMore: false,
          allProducts: updatedList,
          currentPage: nextPage,
          hasMore: distinctNew.isNotEmpty && newProducts.length >= _pageSize,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ Error loading more products: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onProductRefreshRequested(
    ProductRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    add(const ProductLoadRequested());
  }

  void _onProductCategorySelected(
    ProductCategorySelected event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onProductSearchChanged(
    ProductSearchChanged event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onProductSortChanged(
    ProductSortChanged event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(sortOption: event.sortOption));
  }

  void _onProductPriceFilterChanged(
    ProductPriceFilterChanged event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(maxPriceFilter: event.maxPrice));
  }

  void _onProductRatingFilterChanged(
    ProductRatingFilterChanged event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(minRatingFilter: event.minRating));
  }

  void _onProductFiltersReset(
    ProductFiltersReset event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      selectedCategory: 'All',
      searchQuery: '',
      sortOption: SortOption.featured,
      maxPriceFilter: 1000.0,
      minRatingFilter: 0.0,
    ));
  }

  void _onProductAddReviewRequested(
    ProductAddReviewRequested event,
    Emitter<ProductState> emit,
  ) {
    final index = state.allProducts.indexWhere((p) => p.id == event.productId);
    if (index >= 0) {
      final oldProduct = state.allProducts[index];
      final updatedReviews = [event.review, ...oldProduct.reviews];
      final totalStars = updatedReviews.fold(0.0, (sum, r) => sum + r.rating);
      final newAverage = double.parse((totalStars / updatedReviews.length).toStringAsFixed(1));

      final updatedProduct = oldProduct.copyWith(
        reviews: updatedReviews,
        rating: newAverage,
        ratingCount: updatedReviews.length,
      );

      final updatedList = List<ProductEntity>.from(state.allProducts);
      updatedList[index] = updatedProduct;

      emit(state.copyWith(allProducts: updatedList));
    }
  }
}
