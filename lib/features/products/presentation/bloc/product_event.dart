import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

enum SortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
}

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductLoadRequested extends ProductEvent {
  const ProductLoadRequested();
}

class ProductLoadMoreRequested extends ProductEvent {
  const ProductLoadMoreRequested();
}

class ProductRefreshRequested extends ProductEvent {
  const ProductRefreshRequested();
}

class ProductCategorySelected extends ProductEvent {
  final String category;

  const ProductCategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

class ProductSearchChanged extends ProductEvent {
  final String query;

  const ProductSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ProductSortChanged extends ProductEvent {
  final SortOption sortOption;

  const ProductSortChanged(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

class ProductPriceFilterChanged extends ProductEvent {
  final double maxPrice;

  const ProductPriceFilterChanged(this.maxPrice);

  @override
  List<Object?> get props => [maxPrice];
}

class ProductRatingFilterChanged extends ProductEvent {
  final double minRating;

  const ProductRatingFilterChanged(this.minRating);

  @override
  List<Object?> get props => [minRating];
}

class ProductFiltersReset extends ProductEvent {
  const ProductFiltersReset();
}

class ProductAddReviewRequested extends ProductEvent {
  final String productId;
  final ProductReviewEntity review;

  const ProductAddReviewRequested({
    required this.productId,
    required this.review,
  });

  @override
  List<Object?> get props => [productId, review];
}
