import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class ShippingAddress {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: 'Home')
  final String label; // e.g. "Home", "Office"
  @JsonKey(defaultValue: '')
  final String recipientName;
  @JsonKey(defaultValue: '')
  final String street;
  @JsonKey(defaultValue: '')
  final String city;
  @JsonKey(defaultValue: '')
  final String state;
  @JsonKey(defaultValue: '')
  final String zipCode;
  @JsonKey(defaultValue: '')
  final String phone;
  @JsonKey(defaultValue: false)
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    this.isDefault = false,
  });

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    bool? isDefault,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressFromJson(json);

  Map<String, dynamic> toJson() => _$ShippingAddressToJson(this);

  String get formattedAddress => '$street, $city, $state $zipCode';
}

@JsonSerializable(explicitToJson: true)
class UserProfile {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String email;
  @JsonKey(defaultValue: '')
  final String avatarUrl;
  @JsonKey(defaultValue: '')
  final String phone;
  @JsonKey(defaultValue: <ShippingAddress>[])
  final List<ShippingAddress> addresses;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.phone,
    required this.addresses,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  static UserProfile defaultUser = UserProfile(
    id: 'usr_guest',
    name: 'Cherish Customer',
    email: 'customer@cherishbabystore.com',
    avatarUrl: '',
    phone: '+1 (555) 349-2810',
    addresses: [
      ShippingAddress(
        id: 'addr_1',
        label: 'Home',
        recipientName: 'Cherish Customer',
        street: '742 Evergreen Terrace, Suite 4B',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94107',
        phone: '+1 (555) 349-2810',
        isDefault: true,
      ),
    ],
  );
}
