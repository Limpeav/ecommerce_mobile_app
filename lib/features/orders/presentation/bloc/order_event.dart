import 'package:equatable/equatable.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/models/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderLoadedFromStorage extends OrderEvent {
  const OrderLoadedFromStorage();
}

class OrderFetchRequested extends OrderEvent {
  final String? authToken;

  const OrderFetchRequested({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class OrderPlaced extends OrderEvent {
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;
  final String deliveryAddress;
  final String paymentMethod;
  final String? recipientName;
  final String? recipientPhone;
  final String? city;
  final String? street;
  final double? latitude;
  final double? longitude;
  final String? authToken;
  final double exchangeRate;
  final void Function(OrderModel order)? onComplete;

  const OrderPlaced({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.recipientName,
    this.recipientPhone,
    this.city,
    this.street,
    this.latitude,
    this.longitude,
    this.authToken,
    this.exchangeRate = 4100.0,
    this.onComplete,
  });

  @override
  List<Object?> get props => [
        items,
        subtotal,
        discount,
        shipping,
        tax,
        total,
        deliveryAddress,
        paymentMethod,
        recipientName,
        recipientPhone,
        city,
        street,
        latitude,
        longitude,
        authToken,
        exchangeRate,
      ];
}

class OrderMarkedAsPaid extends OrderEvent {
  final String orderId;
  final String? authToken;
  final Map<String, dynamic>? paymentResult;
  final double exchangeRate;

  const OrderMarkedAsPaid({
    required this.orderId,
    this.authToken,
    this.paymentResult,
    this.exchangeRate = 4100.0,
  });

  @override
  List<Object?> get props => [orderId, authToken, paymentResult, exchangeRate];
}

class OrderTrackRequested extends OrderEvent {
  final String orderIdOrNumber;
  final String? authToken;
  final void Function(OrderModel? order)? onResult;

  const OrderTrackRequested({
    required this.orderIdOrNumber,
    this.authToken,
    this.onResult,
  });

  @override
  List<Object?> get props => [orderIdOrNumber, authToken];
}

class OrderCancelled extends OrderEvent {
  final String orderId;
  final String? authToken;

  const OrderCancelled({
    required this.orderId,
    this.authToken,
  });

  @override
  List<Object?> get props => [orderId, authToken];
}

class OrderCleared extends OrderEvent {
  const OrderCleared();
}

class OrderPendingReviewsRefreshed extends OrderEvent {
  const OrderPendingReviewsRefreshed();
}

class OrderDeliveryReviewPromptCleared extends OrderEvent {
  const OrderDeliveryReviewPromptCleared();
}
