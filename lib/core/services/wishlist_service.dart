import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';

class WishlistService {
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

  /// Fetch user wishlist from MongoDB backend
  /// Route: GET /api/wishlist (Protected)
  static Future<List<Product>?> fetchWishlist({String? authToken}) async {
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

      debugPrint('🔵 Fetching wishlist from backend: GET ${ApiConstants.wishlist}');
      final response = await http
          .get(Uri.parse(ApiConstants.wishlist), headers: headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('🔵 Backend Wishlist Response: HTTP ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = (data is List)
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : (data is Map<String, dynamic> && data['wishlist'] is List)
                    ? data['wishlist'] as List
                    : (data is Map<String, dynamic> && data['products'] is List)
                        ? data['products'] as List
                        : [];

        final List<Product> products = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              if (item['product'] is Map<String, dynamic>) {
                products.add(ProductFactory.fromJson(item['product'] as Map<String, dynamic>));
              } else {
                products.add(ProductFactory.fromJson(item));
              }
            } catch (_) {}
          }
        }
        debugPrint('✅ Loaded ${products.length} wishlist items from backend');
        return products;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching wishlist: $e');
    }
    return null;
  }

  /// Add a product to wishlist on backend
  /// Route: POST /api/wishlist/add (Protected)
  static Future<bool> addToWishlist(String productId, {String? authToken}) async {
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

      final body = json.encode({'productId': productId});

      debugPrint('🔵 Adding to wishlist on backend: POST ${ApiConstants.addToWishlist}');
      final response = await http
          .post(Uri.parse(ApiConstants.addToWishlist), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Add Wishlist response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error adding to wishlist: $e');
      return false;
    }
  }

  /// Remove a product from wishlist on backend
  /// Route: DELETE /api/wishlist/remove/:productId (Protected)
  static Future<bool> removeFromWishlist(String productId, {String? authToken}) async {
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

      debugPrint('🔵 Removing from wishlist on backend: DELETE ${ApiConstants.removeFromWishlist(productId)}');
      final response = await http
          .delete(Uri.parse(ApiConstants.removeFromWishlist(productId)), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 Remove Wishlist response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error removing from wishlist: $e');
      return false;
    }
  }
}
