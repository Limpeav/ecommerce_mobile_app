import 'package:equatable/equatable.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/models/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartLoadedFromStorage extends CartEvent {
  const CartLoadedFromStorage();
}

class CartRemoteFetchRequested extends CartEvent {
  final String? authToken;

  const CartRemoteFetchRequested({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class CartItemAdded extends CartEvent {
  final Product product;
  final int quantity;
  final String? color;
  final String? size;
  final String? authToken;

  const CartItemAdded({
    required this.product,
    this.quantity = 1,
    this.color,
    this.size,
    this.authToken,
  });

  @override
  List<Object?> get props => [product, quantity, color, size, authToken];
}

class CartItemQuantityUpdated extends CartEvent {
  final CartItem item;
  final int newQuantity;
  final String? authToken;

  const CartItemQuantityUpdated({
    required this.item,
    required this.newQuantity,
    this.authToken,
  });

  @override
  List<Object?> get props => [item, newQuantity, authToken];
}

class CartItemRemoved extends CartEvent {
  final CartItem item;
  final String? authToken;

  const CartItemRemoved({
    required this.item,
    this.authToken,
  });

  @override
  List<Object?> get props => [item, authToken];
}

class CartCleared extends CartEvent {
  final String? authToken;

  const CartCleared({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class CartPromoCodeApplied extends CartEvent {
  final String code;

  const CartPromoCodeApplied(this.code);

  @override
  List<Object?> get props => [code];
}

class CartPromoCodeRemoved extends CartEvent {
  const CartPromoCodeRemoved();
}

class CartFinancialSettingsUpdated extends CartEvent {
  final double shippingFee;
  final double taxRate;
  final double freeShippingThreshold;

  const CartFinancialSettingsUpdated({
    required this.shippingFee,
    required this.taxRate,
    this.freeShippingThreshold = 150.0,
  });

  @override
  List<Object?> get props => [shippingFee, taxRate, freeShippingThreshold];
}
