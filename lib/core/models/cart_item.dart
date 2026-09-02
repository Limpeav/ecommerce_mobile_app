import 'package:json_annotation/json_annotation.dart';
import '../../features/products/data/models/product_model.dart';
import 'product.dart';

part 'cart_item.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItem {
  @JsonKey(
    fromJson: _productFromJson,
    toJson: _productToJson,
  )
  final Product product;
  @JsonKey(defaultValue: 1)
  int quantity;
  @JsonKey(defaultValue: 'Default')
  String selectedColor;
  @JsonKey(defaultValue: 'Standard')
  String selectedSize;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedColor = 'Default',
    this.selectedSize = 'Standard',
  });

  static Product _productFromJson(Map<String, dynamic> json) =>
      ProductModel.fromJson(json);

  static Map<String, dynamic> _productToJson(Product product) =>
      ProductModel.fromEntity(product).toJson();

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}
