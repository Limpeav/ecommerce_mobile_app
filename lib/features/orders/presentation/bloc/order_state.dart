import 'package:equatable/equatable.dart';
import '../../../../core/models/order.dart';
import '../../../../core/services/review_requirement_service.dart';

class OrderState extends Equatable {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final OrderModel? lastPlacedOrder;
  final List<PendingReviewItem> pendingReviewItems;
  final PendingReviewItem? deliveryReviewPrompt;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastPlacedOrder,
    this.pendingReviewItems = const [],
    this.deliveryReviewPrompt,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? errorMessage,
    OrderModel? lastPlacedOrder,
    List<PendingReviewItem>? pendingReviewItems,
    PendingReviewItem? deliveryReviewPrompt,
    bool clearError = false,
    bool clearDeliveryReviewPrompt = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastPlacedOrder: lastPlacedOrder ?? this.lastPlacedOrder,
      pendingReviewItems: pendingReviewItems ?? this.pendingReviewItems,
      deliveryReviewPrompt: clearDeliveryReviewPrompt
          ? null
          : (deliveryReviewPrompt ?? this.deliveryReviewPrompt),
    );
  }

  @override
  List<Object?> get props => [
        orders,
        isLoading,
        errorMessage,
        lastPlacedOrder,
        pendingReviewItems,
        deliveryReviewPrompt,
      ];
}
