import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ProductReviewService {
  static Future<bool> submitReview({
    required String productId,
    required double rating,
    required String comment,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      final body = json.encode({
        'rating': rating,
        'comment': comment,
      });

      final response = await http
          .post(
            Uri.parse(ApiConstants.productReviews(productId)),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('🔵 Submit product review response: HTTP ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Error submitting product review to backend: $e');
      return false;
    }
  }
}
