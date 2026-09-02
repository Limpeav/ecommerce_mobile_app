import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/user_profile.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final SharedPreferences? _prefs;
  static const String _storageKey = 'customer_saved_addresses_v1';

  AddressCubit({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const AddressState()) {
    _loadAddresses();
  }

  void _loadAddresses() {
    if (_prefs != null) {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(jsonString);
          final List<ShippingAddress> list = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              list.add(ShippingAddress.fromJson(item));
            }
          }
          if (list.isNotEmpty) {
            emit(AddressState(addresses: list));
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Error loading saved addresses: $e');
        }
      }
    }

    // Default fallback address
    emit(AddressState(addresses: List.from(UserProfile.defaultUser.addresses)));
  }

  Future<void> _saveAddresses(List<ShippingAddress> addresses) async {
    if (_prefs != null) {
      try {
        final List<Map<String, dynamic>> rawList =
            addresses.map((a) => a.toJson()).toList();
        await _prefs.setString(_storageKey, json.encode(rawList));
      } catch (e) {
        debugPrint('⚠️ Error saving addresses to storage: $e');
      }
    }
  }

  void addAddress(ShippingAddress address) {
    final updated = List<ShippingAddress>.from(state.addresses);
    if (address.isDefault || updated.isEmpty) {
      for (int i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
      updated.insert(0, address.copyWith(isDefault: true));
    } else {
      updated.add(address);
    }
    _saveAddresses(updated);
    emit(AddressState(addresses: updated));
  }

  void updateAddress(ShippingAddress updated) {
    final list = List<ShippingAddress>.from(state.addresses);
    final index = list.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      if (updated.isDefault) {
        for (int i = 0; i < list.length; i++) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
      list[index] = updated;
      _saveAddresses(list);
      emit(AddressState(addresses: list));
    }
  }

  void setDefaultAddress(String id) {
    final list = List<ShippingAddress>.from(state.addresses);
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    _saveAddresses(list);
    emit(AddressState(addresses: list));
  }

  void deleteAddress(String id) {
    final list = List<ShippingAddress>.from(state.addresses);
    final index = list.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final wasDefault = list[index].isDefault;
      list.removeAt(index);
      if (wasDefault && list.isNotEmpty) {
        list[0] = list[0].copyWith(isDefault: true);
      }
      _saveAddresses(list);
      emit(AddressState(addresses: list));
    }
  }
}
