// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  product: CartItem._productFromJson(json['product'] as Map<String, dynamic>),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  selectedColor: json['selectedColor'] as String? ?? 'Default',
  selectedSize: json['selectedSize'] as String? ?? 'Standard',
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'product': CartItem._productToJson(instance.product),
  'quantity': instance.quantity,
  'selectedColor': instance.selectedColor,
  'selectedSize': instance.selectedSize,
};
