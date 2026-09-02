import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/profile/presentation/bloc/address_cubit.dart';
import 'package:flutter_application_1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:flutter_application_1/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:flutter_application_1/features/orders/presentation/bloc/order_bloc.dart';
import 'package:flutter_application_1/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_application_1/core/theme/bloc/theme_cubit.dart';
import 'package:flutter_application_1/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:flutter_application_1/core/di/service_locator.dart';
import 'package:flutter_application_1/core/models/notification_item.dart';
import 'package:flutter_application_1/core/models/order.dart';
import 'package:flutter_application_1/core/services/search_history_service.dart';
import 'package:flutter_application_1/features/catalog/presentation/pages/catalog_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:flutter_application_1/features/orders/presentation/pages/order_tracking_page.dart';

Widget _buildTestApp({required Widget child}) {
  final sl = ServiceLocator.instance;
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>.value(value: sl.themeCubit),
      BlocProvider<AuthBloc>.value(value: sl.authBloc),
      BlocProvider<ProductBloc>.value(value: sl.productBloc),
      BlocProvider<CartBloc>.value(value: sl.cartBloc),
      BlocProvider<WishlistBloc>.value(value: sl.wishlistBloc),
      BlocProvider<OrderBloc>.value(value: sl.orderBloc),
      BlocProvider<AddressCubit>.value(value: sl.addressCubit),
      BlocProvider<NotificationCubit>.value(value: sl.notificationCubit),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ServiceLocator.instance.init(preferences: prefs, force: true);
  });

  group('NotificationCubit & Service Tests', () {
    test('NotificationCubit initializes with seeded high-touch notifications', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      expect(cubit.state.notifications.isNotEmpty, true);
      expect(cubit.state.unreadCount > 0, true);
    });

    test('Adding order notification creates new item at top and increments unread count', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      final initialUnread = cubit.state.unreadCount;

      cubit.addNotification(
        title: '📦 Order #ORD-999 Shipped',
        message: 'Your baby items package is on the way via Express Courier.',
        type: NotificationType.order,
        orderId: 'ord_test_999',
        orderNumber: '#ORD-999',
      );

      expect(cubit.state.notifications.first.title, contains('Order #ORD-999 Shipped'));
      expect(cubit.state.notifications.first.type, NotificationType.order);
      expect(cubit.state.unreadCount, initialUnread + 1);
    });

    test('Marking single notification as read updates status accurately', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      final firstId = cubit.state.notifications.first.id;

      cubit.markAsRead(firstId);
      final item = cubit.state.notifications.firstWhere((n) => n.id == firstId);
      expect(item.isRead, true);
    });

    test('Mark all as read marks every notification as read', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      cubit.markAllAsRead();
      expect(cubit.state.unreadCount, 0);
    });

    test('Filter by NotificationType returns only matching items', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      cubit.setFilter(NotificationType.promo);

      expect(cubit.state.selectedFilter, NotificationType.promo);
      final filtered = cubit.state.filteredNotifications;
      for (final item in filtered) {
        expect(item.type, NotificationType.promo);
      }
    });

    test('Clear all empties notification list', () {
      final cubit = ServiceLocator.instance.notificationCubit;
      cubit.clearAll();
      expect(cubit.state.notifications.isEmpty, true);
      expect(cubit.state.unreadCount, 0);
    });
  });

  group('SearchHistoryService Unit Tests', () {
    test('Adding search queries persists, deduplicates, and limits to maxRecentItems', () async {
      final service = ServiceLocator.instance.searchHistoryService;
      await service.clearHistory();

      await service.addSearch('Romper');
      await service.addSearch('Crib');
      await service.addSearch('Bottle');
      await service.addSearch('Romper'); // Duplicate should move to top

      final history = service.getHistory();
      expect(history.first, 'Romper');
      expect(history.length, 3);
      expect(history, ['Romper', 'Bottle', 'Crib']);
    });

    test('Removing specific query updates history cleanly', () async {
      final service = ServiceLocator.instance.searchHistoryService;
      await service.addSearch('Stroller');
      await service.removeSearch('Stroller');

      expect(service.getHistory().contains('Stroller'), false);
    });

    test('Trending searches provides curated baby items', () {
      final trending = SearchHistoryService.trendingSearches;
      expect(trending.isNotEmpty, true);
      expect(trending.contains('Organic Cotton Romper'), true);
      expect(trending.contains('Baby Stroller'), true);
    });
  });

  group('NotificationCenterPage & Live Tracking Widget Tests', () {
    testWidgets('NotificationCenterPage renders header, category filter chips and cards', (tester) async {
      await tester.pumpWidget(_buildTestApp(child: const NotificationCenterPage()));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('All'), findsOneWidget);
      expect(find.textContaining('Orders'), findsOneWidget);
      expect(find.textContaining('Promotions'), findsOneWidget);
    });

    testWidgets('OrderTrackingPage renders live polling sync banner and steps', (tester) async {
      final dummyOrder = OrderModel(
        id: 'ord_test_live_1',
        date: DateTime.now(),
        trackingNumber: 'EXP-LIVE-1',
        items: const [],
        subtotal: 45.0,
        discount: 0.0,
        shipping: 2.0,
        tax: 0.0,
        total: 47.0,
        deliveryAddress: '123 Test Street, Phnom Penh',
        paymentMethod: 'Bakong KHQR',
        status: OrderStatus.processing,
        estimatedDelivery: '3-5 Business Days',
      );

      await tester.pumpWidget(_buildTestApp(child: OrderTrackingPage(order: dummyOrder)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Track'), findsWidgets);
      expect(find.textContaining('Live Real-Time Polling Active'), findsOneWidget);
      expect(find.text('Processing'), findsWidgets);
    });

    testWidgets('CatalogPage displays Trending Searches on focus', (tester) async {
      await tester.pumpWidget(_buildTestApp(child: const CatalogPage(focusSearchOnOpen: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trending Searches'), findsOneWidget);
      expect(find.text('Organic Cotton Romper'), findsOneWidget);
    });
  });
}
