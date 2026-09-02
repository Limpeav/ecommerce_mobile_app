enum NotificationType {
  order,
  promo,
  flashSale,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.order:
        return 'Orders';
      case NotificationType.promo:
        return 'Promotions';
      case NotificationType.flashSale:
        return 'Flash Sales';
      case NotificationType.system:
        return 'System';
    }
  }

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'order':
      case 'orders':
        return NotificationType.order;
      case 'promo':
      case 'promotion':
      case 'promotions':
      case 'discount':
        return NotificationType.promo;
      case 'flashsale':
      case 'flash_sale':
      case 'sale':
        return NotificationType.flashSale;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? orderId;
  final String? orderNumber;
  final String? productId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.orderNumber,
    this.productId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? orderId,
    String? orderNumber,
    String? productId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      productId: productId ?? this.productId,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      orderId: json['orderId']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      productId: json['productId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'productId': productId,
      };
}
