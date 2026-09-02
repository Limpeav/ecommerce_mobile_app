import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/notification_item.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  static const String _storageKey = 'cherish_notifications_v1';
  final SharedPreferences? _preferences;

  NotificationCubit({SharedPreferences? preferences})
      : _preferences = preferences,
        super(const NotificationState()) {
    _loadNotifications();
  }

  void _loadNotifications() {
    final raw = _preferences?.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final items = decoded
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(notifications: items));
        return;
      } catch (_) {}
    }

    // Seed initial notifications for high-touch user engagement
    final initialItems = [
      NotificationItem(
        id: 'notif_welcome',
        title: '🎉 Welcome to Cherish Baby Store!',
        message: 'Enjoy premium baby & kids essentials with high-speed delivery and secure Bakong KHQR checkout.',
        type: NotificationType.system,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_flash_sale',
        title: '⚡ Weekend Flash Sale is Live!',
        message: 'Save up to 40% on organic cotton rompers, cribs, and baby care gear. Limited stocks available.',
        type: NotificationType.flashSale,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_promo_voucher',
        title: '🏷️ Exclusive Welcome Voucher',
        message: 'Use code CHERISH10 at checkout to receive 10% off your entire first baby apparel order.',
        type: NotificationType.promo,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
    ];

    emit(state.copyWith(notifications: initialItems));
    _saveToStorage(initialItems);
  }

  Future<void> _saveToStorage(List<NotificationItem> items) async {
    try {
      final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await _preferences?.setString(_storageKey, jsonStr);
    } catch (_) {}
  }

  /// Add a new real-time in-app notification (e.g. order status changes)
  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
    String? orderNumber,
    String? productId,
  }) {
    final newItem = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      orderId: orderId,
      orderNumber: orderNumber,
      productId: productId,
    );

    final updated = [newItem, ...state.notifications];
    emit(state.copyWith(notifications: updated));
    _saveToStorage(updated);
  }

  /// Mark a specific notification as read
  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    emit(state.copyWith(notifications: updated));
    _saveToStorage(updated);
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
    _saveToStorage(updated);
  }

  /// Delete a single notification
  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(notifications: updated));
    _saveToStorage(updated);
  }

  /// Clear all notifications
  void clearAll() {
    emit(state.copyWith(notifications: []));
    _saveToStorage([]);
  }

  /// Set category filter (All, Orders, Promos, Flash Sales, System)
  void setFilter(NotificationType? filter) {
    if (filter == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(selectedFilter: filter));
    }
  }
}
