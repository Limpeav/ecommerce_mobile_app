import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  /// Retrieve cached user auth JWT token
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

  /// Fetch user cart from MongoDB backend
  /// Route: GET /api/cart (Protected)
  static Future<List<CartItem>?> fetchCart({String? authToken}) async {
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

      debugPrint('🔵 Fetching cart from backend: GET ${ApiConstants.cart}');
      final response = await http
          .get(Uri.parse(ApiConstants.cart), headers: headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('🔵 Backend Cart Response: HTTP ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = (data is List)
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : (data is Map<String, dynamic> && data['items'] is List)
                    ? data['items'] as List
                    : (data is Map<String, dynamic> && data['cart'] is Map<String, dynamic> && data['cart']['items'] is List)
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
                final qty = (item['quantity'] ?? item['qty'] as num?)?.toInt() ?? 1;
                final color = (item['selectedColor'] ?? item['color'] ?? 'Default').toString();
                final size = (item['selectedSize'] ?? item['size'] ?? 'Standard').toString();

                final product = Product(
                  id: prodId,
                  title: title,
                  price: price,
                  description: '',
                  category: 'General',
                  image: image,
                  images: image.isNotEmpty ? [image] : [],
                  availableColors: [color],
                  availableSizes: [size],
                  reviews: [],
                );

                cartItems.add(CartItem(
                  product: product,
                  quantity: qty,
                  selectedColor: color,
                  selectedSize: size,
                ));
              }
            } catch (_) {}
          }
        }
        debugPrint('✅ Loaded ${cartItems.length} cart items from backend');
        return cartItems;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching cart: $e');
    }
    return null;
  }

  /// Add a product to cart on backend
  /// Route: POST /api/cart/add (Protected)
  static Future<bool> addToCart({
    required String productId,
    int quantity = 1,
    String? color,
    String? size,
    String? authToken,
  }) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'productId': productId,
        'quantity': quantity,
        'selectedColor': ?color,
        'selectedSize': ?size,
      });

      debugPrint('🔵 Adding to cart on backend: POST ${ApiConstants.addToCart}');
      final response = await http
          .post(Uri.parse(ApiConstants.addToCart), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Add Cart response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error adding to cart: $e');
      return false;
    }
  }

  /// Update item quantity in cart on backend
  /// Route: PUT /api/cart/:productId (Protected)
  static Future<bool> updateCartQuantity(
    String productId,
    int quantity, {
    String? authToken,
  }) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({'quantity': quantity});

      debugPrint('🔵 Updating cart quantity on backend: PUT ${ApiConstants.updateCartQuantity(productId)}');
      final response = await http
          .put(Uri.parse(ApiConstants.updateCartQuantity(productId)), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Update Cart response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error updating cart quantity: $e');
      return false;
    }
  }

  /// Remove item from cart on backend
  /// Route: DELETE /api/cart/remove/:productId (Protected)
  static Future<bool> removeFromCart(String productId, {String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      debugPrint('🔵 Removing from cart on backend: DELETE ${ApiConstants.removeFromCart(productId)}');
      final response = await http
          .delete(Uri.parse(ApiConstants.removeFromCart(productId)), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Remove Cart response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error removing from cart: $e');
      return false;
    }
  }

  /// Clear entire cart on backend
  /// Route: DELETE /api/cart (Protected)
  static Future<bool> clearCart({String? authToken}) async {
    try {
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      debugPrint('🔵 Clearing cart on backend: DELETE ${ApiConstants.clearCart}');
      final response = await http
          .delete(Uri.parse(ApiConstants.clearCart), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Clear Cart response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error clearing cart: $e');
      return false;
    }
  }
}
