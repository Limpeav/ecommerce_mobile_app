import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import '../constants/api_constants.dart';

part 'settings_service.g.dart';

/// Holds the admin-configured financial settings fetched from the backend.
@JsonSerializable()
class FinancialSettings {
  final double shippingFee;
  final double taxRate;        // e.g. 0.10 for 10%
  final double exchangeRate;   // USD → KHR (e.g. 4100.0)
  final bool freeShippingEnabled;
  final double freeShippingThreshold; // order subtotal above which shipping is free

  const FinancialSettings({
    this.shippingFee = 1.50,
    this.taxRate = 0.08,
    this.exchangeRate = 4100.0,
    this.freeShippingEnabled = false,
    this.freeShippingThreshold = 0.0,
  });

  /// Fallback defaults used while loading or on network error.
  static const FinancialSettings defaults = FinancialSettings();

  factory FinancialSettings.fromJson(Map<String, dynamic> json) {
    // Support both flat and nested response formats from the backend.
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    // Backend returns: { usdToKhrRate, khrToUsdRate, taxPercentage, deliveryFee }
    // taxPercentage is a whole number (e.g. 8 means 8%), convert to decimal
    final rawTax = _parseDouble(data['taxPercentage'] ?? data['taxRate'] ?? data['tax_rate'] ?? data['tax'] ?? 8.0);
    final taxRate = rawTax > 1.0 ? rawTax / 100.0 : rawTax; // 8 → 0.08

    final normalized = <String, dynamic>{
      'shippingFee': _parseDouble(data['deliveryFee'] ?? data['shippingFee'] ?? data['shipping_fee'] ?? data['shippingRate'] ?? 1.50),
      'taxRate': taxRate,
      'exchangeRate': _parseDouble(data['usdToKhrRate'] ?? data['exchangeRate'] ?? data['exchange_rate'] ?? data['khrRate'] ?? 4100.0),
      'freeShippingEnabled': data['freeShippingEnabled'] == true || data['free_shipping_enabled'] == true,
      'freeShippingThreshold': _parseDouble(data['freeShippingThreshold'] ?? data['free_shipping_threshold'] ?? 0.0),
    };

    return _$FinancialSettingsFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$FinancialSettingsToJson(this);

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Calculates the effective shipping fee given a cart subtotal.
  double effectiveShipping(double subtotal) {
    if (freeShippingEnabled && subtotal >= freeShippingThreshold) return 0.0;
    return shippingFee;
  }
}

class SettingsService {
  static FinancialSettings? _cached;

  /// Fetches admin financial settings from GET /api/settings/financial.
  /// Returns cached result on subsequent calls; falls back to defaults on error.
  static Future<FinancialSettings> fetchFinancialSettings({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.financialSettings),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _cached = FinancialSettings.fromJson(json);
        debugPrint('✅ Financial settings loaded: shipping=\$${_cached!.shippingFee}, tax=${_cached!.taxRate}, rate=${_cached!.exchangeRate}');
        return _cached!;
      } else {
        debugPrint('⚠️ Financial settings returned ${response.statusCode}, using defaults');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch financial settings: $e — using defaults');
    }

    _cached = FinancialSettings.defaults;
    return _cached!;
  }

  /// Clear cached settings (e.g. after admin updates them).
  static void clearCache() => _cached = null;
}
