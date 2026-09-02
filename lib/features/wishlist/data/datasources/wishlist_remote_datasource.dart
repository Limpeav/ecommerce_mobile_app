import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/product.dart';

abstract class WishlistRemoteDataSource {
  Future<List<Product>?> fetchWishlist({String? authToken});
  Future<bool> addToWishlist(String productId, {String? authToken});
  Future<bool> removeFromWishlist(String productId, {String? authToken});
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final http.Client? client;

  WishlistRemoteDataSourceImpl({this.client});

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
  Future<List<Product>?> fetchWishlist({String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return null;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client
          .get(Uri.parse(ApiConstants.wishlist), headers: headers)
          .timeout(const Duration(seconds: 12));

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
        return products;
      }
    } catch (e) {
      debugPrint('⚠️ WishlistRemoteDataSource.fetchWishlist error: $e');
    }
    return null;
  }

  @override
  Future<bool> addToWishlist(String productId, {String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({'productId': productId});

      final response = await _client
          .post(Uri.parse(ApiConstants.wishlist), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ WishlistRemoteDataSource.addToWishlist error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFromWishlist(String productId, {String? authToken}) async {
    try {
      String? token = authToken ?? await _getUserAuthToken();
      if (token == null || token.isEmpty) return false;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final url = '${ApiConstants.wishlist}/$productId';
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ WishlistRemoteDataSource.removeFromWishlist error: $e');
      return false;
    }
  }
}
