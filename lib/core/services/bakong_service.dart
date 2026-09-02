import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class BakongQrResponse {
  final bool success;
  final String? qrData;
  final String? md5;
  final String? paymentId;
  final String? errorMessage;

  const BakongQrResponse({
    required this.success,
    this.qrData,
    this.md5,
    this.paymentId,
    this.errorMessage,
  });
}

class BakongTransactionStatus {
  final bool isPaid;
  final String? status;
  final String? transactionHash;
  final double? amount;

  const BakongTransactionStatus({
    required this.isPaid,
    this.status,
    this.transactionHash,
    this.amount,
  });
}

class BakongService {
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

  /// Request your backend to generate a Bakong KHQR code
  /// Route: POST /api/payments/bakong/generate (Protected)
  static Future<BakongQrResponse> generateMerchantQr({
    required double amount,
    String currency = 'USD',
    String? orderId,
    String? authToken, // Pass directly from AuthController instead of re-reading prefs
  }) async {
    try {
      // Prefer injected token; fall back to SharedPreferences
      String? token = authToken;
      if (token == null || token.isEmpty) {
        token = await _getUserAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Check if orderId is a valid 24-character hex MongoDB ObjectId before sending
      final isValidObjectId = orderId != null &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(orderId);

      final body = json.encode({
        'amount': amount,
        'currency': currency,
        if (isValidObjectId) 'orderId': orderId,
      });

      final response = await http
          .post(
            Uri.parse(ApiConstants.generateBakongQR),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('🔵 Bakong QR generate: HTTP ${response.statusCode} body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final resData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : <String, dynamic>{});

        final khqr = (data is Map<String, dynamic> && data['khqrData'] is Map<String, dynamic>)
            ? data['khqrData'] as Map<String, dynamic>
            : (resData['khqrData'] is Map<String, dynamic>
                ? resData['khqrData'] as Map<String, dynamic>
                : resData);

        final qrData = (khqr['qrString'] ??
                khqr['qr'] ??
                khqr['qrCode'] ??
                resData['qr'] ??
                resData['qrCode'] ??
                resData['qrString'] ??
                resData['data'])
            ?.toString();
        final md5 = (khqr['md5'] ?? resData['md5'] ?? resData['hash'])?.toString();
        final paymentId = (data['_id'] ??
                data['id'] ??
                resData['paymentId'] ??
                resData['_id'] ??
                resData['id'] ??
                khqr['transactionId'])
            ?.toString();

        return BakongQrResponse(
          success: true,
          qrData: qrData,
          md5: md5,
          paymentId: paymentId,
        );
      } else {
        String errMsg = 'Backend returned status ${response.statusCode}';
        try {
          final errJson = json.decode(utf8.decode(response.bodyBytes));
          if (errJson is Map<String, dynamic> && errJson['message'] != null) {
            errMsg = errJson['message'].toString();
          }
        } catch (_) {}
        if (response.statusCode == 401) {
          errMsg = 'Please log in first to generate Bakong KHQR payment.';
        }
        return BakongQrResponse(
          success: false,
          errorMessage: errMsg,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting Bakong QR from backend: $e');
      return BakongQrResponse(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Poll backend for payment status
  /// Route: GET /api/payments/:paymentId/status (Protected)
  static Future<BakongTransactionStatus> checkPaymentStatus(String paymentId, {String? authToken}) async {
    if (paymentId.isEmpty) {
      return const BakongTransactionStatus(isPaid: false);
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

      final response = await http
          .get(
            Uri.parse(ApiConstants.paymentStatus(paymentId)),
            headers: headers,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final resData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : <String, dynamic>{});

        final status = (resData['status'] ?? data['status'] ?? '').toString().toUpperCase();
        final isPaid = status == 'PAID' ||
            status == 'COMPLETED' ||
            status == 'SUCCESS' ||
            resData['isPaid'] == true ||
            data['isPaid'] == true;

        return BakongTransactionStatus(
          isPaid: isPaid,
          status: status,
          transactionHash: (resData['transactionHash'] ?? resData['hash'])?.toString(),
          amount: (resData['amount'] as num?)?.toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Bakong backend status poll error: $e');
    }

    return const BakongTransactionStatus(isPaid: false);
  }

  /// EMVCo CRC-16 CCITT (0x1021) Checksum calculation for Bakong KHQR
  static String calculateCrc16(String data) {
    int crc = 0xFFFF;
    final bytes = utf8.encode(data);
    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Generate an official EMVCo-compliant Bakong KHQR QR string locally
  static String generateFallbackKhqr({
    required double amount,
    String currency = 'USD',
    String? orderId,
    String accountId = 'cherish_baby@abaa',
    String merchantName = 'Cherish Baby Store',
    String city = 'Phnom Penh',
  }) {
    final currencyCode = currency.toUpperCase() == 'KHR' ? '116' : '840';
    final formattedAmount = amount.toStringAsFixed(2);
    final cleanOrder = (orderId ?? 'ORD-000000').replaceAll('#', '');

    // Format Tag-Length-Value (EMVCo TLV)
    String tlv(String tag, String value) {
      final len = utf8.encode(value).length.toString().padLeft(2, '0');
      return '$tag$len$value';
    }

    final merchantInfo = tlv('00', accountId) + tlv('01', 'ABA Bank');
    final tag29 = tlv('29', merchantInfo);
    final tag52 = tlv('52', '5999');
    final tag53 = tlv('53', currencyCode);
    final tag54 = tlv('54', formattedAmount);
    final tag58 = tlv('58', 'KH');
    final tag59 = tlv('59', merchantName);
    final tag60 = tlv('60', city);
    final tag62 = tlv('62', tlv('01', cleanOrder));

    final rawPayload = '000201010212'
        '$tag29'
        '$tag52'
        '$tag53'
        '$tag54'
        '$tag58'
        '$tag59'
        '$tag60'
        '$tag62'
        '6304';

    final crc = calculateCrc16(rawPayload);
    return '$rawPayload$crc';
  }
}
