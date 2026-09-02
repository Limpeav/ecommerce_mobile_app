// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String? ?? '',
  role: json['role'] as String? ?? 'user',
  token: json['token'] as String?,
  avatarUrl: json['avatarUrl'] as String? ?? '',
  isVerified: json['isVerified'] as bool? ?? true,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'role': instance.role,
  'token': instance.token,
  'avatarUrl': instance.avatarUrl,
  'isVerified': instance.isVerified,
};
