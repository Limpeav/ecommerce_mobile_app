// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShippingAddress _$ShippingAddressFromJson(Map<String, dynamic> json) =>
    ShippingAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      recipientName: json['recipientName'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$ShippingAddressToJson(ShippingAddress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'recipientName': instance.recipientName,
      'street': instance.street,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'phone': instance.phone,
      'isDefault': instance.isDefault,
    };

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  avatarUrl: json['avatarUrl'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  addresses:
      (json['addresses'] as List<dynamic>?)
          ?.map((e) => ShippingAddress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'phone': instance.phone,
      'addresses': instance.addresses.map((e) => e.toJson()).toList(),
    };
