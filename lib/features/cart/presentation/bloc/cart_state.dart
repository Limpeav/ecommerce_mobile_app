import 'package:equatable/equatable.dart';
import '../../../../core/models/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final String? appliedPromoCode;
  final double discountRate;
  final double flatDiscount;
  final bool freeShippingApplied;
  final bool isLoading;

  // Financial Settings
  final double adminShippingFee;
  final double adminTaxRate;
  final double adminFreeShippingThreshold;

  const CartState({
    this.items = const [],
    this.appliedPromoCode,
    this.discountRate = 0.0,
    this.flatDiscount = 0.0,
    this.freeShippingApplied = false,
    this.isLoading = false,
    this.adminShippingFee = 1.50,
    this.adminTaxRate = 0.08,
    this.adminFreeShippingThreshold = 150.0,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (flatDiscount > 0) return flatDiscount;
    return subtotal * discountRate;
  }

  double get shippingFee {
    if (subtotal == 0 || freeShippingApplied || subtotal > adminFreeShippingThreshold) {
      return 0.0;
    }
    return adminShippingFee;
  }

  double get taxAmount => (subtotal - discountAmount) * adminTaxRate;

  double get total {
    if (subtotal == 0) return 0.0;
    final afterDiscount = (subtotal - discountAmount);
    return (afterDiscount > 0 ? afterDiscount : 0) + shippingFee + taxAmount;
  }

  CartState copyWith({
    List<CartItem>? items,
    String? appliedPromoCode,
    bool clearPromo = false,
    double? discountRate,
    double? flatDiscount,
    bool? freeShippingApplied,
    bool? isLoading,
    double? adminShippingFee,
    double? adminTaxRate,
    double? adminFreeShippingThreshold,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromoCode: clearPromo ? null : (appliedPromoCode ?? this.appliedPromoCode),
      discountRate: discountRate ?? this.discountRate,
      flatDiscount: flatDiscount ?? this.flatDiscount,
      freeShippingApplied: freeShippingApplied ?? this.freeShippingApplied,
      isLoading: isLoading ?? this.isLoading,
      adminShippingFee: adminShippingFee ?? this.adminShippingFee,
      adminTaxRate: adminTaxRate ?? this.adminTaxRate,
      adminFreeShippingThreshold: adminFreeShippingThreshold ?? this.adminFreeShippingThreshold,
    );
  }

  @override
  List<Object?> get props => [
        items,
        appliedPromoCode,
        discountRate,
        flatDiscount,
        freeShippingApplied,
        isLoading,
        adminShippingFee,
        adminTaxRate,
        adminFreeShippingThreshold,
      ];
}
