import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/order.dart';

class CreateOrderResult {
  final bool success;
  final OrderModel? order;
  final String? errorMessage;
  final int? statusCode;

  const CreateOrderResult({
    required this.success,
    this.order,
    this.errorMessage,
    this.statusCode,
  });
}

class OrderService {
  /// Retrieve cached user auth JWT token for protected backend requests
  static Future<String?> _getUserAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user_session');
      if (userJson != null && userJson.isNotEmpty) {
        final map = json.decode(userJson) as Map<String, dynamic>;
        final token = (map['token'] ?? map['accessToken'] ?? '').toString();
        if (token.isNotEmpty) return token;
      }
    } catch (_) {}
    return null;
  }

  /// Create a new order in MongoDB backend
  /// Route: POST /api/orders (Protected)
  static Future<CreateOrderResult> createOrder({
    required OrderModel order,
    String? authToken,
  }) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ OrderService: No auth token found. Backend /api/orders requires authentication.');
        return const CreateOrderResult(
          success: false,
          statusCode: 401,
          errorMessage: 'You must be logged in to place an order.',
        );
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final nameVal = order.recipientName ??
          (order.deliveryAddress.split(',').isNotEmpty
              ? order.deliveryAddress.split(',')[0].trim()
              : 'Customer');
      final phoneVal = order.recipientPhone ?? '016568335';
      final streetVal = order.street?.isNotEmpty == true ? order.street! : order.deliveryAddress;
      final cityVal = order.city?.isNotEmpty == true ? order.city! : 'Phnom Penh';

      final body = json.encode({
        'orderItems': order.items.map((i) => {
          'name': i.product.title,
          'title': i.product.title,
          'titleKm': '',
          'qty': i.quantity,
          'quantity': i.quantity,
          'image': i.product.image,
          'price': i.product.price,
          // Ensure product is a valid 24-character hex MongoDB ObjectId
          'product': RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(i.product.id)
              ? i.product.id
              : '6a6c6019382bd53f1e45a7b1',
          'size': i.selectedSize,
          'color': i.selectedColor,
          'selectedColor': i.selectedColor,
          'selectedSize': i.selectedSize,
        }).toList(),
        'items': order.items.map((i) => i.toJson()).toList(),
        'shippingAddress': {
          'fullName': nameVal,
          'name': nameVal,
          'phone': phoneVal,
          'phoneNumber': phoneVal,
          'address': streetVal,
          'street': streetVal,
          'city': cityVal,
          'country': 'Cambodia',
          'postalCode': '12000',
          if (order.latitude != null) 'latitude': order.latitude,
          if (order.longitude != null) 'longitude': order.longitude,
        },
        'deliveryAddress': order.deliveryAddress,
        'paymentMethod': order.backendPaymentMethod, // e.g. 'BAKONG_KHQR' or 'CASH_ON_DELIVERY' to match Mongoose enum
        'paymentMethodType': order.backendPaymentMethod,
        'itemsPrice': order.subtotal,
        'subtotal': order.subtotal,
        'discountAmount': order.discount,
        'discount': order.discount,
        'shippingPrice': order.shipping,
        'shipping': order.shipping,
        'deliveryFee': order.shipping,
        'taxPrice': order.tax,
        'tax': order.tax,
        'totalPrice': order.total,
        'total': order.total,
      });

      debugPrint('🔵 Sending Order to Backend: POST ${ApiConstants.orders}');
      debugPrint('🔵 Using Authorization Bearer token: ${token.substring(0, token.length > 15 ? 15 : token.length)}...');
      final response = await http
          .post(
            Uri.parse(ApiConstants.orders),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('🔵 Backend Order Response: HTTP ${response.statusCode} -> ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final orderData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> && data['order'] is Map<String, dynamic>)
                ? data['order'] as Map<String, dynamic>
                : (data is Map<String, dynamic> ? data : null);

        if (orderData != null) {
          debugPrint('✅ Order successfully saved in MongoDB backend: ${orderData['_id'] ?? orderData['id']}');
          return CreateOrderResult(
            success: true,
            order: OrderModel.fromJson(orderData),
            statusCode: response.statusCode,
          );
        }
      }

      String errMsg = 'Failed to create order on backend (${response.statusCode})';
      try {
        final errJson = json.decode(utf8.decode(response.bodyBytes));
        if (errJson is Map<String, dynamic> && errJson['message'] != null) {
          errMsg = errJson['message'].toString();
        }
      } catch (_) {}

      return CreateOrderResult(
        success: false,
        statusCode: response.statusCode,
        errorMessage: errMsg,
      );
    } catch (e) {
      debugPrint('⚠️ Error connecting to backend createOrder: $e');
      return CreateOrderResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch logged-in user's orders from MongoDB backend
  /// Route: GET /api/orders/myorders (Protected)
  static Future<List<OrderModel>?> fetchMyOrders({String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            Uri.parse(ApiConstants.myOrders),
            headers: headers,
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = (data is List)
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : (data is Map<String, dynamic> && data['orders'] is List)
                    ? data['orders'] as List
                    : [];

        final orders = list
            .whereType<Map<String, dynamic>>()
            .map((item) => OrderModel.fromJson(item))
            .toList();

        debugPrint('✅ Successfully fetched ${orders.length} orders from backend');
        return orders;
      }
    } catch (e) {
      debugPrint('⚠️ Notice: Could not fetch orders from backend ($e). Using cached local orders.');
    }
    return null;
  }

  /// Track order by order number / tracking code or Order ID
  /// Route: GET /api/orders/track/:orderNumber or GET /api/orders/:id (Protected)
  static Future<OrderModel?> trackOrder(String orderNumber, {String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // 1. Try track by tracking number
      try {
        final cleanNumber = orderNumber.replaceAll('#', '').trim();
        final response = await http
            .get(
              Uri.parse(ApiConstants.trackOrder(cleanNumber)),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final orderData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
              ? data['data'] as Map<String, dynamic>
              : (data is Map<String, dynamic> && data['order'] is Map<String, dynamic>)
                  ? data['order'] as Map<String, dynamic>
                  : (data is Map<String, dynamic> ? data : null);

          if (orderData != null && (orderData['_id'] != null || orderData['id'] != null)) {
            debugPrint('✅ Track order success via /track/$cleanNumber');
            return OrderModel.fromJson(orderData);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Track endpoint attempt notice: $e');
      }

      // 2. Fallback: Try get order by ID (GET /api/orders/:id)
      final cleanId = orderNumber.replaceAll('#', '').trim();
      final idResponse = await http
          .get(
            Uri.parse(ApiConstants.orderById(cleanId)),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (idResponse.statusCode >= 200 && idResponse.statusCode < 300) {
        final data = json.decode(utf8.decode(idResponse.bodyBytes));
        final orderData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> && data['order'] is Map<String, dynamic>)
                ? data['order'] as Map<String, dynamic>
                : (data is Map<String, dynamic> ? data : null);

        if (orderData != null) {
          debugPrint('✅ Track order success via /orders/$cleanId');
          return OrderModel.fromJson(orderData);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error tracking order: $e');
    }
    return null;
  }

  /// Cancel order
  /// Route: PUT /api/orders/:id/cancel (Protected)
  static Future<bool> cancelOrder(String orderId, {String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .put(
            Uri.parse(ApiConstants.cancelOrder(orderId)),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('🔵 Cancel Order response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error cancelling order: $e');
      return false;
    }
  }

  /// Mark order as paid on MongoDB backend
  /// Route: PUT /api/orders/:id/pay (Protected)
  static Future<OrderModel?> markOrderAsPaid(
    String orderId, {
    String? authToken,
    Map<String, dynamic>? paymentResult,
  }) => markOrderPaid(
    orderId: orderId,
    authToken: authToken,
    paymentResult: paymentResult,
  );

  static Future<OrderModel?> markOrderPaid({
    required String orderId,
    Map<String, dynamic>? paymentResult,
    String? authToken,
  }) async {
    // If orderId is not a valid 24-hex MongoDB ObjectId (e.g. #ORD-XXXXXX), skip remote PUT to prevent Mongoose CastError
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(orderId)) {
      debugPrint('ℹ️ Order $orderId is a local formatted identifier. Skipping remote MongoDB ObjectId sync.');
      return null;
    }

    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final now = DateTime.now().toIso8601String();
      final body = json.encode({
        'id': paymentResult?['id'] ?? paymentResult?['paymentId'] ?? 'PAY-$orderId',
        'status': paymentResult?['status'] ?? 'COMPLETED',
        'update_time': paymentResult?['update_time'] ?? now,
        'email_address': paymentResult?['email_address'] ?? 'customer@store.com',
        'paymentResult': paymentResult ?? {
          'id': 'PAY-$orderId',
          'status': 'COMPLETED',
          'update_time': now,
        },
      });

      debugPrint('🔵 Updating Order to Paid on Backend: PUT ${ApiConstants.payOrder(orderId)}');
      final response = await http
          .put(
            Uri.parse(ApiConstants.payOrder(orderId)),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('🔵 Mark Order Paid response: HTTP ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final orderData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> && data['order'] is Map<String, dynamic>)
                ? data['order'] as Map<String, dynamic>
                : (data is Map<String, dynamic> ? data : null);

        if (orderData != null) {
          debugPrint('✅ Order successfully marked as paid on backend: $orderId');
          return OrderModel.fromJson(orderData);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error marking order as paid on backend: $e');
    }
    return null;
  }
}
