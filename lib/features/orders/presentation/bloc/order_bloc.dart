import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/order.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/review_requirement_service.dart';
import '../../../../core/services/telegram_bot_service.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final SharedPreferences? _prefs;
  static const String _storageKey = 'customer_saved_orders_v1';

  OrderBloc({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const OrderState()) {
    on<OrderLoadedFromStorage>(_onOrderLoadedFromStorage);
    on<OrderFetchRequested>(_onOrderFetchRequested);
    on<OrderPlaced>(_onOrderPlaced);
    on<OrderMarkedAsPaid>(_onOrderMarkedAsPaid);
    on<OrderTrackRequested>(_onOrderTrackRequested);
    on<OrderCancelled>(_onOrderCancelled);
    on<OrderCleared>(_onOrderCleared);
    on<OrderPendingReviewsRefreshed>(_onOrderPendingReviewsRefreshed);
    on<OrderDeliveryReviewPromptCleared>(_onOrderDeliveryReviewPromptCleared);

    // Automatically load persisted orders
    add(const OrderLoadedFromStorage());
  }

  Future<void> _onOrderLoadedFromStorage(
    OrderLoadedFromStorage event,
    Emitter<OrderState> emit,
  ) async {
    var loadedOrders = <OrderModel>[];
    if (_prefs != null) {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(jsonString);
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              loadedOrders.add(OrderModel.fromJson(item));
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error loading saved orders: $e');
        }
      }
    }

    final newlyRequired =
        await ReviewRequirementService.registerDeliveredOrders(loadedOrders);
    final pendingReviewItems =
        await ReviewRequirementService.getPendingReviewItems();

    emit(state.copyWith(
      orders: loadedOrders,
      pendingReviewItems: pendingReviewItems,
      deliveryReviewPrompt:
          newlyRequired.isNotEmpty ? newlyRequired.first : null,
      clearDeliveryReviewPrompt: newlyRequired.isEmpty,
    ));
  }

  Future<void> _saveOrders(List<OrderModel> orders) async {
    if (_prefs != null) {
      try {
        final List<Map<String, dynamic>> rawList =
            orders.map((o) => o.toJson()).toList();
        await _prefs.setString(_storageKey, json.encode(rawList));
      } catch (e) {
        debugPrint('⚠️ Error saving orders to storage: $e');
      }
    }
  }

  Future<void> _onOrderFetchRequested(
    OrderFetchRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      if (event.authToken == null || event.authToken!.isEmpty) {
        emit(state.copyWith(
          orders: const [],
          pendingReviewItems: const [],
          isLoading: false,
          clearDeliveryReviewPrompt: true,
        ));
        await _saveOrders([]);
        return;
      }

      final remoteOrders = await OrderService.fetchMyOrders(authToken: event.authToken);
      if (remoteOrders != null) {
        await _saveOrders(remoteOrders);
        final newlyRequired =
            await ReviewRequirementService.registerDeliveredOrders(remoteOrders);
        final pendingReviewItems =
            await ReviewRequirementService.getPendingReviewItems();
        emit(state.copyWith(
          orders: remoteOrders,
          pendingReviewItems: pendingReviewItems,
          deliveryReviewPrompt:
              newlyRequired.isNotEmpty ? newlyRequired.first : null,
          isLoading: false,
        ));
        return;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
      return;
    }

    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onOrderPlaced(
    OrderPlaced event,
    Emitter<OrderState> emit,
  ) async {
    final randomNum = 100000 + Random().nextInt(900000);
    final trackingCode = 'EXP-${1000 + Random().nextInt(9000)}-${Random().nextInt(999)}';
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 3));
    final dateStr = '${_monthName(deliveryDate.month)} ${deliveryDate.day}, ${deliveryDate.year}';
    final isKhqr = event.paymentMethod.toUpperCase().contains('BAKONG') ||
        event.paymentMethod.toUpperCase().contains('KHQR');

    OrderModel orderToSave = OrderModel(
      id: '#ORD-$randomNum',
      date: now,
      items: List.from(event.items),
      subtotal: event.subtotal,
      discount: event.discount,
      shipping: event.shipping,
      tax: event.tax,
      total: event.total,
      deliveryAddress: event.deliveryAddress,
      paymentMethod: event.paymentMethod,
      status: OrderStatus.processing,
      trackingNumber: trackingCode,
      estimatedDelivery: dateStr,
      isPaid: false,
      paidAt: null,
      recipientName: event.recipientName,
      recipientPhone: event.recipientPhone,
      city: event.city,
      street: event.street,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    // Call Backend API
    try {
      final result = await OrderService.createOrder(
        order: orderToSave,
        authToken: event.authToken,
      );
      if (result.success && result.order != null) {
        orderToSave = result.order!.copyWith(
          latitude: event.latitude ?? result.order!.latitude,
          longitude: event.longitude ?? result.order!.longitude,
          recipientName: event.recipientName ?? result.order!.recipientName,
          recipientPhone: event.recipientPhone ?? result.order!.recipientPhone,
        );
      } else {
        debugPrint('⚠️ Backend rejected order creation: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('⚠️ Order saved locally, backend sync notice: $e');
    }

    final updatedOrders = [orderToSave, ...state.orders];
    await _saveOrders(updatedOrders);
    emit(state.copyWith(
      orders: updatedOrders,
      lastPlacedOrder: orderToSave,
    ));

    event.onComplete?.call(orderToSave);

    // Dispatch real-time push notification for order creation
    PushNotificationService.instance.notifyOrderStatusChange(
      order: orderToSave,
      newStatus: orderToSave.status,
    );

    // Dispatch Telegram Bot notification for Cash on Delivery orders
    if (!isKhqr) {
      TelegramBotService.sendOrderNotification(
        order: orderToSave,
        exchangeRate: event.exchangeRate,
      ).catchError((e) {
        debugPrint('⚠️ Telegram dispatch background error: $e');
        return false;
      });
    }
  }

  Future<void> _onOrderMarkedAsPaid(
    OrderMarkedAsPaid event,
    Emitter<OrderState> emit,
  ) async {
    final index = state.orders.indexWhere((o) => o.id == event.orderId || o.id == '#${event.orderId}');
    final now = DateTime.now();

    await OrderService.markOrderAsPaid(
      event.orderId,
      authToken: event.authToken,
      paymentResult: event.paymentResult,
    );

    if (index >= 0) {
      final updatedOrders = List<OrderModel>.from(state.orders);
      final updatedOrder = updatedOrders[index].copyWith(
        isPaid: true,
        paidAt: now,
      );
      updatedOrders[index] = updatedOrder;

      await _saveOrders(updatedOrders);
      emit(state.copyWith(orders: updatedOrders));

      TelegramBotService.sendOrderNotification(
        order: updatedOrder,
        exchangeRate: event.exchangeRate,
        paymentStatusOverride: 'PAID',
        transactionId: event.paymentResult?['id']?.toString() ??
            event.paymentResult?['paymentId']?.toString(),
      ).catchError((e) {
        debugPrint('⚠️ Telegram dispatch background error: $e');
        return false;
      });
    }
  }

  Future<void> _onOrderTrackRequested(
    OrderTrackRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final updated = await OrderService.trackOrder(
        event.orderIdOrNumber,
        authToken: event.authToken,
      );
      if (updated != null) {
        final updatedOrders = List<OrderModel>.from(state.orders);
        final index = updatedOrders.indexWhere((o) =>
            o.id == updated.id ||
            o.trackingNumber == updated.trackingNumber ||
            o.id == event.orderIdOrNumber ||
            o.trackingNumber == event.orderIdOrNumber);

        if (index >= 0) {
          final previousStatus = updatedOrders[index].status;
          updatedOrders[index] = updated;
          if (previousStatus != updated.status) {
            PushNotificationService.instance.notifyOrderStatusChange(
              order: updated,
              newStatus: updated.status,
            );
          }
        } else {
          updatedOrders.insert(0, updated);
        }

        await _saveOrders(updatedOrders);
        final newlyRequired =
            await ReviewRequirementService.registerDeliveredOrders(updatedOrders);
        final pendingReviewItems =
            await ReviewRequirementService.getPendingReviewItems();
        emit(state.copyWith(
          orders: updatedOrders,
          pendingReviewItems: pendingReviewItems,
          deliveryReviewPrompt:
              newlyRequired.isNotEmpty ? newlyRequired.first : null,
        ));
        event.onResult?.call(updated);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error tracking order in bloc: $e');
    }
    event.onResult?.call(null);
  }

  Future<void> _onOrderCancelled(
    OrderCancelled event,
    Emitter<OrderState> emit,
  ) async {
    final index = state.orders.indexWhere((o) => o.id == event.orderId);
    if (index >= 0) {
      await OrderService.cancelOrder(event.orderId, authToken: event.authToken);

      final updatedOrders = List<OrderModel>.from(state.orders);
      updatedOrders[index] = updatedOrders[index].copyWith(status: OrderStatus.cancelled);

      await _saveOrders(updatedOrders);
      emit(state.copyWith(orders: updatedOrders));
    }
  }

  Future<void> _onOrderCleared(
    OrderCleared event,
    Emitter<OrderState> emit,
  ) async {
    await _saveOrders([]);
    emit(state.copyWith(
      orders: const [],
      pendingReviewItems: const [],
      clearDeliveryReviewPrompt: true,
    ));
  }

  Future<void> _onOrderPendingReviewsRefreshed(
    OrderPendingReviewsRefreshed event,
    Emitter<OrderState> emit,
  ) async {
    final pendingReviewItems =
        await ReviewRequirementService.getPendingReviewItems();
    emit(state.copyWith(pendingReviewItems: pendingReviewItems));
  }

  void _onOrderDeliveryReviewPromptCleared(
    OrderDeliveryReviewPromptCleared event,
    Emitter<OrderState> emit,
  ) {
    emit(state.copyWith(clearDeliveryReviewPrompt: true));
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
