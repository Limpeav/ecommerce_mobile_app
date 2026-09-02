import 'package:json_annotation/json_annotation.dart';

part 'banner_model.g.dart';

@JsonSerializable()
class BannerModel {
  @JsonKey(readValue: _readId)
  final String id;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String alt;
  @JsonKey(defaultValue: '')
  final String image;
  @JsonKey(defaultValue: true)
  final bool isActive;
  @JsonKey(defaultValue: 0)
  final int sortOrder;

  const BannerModel({
    required this.id,
    required this.title,
    required this.alt,
    required this.image,
    this.isActive = true,
    this.sortOrder = 0,
  });

  static Object? _readId(Map json, String key) =>
      (json['_id'] ?? json['id'] ?? '').toString();

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}
