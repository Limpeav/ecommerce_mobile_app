import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class PendingReviewItem {
  final String orderId;
  final String productId;
  final String productTitle;
  final String productImage;
  final DateTime deliveredAt;
  final DateTime createdAt;

  const PendingReviewItem({
    required this.orderId,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.deliveredAt,
    required this.createdAt,
  });

  String get key => '$orderId::$productId';

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'deliveredAt': deliveredAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PendingReviewItem.fromJson(Map<String, dynamic> json) {
    return PendingReviewItem(
      orderId: (json['orderId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productTitle: (json['productTitle'] ?? 'Product').toString(),
      productImage: (json['productImage'] ?? '').toString(),
      deliveredAt: DateTime.tryParse((json['deliveredAt'] ?? '').toString()) ??
          DateTime.now(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ReviewRequirementService {
  static const String _pendingKey = 'required_product_reviews_pending_v1';
  static const String _ratedKey = 'required_product_reviews_rated_v1';

  static Future<List<PendingReviewItem>> getPendingReviewItems() async {
    final prefs = await SharedPreferences.getInstance();
    return _readPending(prefs);
  }

  static Future<bool> hasPendingReviews() async {
    final pending = await getPendingReviewItems();
    return pending.isNotEmpty;
  }

  static Future<List<PendingReviewItem>> registerDeliveredOrders(
    List<OrderModel> orders,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _readPending(prefs);
    final pendingKeys = pending.map((item) => item.key).toSet();
    final ratedKeys = prefs.getStringList(_ratedKey)?.toSet() ?? <String>{};
    final newlyRequired = <PendingReviewItem>[];
    final now = DateTime.now();

    for (final order in orders) {
      final isDelivered = order.status == OrderStatus.delivered ||
          order.isDelivered ||
          order.deliveredAt != null;
      if (!isDelivered) continue;

      final productIdsInOrder = <String>{};
      for (final item in order.items) {
        final product = item.product;
        if (product.id.trim().isEmpty || !productIdsInOrder.add(product.id)) {
          continue;
        }

        final pendingItem = PendingReviewItem(
          orderId: order.id,
          productId: product.id,
          productTitle: product.title,
          productImage: product.image,
          deliveredAt: order.deliveredAt ?? now,
          createdAt: now,
        );

        if (pendingKeys.contains(pendingItem.key) ||
            ratedKeys.contains(pendingItem.key)) {
          continue;
        }

        pending.add(pendingItem);
        pendingKeys.add(pendingItem.key);
        newlyRequired.add(pendingItem);
      }
    }

    if (newlyRequired.isNotEmpty) {
      await _writePending(prefs, pending);
    }

    return newlyRequired;
  }

  static Future<void> markRated({
    required String orderId,
    required String productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$orderId::$productId';
    final pending = _readPending(prefs)
        .where((item) => item.key != key)
        .toList(growable: false);
    final ratedKeys = prefs.getStringList(_ratedKey)?.toSet() ?? <String>{};
    ratedKeys.add(key);

    await _writePending(prefs, pending);
    await prefs.setStringList(_ratedKey, ratedKeys.toList());
  }

  static List<PendingReviewItem> _readPending(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_pendingKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingReviewItem.fromJson)
          .where((item) => item.orderId.isNotEmpty && item.productId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error reading pending required reviews: $e');
      return [];
    }
  }

  static Future<void> _writePending(
    SharedPreferences prefs,
    List<PendingReviewItem> pending,
  ) async {
    await prefs.setString(
      _pendingKey,
      json.encode(pending.map((item) => item.toJson()).toList()),
    );
  }
}
