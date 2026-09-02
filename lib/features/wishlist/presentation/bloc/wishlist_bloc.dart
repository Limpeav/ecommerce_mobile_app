import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/wishlist_service.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final SharedPreferences? _prefs;
  static const String _storageKey = 'customer_saved_wishlist_items_v1';

  WishlistBloc({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const WishlistState()) {
    on<WishlistLoadedFromStorage>(_onWishlistLoadedFromStorage);
    on<WishlistRemoteFetchRequested>(_onWishlistRemoteFetchRequested);
    on<WishlistToggleRequested>(_onWishlistToggleRequested);
    on<WishlistRemoveRequested>(_onWishlistRemoveRequested);

    // Automatically load persisted wishlist
    add(const WishlistLoadedFromStorage());
  }

  void _onWishlistLoadedFromStorage(
    WishlistLoadedFromStorage event,
    Emitter<WishlistState> emit,
  ) {
    if (_prefs != null) {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(jsonString);
          final List<Product> favoriteProducts = [];
          final Set<String> favoriteIds = {};
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final prod = ProductFactory.fromJson(item);
              favoriteProducts.add(prod);
              favoriteIds.add(prod.id);
            }
          }
          emit(state.copyWith(
            items: favoriteProducts,
            favoriteProductIds: favoriteIds,
          ));
        } catch (e) {
          debugPrint('⚠️ Error loading saved wishlist items: $e');
        }
      }
    }
  }

  Future<void> _saveWishlist(List<Product> items) async {
    if (_prefs != null) {
      try {
        final List<Map<String, dynamic>> rawList = items
            .map((p) => ProductFactory.fromEntity(p).toJson())
            .toList();
        await _prefs.setString(_storageKey, json.encode(rawList));
      } catch (e) {
        debugPrint('⚠️ Error saving wishlist items: $e');
      }
    }
  }

  Future<void> _onWishlistRemoteFetchRequested(
    WishlistRemoteFetchRequested event,
    Emitter<WishlistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final remoteList = await WishlistService.fetchWishlist(authToken: event.authToken);
      if (remoteList != null) {
        final List<Product> favoriteProducts = List.from(remoteList);
        final Set<String> favoriteIds = favoriteProducts.map((p) => p.id).toSet();
        await _saveWishlist(favoriteProducts);
        emit(state.copyWith(
          items: favoriteProducts,
          favoriteProductIds: favoriteIds,
          isLoading: false,
        ));
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching remote wishlist: $e');
    }

    emit(state.copyWith(isLoading: false));
  }

  void _onWishlistToggleRequested(
    WishlistToggleRequested event,
    Emitter<WishlistState> emit,
  ) {
    final updatedItems = List<Product>.from(state.items);
    final updatedIds = Set<String>.from(state.favoriteProductIds);

    if (updatedIds.contains(event.product.id)) {
      updatedIds.remove(event.product.id);
      updatedItems.removeWhere((p) => p.id == event.product.id);
      WishlistService.removeFromWishlist(event.product.id, authToken: event.authToken);
    } else {
      updatedIds.add(event.product.id);
      updatedItems.add(event.product);
      WishlistService.addToWishlist(event.product.id, authToken: event.authToken);
    }

    _saveWishlist(updatedItems);
    emit(state.copyWith(
      items: updatedItems,
      favoriteProductIds: updatedIds,
    ));
  }

  void _onWishlistRemoveRequested(
    WishlistRemoveRequested event,
    Emitter<WishlistState> emit,
  ) {
    final updatedItems = List<Product>.from(state.items);
    final updatedIds = Set<String>.from(state.favoriteProductIds);

    updatedIds.remove(event.productId);
    updatedItems.removeWhere((p) => p.id == event.productId);
    WishlistService.removeFromWishlist(event.productId, authToken: event.authToken);

    _saveWishlist(updatedItems);
    emit(state.copyWith(
      items: updatedItems,
      favoriteProductIds: updatedIds,
    ));
  }
}
