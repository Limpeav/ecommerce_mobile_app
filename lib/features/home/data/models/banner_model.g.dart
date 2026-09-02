// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BannerModel _$BannerModelFromJson(Map<String, dynamic> json) => BannerModel(
  id: BannerModel._readId(json, 'id') as String,
  title: json['title'] as String? ?? '',
  alt: json['alt'] as String? ?? '',
  image: json['image'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BannerModelToJson(BannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'alt': instance.alt,
      'image': instance.image,
      'isActive': instance.isActive,
      'sortOrder': instance.sortOrder,
    };
