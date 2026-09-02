import 'package:equatable/equatable.dart';
import '../../../../core/models/user_profile.dart';

class AddressState extends Equatable {
  final List<ShippingAddress> addresses;

  const AddressState({this.addresses = const []});

  ShippingAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  AddressState copyWith({List<ShippingAddress>? addresses}) {
    return AddressState(addresses: addresses ?? this.addresses);
  }

  @override
  List<Object?> get props => [addresses];
}
