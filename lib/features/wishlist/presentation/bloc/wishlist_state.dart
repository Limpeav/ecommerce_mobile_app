import 'package:equatable/equatable.dart';
import '../../../../core/models/product.dart';

class WishlistState extends Equatable {
  final List<Product> items;
  final Set<String> favoriteProductIds;
  final bool isLoading;

  const WishlistState({
    this.items = const [],
    this.favoriteProductIds = const {},
    this.isLoading = false,
  });

  int get count => items.length;

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);

  WishlistState copyWith({
    List<Product>? items,
    Set<String>? favoriteProductIds,
    bool? isLoading,
  }) {
    return WishlistState(
      items: items ?? this.items,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, favoriteProductIds, isLoading];
}
