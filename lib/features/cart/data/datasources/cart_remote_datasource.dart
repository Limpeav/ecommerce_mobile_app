import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/models/product.dart';

abstract class CartRemoteDataSource {
  Future<List<CartItem>?> fetchCart({String? authToken});
  Future<bool> addToCart({
    required String productId,
    int quantity = 1,
    String? color,
    String? size,
    String? authToken,
  });
  Future<bool> updateCartQuantity(
    String productId,
    int quantity, {
    String? authToken,
  });
  Future<bool> removeFromCart(String productId, {String? authToken});
  Future<bool> clearCart({String? authToken});
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final http.Client? client;

  CartRemoteDataSourceImpl({this.client});

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
  Future<List<CartItem>?> fetchCart({String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) return null;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client
          .get(Uri.parse(ApiConstants.cart), headers: headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = (data is List)
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : (data is Map<String, dynamic> && data['items'] is List)
                    ? data['items'] as List
                    : (data is Map<String, dynamic> &&
                            data['cart'] is Map<String, dynamic> &&
                            data['cart']['items'] is List)
                        ? data['cart']['items'] as List
                        : [];

        final List<CartItem> cartItems = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              if (item['product'] is Map<String, dynamic>) {
                cartItems.add(CartItem.fromJson(item));
              } else {
                final prodId = (item['product'] ?? item['_id'] ?? item['id'] ?? '').toString();
                final title = (item['name'] ?? item['title'] ?? 'Product').toString();
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final image = (item['image'] ?? item['photo'] ?? '').toString();
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                final color = (item['color'] ?? 'Default').toString();
                final size = (item['size'] ?? 'Standard').toString();

                final fallbackProd = Product(
                  id: prodId,
                  title: title,
                  price: price,
                  description: '',
                  category: 'General',
                  image: image.isNotEmpty
                      ? image
                      : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
                  images: image.isNotEmpty ? [image] : [],
                  availableColors: [color],
                  availableSizes: [size],
                  reviews: const [],
                );

                cartItems.add(CartItem(
                  product: fallbackProd,
                  quantity: qty,
                  selectedColor: color,
                  selectedSize: size,
                ));
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing cart item: $e');
            }
          }
        }
        return cartItems;
      }
    } catch (e) {
      debugPrint('⚠️ CartRemoteDataSource.fetchCart error: $e');
    }
    return null;
  }

  @override
  Future<bool> addToCart({
    required String productId,
    int quantity = 1,
    String? color,
    String? size,
    String? authToken,
  }) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'productId': productId,
        'quantity': quantity,
        'color': color ?? 'Default',
        'size': size ?? 'Standard',
      });

      final response = await _client
          .post(Uri.parse(ApiConstants.cart), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ CartRemoteDataSource.addToCart error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateCartQuantity(
    String productId,
    int quantity, {
    String? authToken,
  }) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'productId': productId,
        'quantity': quantity,
      });

      final response = await _client
          .put(Uri.parse(ApiConstants.cart), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ CartRemoteDataSource.updateCartQuantity error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromCart(String productId, {String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final url = '${ApiConstants.cart}/$productId';
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ CartRemoteDataSource.removeFromCart error: $e');
      return false;
    }
  }

  @override
  Future<bool> clearCart({String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client
          .delete(Uri.parse(ApiConstants.cart), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ CartRemoteDataSource.clearCart error: $e');
      return false;
    }
  }
}
