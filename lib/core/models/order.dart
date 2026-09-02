import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'cart_item.dart';
import 'product.dart';

part 'order.g.dart';

enum OrderStatus {
  placed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.processing:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.processing;
    final clean = val.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
    switch (clean) {
      case 'placed':
      case 'pending':
      case 'created':
        return OrderStatus.placed;
      case 'processing':
      case 'confirmed':
      case 'packing':
        return OrderStatus.processing;
      case 'shipped':
      case 'intransit':
      case 'transit':
        return OrderStatus.shipped;
      case 'outfordelivery':
      case 'delivering':
        return OrderStatus.outForDelivery;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.processing;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class OrderModel {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;
  final String deliveryAddress;
  final String paymentMethod;
  final OrderStatus status;
  final String trackingNumber;
  final String estimatedDelivery;
  final bool isPaid;
  final DateTime? paidAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final String? recipientName;
  final String? recipientPhone;
  final String? city;
  final String? street;
  final double? latitude;
  final double? longitude;

  OrderModel({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.trackingNumber,
    required this.estimatedDelivery,
    this.isPaid = false,
    this.paidAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.recipientName,
    this.recipientPhone,
    this.city,
    this.street,
    this.latitude,
    this.longitude,
  });

  OrderModel copyWith({
    String? id,
    DateTime? date,
    List<CartItem>? items,
    double? subtotal,
    double? discount,
    double? shipping,
    double? tax,
    double? total,
    String? deliveryAddress,
    String? paymentMethod,
    OrderStatus? status,
    String? trackingNumber,
    String? estimatedDelivery,
    bool? isPaid,
    DateTime? paidAt,
    bool? isDelivered,
    DateTime? deliveredAt,
    String? recipientName,
    String? recipientPhone,
    String? city,
    String? street,
    double? latitude,
    double? longitude,
  }) {
    return OrderModel(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      city: city ?? this.city,
      street: street ?? this.street,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Clean display order code (e.g., 'D5C113D9' or 'ORD-123456')
  String get displayOrderCode {
    final clean = id.replaceAll('#', '').trim();
    if (clean.startsWith('ORD-') && clean.length > 4) {
      return clean.substring(4);
    }
    if (clean.length > 8 && !clean.contains('-')) {
      return clean.substring(clean.length - 8).toUpperCase();
    }
    return clean;
  }

  /// Maps frontend display payment name to backend Mongoose enum value ("BAKONG_KHQR" or "Cash on Delivery")
  String get backendPaymentMethod {
    final clean = paymentMethod.trim().toUpperCase().replaceAll(' ', '_');
    if (clean.contains('BAKONG') || clean.contains('KHQR')) {
      return 'BAKONG_KHQR';
    }
    return 'Cash on Delivery';
  }

  Map<String, dynamic> toJson() {
    final nameVal = recipientName ?? (deliveryAddress.split(',').isNotEmpty ? deliveryAddress.split(',')[0].trim() : 'Customer');
    final phoneVal = recipientPhone ?? '016568335';
    final streetVal = street?.isNotEmpty == true ? street! : deliveryAddress;
    final cityVal = city?.isNotEmpty == true ? city! : 'Phnom Penh';

    final jsonMap = _$OrderModelToJson(this);
    jsonMap.addAll({
      '_id': id,
      'createdAt': date.toIso8601String(),
      'orderItems': items.map((i) => {
        'name': i.product.title,
        'title': i.product.title,
        'quantity': i.quantity,
        'qty': i.quantity,
        'price': i.product.price,
        'image': i.product.image,
        'selectedColor': i.selectedColor,
        'selectedSize': i.selectedSize,
        'product': i.product.id,
      }).toList(),
      'itemsPrice': subtotal,
      'discountAmount': discount,
      'shippingPrice': shipping,
      'deliveryFee': shipping,
      'taxPrice': tax,
      'totalPrice': total,
      'shippingAddress': {
        'fullName': nameVal,
        'phone': phoneVal,
        'address': streetVal,
        'street': streetVal,
        'city': cityVal,
        'country': 'Cambodia',
        'postalCode': '12000',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
      'paymentMethod': backendPaymentMethod,
      'orderNumber': trackingNumber,
    });
    return jsonMap;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Status
    final statusRaw = (json['status'] ?? json['orderStatus'] ?? 'processing').toString();
    final parsedStatus = OrderStatusExtension.fromString(statusRaw);

    // 2. Parse Items (supports both MongoDB 'orderItems' populated objects and flat maps)
    final List<CartItem> parsedItems = [];
    final rawItems = json['orderItems'] ?? json['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          try {
            final prodMap = raw['product'] is Map<String, dynamic>
                ? raw['product'] as Map<String, dynamic>
                : null;

            final prodId = (prodMap?['_id'] ?? prodMap?['id'] ?? raw['product'] ?? raw['_id'] ?? raw['id'] ?? 'item_${raw.hashCode}').toString();
            final title = (raw['name'] ?? raw['title'] ?? prodMap?['title'] ?? prodMap?['name'] ?? 'Product').toString();
            final price = (raw['price'] as num?)?.toDouble() ?? (prodMap?['price'] as num?)?.toDouble() ?? 0.0;
            final image = (raw['image'] ?? raw['photo'] ?? prodMap?['image'] ?? prodMap?['photo'] ?? '').toString();
            final qty = (raw['quantity'] ?? raw['qty'] as num?)?.toInt() ?? 1;
            final color = (raw['color'] ?? raw['selectedColor'] ?? 'Default').toString();
            final size = (raw['size'] ?? raw['selectedSize'] ?? 'Standard').toString();

            final product = Product(
              id: prodId,
              title: title,
              price: price,
              description: '',
              category: 'Clothing',
              image: image,
              images: image.isNotEmpty ? [image] : [],
              availableColors: [color],
              availableSizes: [size],
              reviews: [],
            );

            parsedItems.add(CartItem(
              product: product,
              quantity: qty,
              selectedColor: color,
              selectedSize: size,
            ));
          } catch (e) {
            debugPrint('⚠️ Error parsing order item: $e');
          }
        }
      }
    }

    // 3. Parse Shipping / Delivery Address & Coordinates
    String parsedAddress = '';
    String? recName;
    String? recPhone;
    String? recCity;
    String? recStreet;
    double? lat;
    double? lng;

    if (json['shippingAddress'] is Map<String, dynamic>) {
      final sa = json['shippingAddress'] as Map<String, dynamic>;
      recName = (sa['fullName'] ?? sa['name'])?.toString();
      recPhone = (sa['phone'] ?? sa['phoneNumber'])?.toString();
      recStreet = (sa['address'] ?? sa['street'])?.toString();
      recCity = sa['city']?.toString();
      lat = (sa['latitude'] as num?)?.toDouble();
      lng = (sa['longitude'] as num?)?.toDouble();
      parsedAddress = [
        recName,
        recStreet,
        recCity,
        recPhone,
      ].where((p) => p != null && p.toString().isNotEmpty).join(', ');
    } else if (json['deliveryAddress'] != null && json['deliveryAddress'].toString().isNotEmpty) {
      parsedAddress = json['deliveryAddress'].toString();
    } else if (json['shippingAddress'] is String) {
      parsedAddress = json['shippingAddress'].toString();
    }

    if (lat == null && json['latitude'] is num) {
      lat = (json['latitude'] as num).toDouble();
    }
    if (lng == null && json['longitude'] is num) {
      lng = (json['longitude'] as num).toDouble();
    }

    // 4. Parse Amounts
    final subtotalVal = (json['itemsPrice'] ?? json['subtotal'] as num?)?.toDouble() ?? 0.0;
    final discountVal = (json['discountAmount'] ?? json['discount'] as num?)?.toDouble() ?? 0.0;
    final shippingVal = (json['shippingPrice'] ?? json['deliveryFee'] ?? json['shipping'] as num?)?.toDouble() ?? 0.0;
    final taxVal = (json['taxPrice'] ?? json['tax'] as num?)?.toDouble() ?? 0.0;
    final totalVal = (json['totalPrice'] ?? json['total'] as num?)?.toDouble() ?? (subtotalVal - discountVal + shippingVal + taxVal);

    // 5. Parse Dates
    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    }

    // 6. Parse ID & Tracking
    final idVal = (json['_id'] ?? json['id'] ?? json['orderNumber'] ?? '#ORD-${DateTime.now().millisecondsSinceEpoch}').toString();
    final trackingVal = (json['orderNumber'] ?? json['trackingNumber'] ?? json['trackingCode'] ?? 'EXP-${idVal.length > 8 ? idVal.substring(idVal.length - 8).toUpperCase() : idVal}').toString();

    // 7. Parse Payment Method & Delivery info
    final rawMethod = (json['paymentMethod'] ?? 'Cash on Delivery').toString();
    final displayMethod = (rawMethod == 'BAKONG_KHQR' || rawMethod == 'KHQR' || rawMethod == 'BAKONG')
        ? 'Bakong KHQR'
        : 'Cash on Delivery';

    final estDelivery = (json['estimatedDelivery'] ?? '3-5 Business Days').toString();
    final isPaid = json['isPaid'] == true;
    final isDelivered = json['isDelivered'] == true;
    final paidAt = json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null;
    final deliveredAt = json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'].toString()) : null;

    final normalized = <String, dynamic>{
      'id': idVal,
      'date': parsedDate.toIso8601String(),
      'items': parsedItems.map((i) => i.toJson()).toList(),
      'subtotal': subtotalVal,
      'discount': discountVal,
      'shipping': shippingVal,
      'tax': taxVal,
      'total': totalVal,
      'deliveryAddress': parsedAddress.isNotEmpty ? parsedAddress : 'Standard Delivery',
      'paymentMethod': displayMethod,
      'status': parsedStatus.name,
      'trackingNumber': trackingVal,
      'estimatedDelivery': estDelivery,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'recipientName': recName,
      'recipientPhone': recPhone,
      'city': recCity,
      'street': recStreet,
      'latitude': lat,
      'longitude': lng,
    };

    return _$OrderModelFromJson(normalized);
  }
}
