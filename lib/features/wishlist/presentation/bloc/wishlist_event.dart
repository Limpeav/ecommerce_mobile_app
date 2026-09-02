import 'package:equatable/equatable.dart';
import '../../../../core/models/product.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class WishlistLoadedFromStorage extends WishlistEvent {
  const WishlistLoadedFromStorage();
}

class WishlistRemoteFetchRequested extends WishlistEvent {
  final String? authToken;

  const WishlistRemoteFetchRequested({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class WishlistToggleRequested extends WishlistEvent {
  final Product product;
  final String? authToken;

  const WishlistToggleRequested({
    required this.product,
    this.authToken,
  });

  @override
  List<Object?> get props => [product, authToken];
}

class WishlistRemoveRequested extends WishlistEvent {
  final String productId;
  final String? authToken;

  const WishlistRemoveRequested({
    required this.productId,
    this.authToken,
  });

  @override
  List<Object?> get props => [productId, authToken];
}
