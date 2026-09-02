// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinancialSettings _$FinancialSettingsFromJson(Map<String, dynamic> json) =>
    FinancialSettings(
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 1.50,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.08,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 4100.0,
      freeShippingEnabled: json['freeShippingEnabled'] as bool? ?? false,
      freeShippingThreshold:
          (json['freeShippingThreshold'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$FinancialSettingsToJson(FinancialSettings instance) =>
    <String, dynamic>{
      'shippingFee': instance.shippingFee,
      'taxRate': instance.taxRate,
      'exchangeRate': instance.exchangeRate,
      'freeShippingEnabled': instance.freeShippingEnabled,
      'freeShippingThreshold': instance.freeShippingThreshold,
    };
