// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: (json['subtotal'] as num).toDouble(),
  discount: (json['discount'] as num).toDouble(),
  shipping: (json['shipping'] as num).toDouble(),
  tax: (json['tax'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  deliveryAddress: json['deliveryAddress'] as String,
  paymentMethod: json['paymentMethod'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  trackingNumber: json['trackingNumber'] as String,
  estimatedDelivery: json['estimatedDelivery'] as String,
  isPaid: json['isPaid'] as bool? ?? false,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  isDelivered: json['isDelivered'] as bool? ?? false,
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
  recipientName: json['recipientName'] as String?,
  recipientPhone: json['recipientPhone'] as String?,
  city: json['city'] as String?,
  street: json['street'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': instance.subtotal,
      'discount': instance.discount,
      'shipping': instance.shipping,
      'tax': instance.tax,
      'total': instance.total,
      'deliveryAddress': instance.deliveryAddress,
      'paymentMethod': instance.paymentMethod,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'trackingNumber': instance.trackingNumber,
      'estimatedDelivery': instance.estimatedDelivery,
      'isPaid': instance.isPaid,
      'paidAt': instance.paidAt?.toIso8601String(),
      'isDelivered': instance.isDelivered,
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'recipientName': instance.recipientName,
      'recipientPhone': instance.recipientPhone,
      'city': instance.city,
      'street': instance.street,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.placed: 'placed',
  OrderStatus.processing: 'processing',
  OrderStatus.shipped: 'shipped',
  OrderStatus.outForDelivery: 'outForDelivery',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};
