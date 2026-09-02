import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/order.dart';

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

abstract class OrderRemoteDataSource {
  Future<CreateOrderResult> createOrder({
    required OrderModel order,
    String? authToken,
  });
  Future<List<OrderModel>?> fetchMyOrders({String? authToken});
  Future<OrderModel?> trackOrder(String orderIdOrNumber, {String? authToken});
  Future<bool> markOrderAsPaid(
    String orderId, {
    String? authToken,
    Map<String, dynamic>? paymentResult,
  });
  Future<bool> cancelOrder(String orderId, {String? authToken});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final http.Client? client;

  OrderRemoteDataSourceImpl({this.client});

  http.Client get _client => client ?? http.Client();

  Future<String?> _getUserAuthToken() async {
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

  @override
  Future<CreateOrderResult> createOrder({
    required OrderModel order,
    String? authToken,
  }) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ OrderRemoteDataSource: No auth token found.');
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

      final backendItems = order.items.map((i) {
        return {
          'product': i.product.id,
          'name': i.product.title,
          'image': i.product.image,
          'price': i.product.price,
          'quantity': i.quantity,
          'color': i.selectedColor,
          'size': i.selectedSize,
        };
      }).toList();

      final body = json.encode({
        'orderItems': backendItems,
        'shippingAddress': {
          'name': nameVal,
          'phone': phoneVal,
          'street': streetVal,
          'city': cityVal,
          'latitude': order.latitude,
          'longitude': order.longitude,
        },
        'paymentMethod': order.paymentMethod,
        'itemsPrice': order.subtotal,
        'taxPrice': order.tax,
        'shippingPrice': order.shipping,
        'totalPrice': order.total,
        'isPaid': order.isPaid,
      });

      final response = await _client
          .post(Uri.parse(ApiConstants.orders), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final orderData = (data is Map<String, dynamic> && data['order'] != null)
            ? data['order']
            : (data is Map<String, dynamic> && data['data'] != null)
                ? data['data']
                : data;

        if (orderData is Map<String, dynamic>) {
          return CreateOrderResult(
            success: true,
            statusCode: response.statusCode,
            order: OrderModel.fromJson(orderData),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ OrderRemoteDataSource.createOrder error: $e');
    }
    return const CreateOrderResult(success: false);
  }

  @override
  Future<List<OrderModel>?> fetchMyOrders({String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return null;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client
          .get(Uri.parse(ApiConstants.myOrders), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = (data is List)
            ? data
            : (data is Map<String, dynamic> && data['orders'] is List)
                ? data['orders'] as List
                : (data is Map<String, dynamic> && data['data'] is List)
                    ? data['data'] as List
                    : [];

        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => OrderModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ OrderRemoteDataSource.fetchMyOrders error: $e');
    }
    return null;
  }

  @override
  Future<OrderModel?> trackOrder(String orderIdOrNumber, {String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final cleanParam = Uri.encodeComponent(orderIdOrNumber.replaceFirst('#', ''));
      final url = '${ApiConstants.orders}/track/$cleanParam';

      final response = await _client.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final orderData = (data is Map<String, dynamic> && data['order'] != null)
            ? data['order']
            : (data is Map<String, dynamic> && data['data'] != null)
                ? data['data']
                : data;

        if (orderData is Map<String, dynamic>) {
          return OrderModel.fromJson(orderData);
        }
      }
    } catch (e) {
      debugPrint('⚠️ OrderRemoteDataSource.trackOrder error: $e');
    }
    return null;
  }

  @override
  Future<bool> markOrderAsPaid(
    String orderId, {
    String? authToken,
    Map<String, dynamic>? paymentResult,
  }) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final cleanId = orderId.replaceFirst('#', '');
      final url = '${ApiConstants.orders}/$cleanId/pay';
      final body = json.encode({
        'id': paymentResult?['id'] ?? 'KHQR_TXN_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'COMPLETED',
        'update_time': DateTime.now().toIso8601String(),
        'email_address': paymentResult?['email'] ?? 'customer@bakong.kh',
        'paymentResult': paymentResult,
      });

      final response = await _client
          .put(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 12));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ OrderRemoteDataSource.markOrderAsPaid error: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelOrder(String orderId, {String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final cleanId = orderId.replaceFirst('#', '');
      final url = '${ApiConstants.orders}/$cleanId/cancel';

      final response = await _client
          .put(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 12));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ OrderRemoteDataSource.cancelOrder error: $e');
      return false;
    }
  }
}
