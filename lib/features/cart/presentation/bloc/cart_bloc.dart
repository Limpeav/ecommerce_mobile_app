import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/services/cart_service.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final SharedPreferences? _prefs;
  static const String _storageKey = 'customer_saved_cart_items_v1';
  static const String _promoStorageKey = 'customer_saved_cart_promo_v1';

  CartBloc({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const CartState()) {
    on<CartLoadedFromStorage>(_onCartLoadedFromStorage);
    on<CartRemoteFetchRequested>(_onCartRemoteFetchRequested);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<CartPromoCodeApplied>(_onCartPromoCodeApplied);
    on<CartPromoCodeRemoved>(_onCartPromoCodeRemoved);
    on<CartFinancialSettingsUpdated>(_onCartFinancialSettingsUpdated);

    // Automatically load persisted cart
    add(const CartLoadedFromStorage());
  }

  void _onCartLoadedFromStorage(
    CartLoadedFromStorage event,
    Emitter<CartState> emit,
  ) {
    if (_prefs != null) {
      final List<CartItem> loadedItems = [];
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(jsonString);
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              loadedItems.add(CartItem.fromJson(item));
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error loading saved cart items: $e');
        }
      }

      var newState = state.copyWith(items: loadedItems);

      final savedPromo = _prefs.getString(_promoStorageKey);
      if (savedPromo != null && savedPromo.isNotEmpty) {
        newState = _applyPromo(newState, savedPromo);
      }

      emit(newState);
    }
  }

  Future<void> _saveCart(CartState currentState) async {
    if (_prefs != null) {
      try {
        final List<Map<String, dynamic>> rawList =
            currentState.items.map((i) => i.toJson()).toList();
        await _prefs.setString(_storageKey, json.encode(rawList));
        if (currentState.appliedPromoCode != null) {
          await _prefs.setString(_promoStorageKey, currentState.appliedPromoCode!);
        } else {
          await _prefs.remove(_promoStorageKey);
        }
      } catch (e) {
        debugPrint('⚠️ Error saving cart items: $e');
      }
    }
  }

  Future<void> _onCartRemoteFetchRequested(
    CartRemoteFetchRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final remoteItems = await CartService.fetchCart(authToken: event.authToken);
      if (remoteItems != null) {
        final newState = state.copyWith(
          items: remoteItems,
          isLoading: false,
        );
        await _saveCart(newState);
        emit(newState);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching remote cart: $e');
    }

    emit(state.copyWith(isLoading: false));
  }

  void _onCartItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) {
    final chosenColor = event.color ??
        (event.product.availableColors.isNotEmpty
            ? event.product.availableColors.first
            : 'Default');
    final chosenSize = event.size ??
        (event.product.availableSizes.isNotEmpty
            ? event.product.availableSizes.first
            : 'Standard');

    final updatedItems = List<CartItem>.from(state.items);
    final index = updatedItems.indexWhere(
      (item) =>
          item.product.id == event.product.id &&
          item.selectedColor == chosenColor &&
          item.selectedSize == chosenSize,
    );

    if (index >= 0) {
      final existing = updatedItems[index];
      updatedItems[index] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
      CartService.updateCartQuantity(
        event.product.id,
        updatedItems[index].quantity,
        authToken: event.authToken,
      );
    } else {
      updatedItems.add(CartItem(
        product: event.product,
        quantity: event.quantity,
        selectedColor: chosenColor,
        selectedSize: chosenSize,
      ));
      CartService.addToCart(
        productId: event.product.id,
        quantity: event.quantity,
        color: chosenColor,
        size: chosenSize,
        authToken: event.authToken,
      );
    }

    final newState = state.copyWith(items: updatedItems);
    _saveCart(newState);
    emit(newState);
  }

  void _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) {
    final updatedItems = List<CartItem>.from(state.items);
    final index = updatedItems.indexWhere((i) =>
        i.product.id == event.item.product.id &&
        i.selectedColor == event.item.selectedColor &&
        i.selectedSize == event.item.selectedSize);

    if (index >= 0) {
      if (event.newQuantity <= 0) {
        updatedItems.removeAt(index);
        CartService.removeFromCart(event.item.product.id, authToken: event.authToken);
      } else {
        updatedItems[index] = updatedItems[index].copyWith(quantity: event.newQuantity);
        CartService.updateCartQuantity(
          event.item.product.id,
          event.newQuantity,
          authToken: event.authToken,
        );
      }

      final newState = state.copyWith(items: updatedItems);
      _saveCart(newState);
      emit(newState);
    }
  }

  void _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) {
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems.removeWhere((i) =>
        i.product.id == event.item.product.id &&
        i.selectedColor == event.item.selectedColor &&
        i.selectedSize == event.item.selectedSize);

    CartService.removeFromCart(event.item.product.id, authToken: event.authToken);

    var newState = state.copyWith(items: updatedItems);
    if (updatedItems.isEmpty) {
      newState = newState.copyWith(
        clearPromo: true,
        discountRate: 0.0,
        flatDiscount: 0.0,
        freeShippingApplied: false,
      );
    }
    _saveCart(newState);
    emit(newState);
  }

  void _onCartCleared(
    CartCleared event,
    Emitter<CartState> emit,
  ) {
    CartService.clearCart(authToken: event.authToken);
    final newState = state.copyWith(
      items: const [],
      clearPromo: true,
      discountRate: 0.0,
      flatDiscount: 0.0,
      freeShippingApplied: false,
    );
    _saveCart(newState);
    emit(newState);
  }

  void _onCartPromoCodeApplied(
    CartPromoCodeApplied event,
    Emitter<CartState> emit,
  ) {
    final newState = _applyPromo(state, event.code);
    _saveCart(newState);
    emit(newState);
  }

  void _onCartPromoCodeRemoved(
    CartPromoCodeRemoved event,
    Emitter<CartState> emit,
  ) {
    final newState = state.copyWith(
      clearPromo: true,
      discountRate: 0.0,
      flatDiscount: 0.0,
      freeShippingApplied: false,
    );
    _saveCart(newState);
    emit(newState);
  }

  void _onCartFinancialSettingsUpdated(
    CartFinancialSettingsUpdated event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(
      adminShippingFee: event.shippingFee,
      adminTaxRate: event.taxRate,
      adminFreeShippingThreshold: event.freeShippingThreshold,
    ));
  }

  CartState _applyPromo(CartState current, String code) {
    final trimmed = code.trim().toUpperCase();
    if (trimmed == 'SAVE20') {
      return current.copyWith(
        appliedPromoCode: trimmed,
        discountRate: 0.20,
        flatDiscount: 0.0,
        freeShippingApplied: false,
      );
    } else if (trimmed == 'SUPER50') {
      return current.copyWith(
        appliedPromoCode: trimmed,
        discountRate: 0.0,
        flatDiscount: 50.0,
        freeShippingApplied: false,
      );
    } else if (trimmed == 'FREESHIP') {
      return current.copyWith(
        appliedPromoCode: trimmed,
        discountRate: 0.0,
        flatDiscount: 0.0,
        freeShippingApplied: true,
      );
    }
    return current;
  }
}
