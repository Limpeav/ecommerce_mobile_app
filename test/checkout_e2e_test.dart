import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/di/service_locator.dart';
import 'package:flutter_application_1/core/models/order.dart';
import 'package:flutter_application_1/core/models/product.dart';
import 'package:flutter_application_1/core/theme/bloc/locale_cubit.dart';
import 'package:flutter_application_1/core/theme/bloc/theme_cubit.dart';
import 'package:flutter_application_1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:flutter_application_1/features/cart/presentation/bloc/cart_event.dart';
import 'package:flutter_application_1/features/cart/presentation/pages/cart_page.dart';
import 'package:flutter_application_1/features/checkout/presentation/pages/checkout_page.dart';
import 'package:flutter_application_1/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:flutter_application_1/features/orders/presentation/bloc/order_bloc.dart';
import 'package:flutter_application_1/features/orders/presentation/bloc/order_event.dart';
import 'package:flutter_application_1/features/orders/presentation/pages/orders_page.dart';
import 'package:flutter_application_1/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_application_1/features/profile/presentation/bloc/address_cubit.dart';
import 'package:flutter_application_1/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

Widget _createTestApp({required Widget child}) {
  final sl = ServiceLocator.instance;
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>.value(value: sl.themeCubit),
      BlocProvider<LocaleCubit>.value(value: sl.localeCubit),
      BlocProvider<AuthBloc>.value(value: sl.authBloc),
      BlocProvider<ProductBloc>.value(value: sl.productBloc),
      BlocProvider<CartBloc>.value(value: sl.cartBloc),
      BlocProvider<WishlistBloc>.value(value: sl.wishlistBloc),
      BlocProvider<OrderBloc>.value(value: sl.orderBloc),
      BlocProvider<AddressCubit>.value(value: sl.addressCubit),
      BlocProvider<NotificationCubit>.value(value: sl.notificationCubit),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ServiceLocator.instance.init(preferences: prefs, force: true);
  });

  group('End-to-End (E2E) Checkout Journey', () {
    testWidgets('Complete journey: Browse -> Cart -> Checkout -> Place Order -> Verify in Orders',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sl = ServiceLocator.instance;

      // 1. Setup sample baby product
      const testProduct = Product(
        id: 'e2e-baby-romper',
        title: 'Organic Cotton Newborn Romper',
        description: 'Ultra-soft 100% organic cotton romper with easy snap buttons.',
        price: 24.50,
        originalPrice: 32.00,
        image: 'Assets/categories_icon/clothing.png',
        images: ['Assets/categories_icon/clothing.png'],
        category: 'Clothing',
        rating: 4.9,
        ratingCount: 128,
        availableColors: ['Sky Blue'],
        availableSizes: ['3-6M'],
        reviews: [],
      );

      // 2. Add product to cart
      sl.cartBloc.add(const CartItemAdded(
        product: testProduct,
        color: 'Sky Blue',
        size: '3-6M',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sl.cartBloc.state.itemCount, 1);
      expect(sl.cartBloc.state.items.first.product.id, 'e2e-baby-romper');

      // 3. Render Cart Page and verify item appears
      await tester.pumpWidget(_createTestApp(child: const CartPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Organic Cotton Newborn Romper'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);

      // 4. Render Checkout Page
      final cartItem = sl.cartBloc.state.items.first;
      await tester.pumpWidget(_createTestApp(child: const CheckoutPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Checkout UI elements
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('Payment Method'), findsWidgets);
      expect(find.text('Order Summary'), findsOneWidget);

      // 5. Place order directly via OrderBloc to complete checkout transaction
      const deliveryAddress = '#123 Preah Norodom Blvd, BKK1, Phnom Penh, Cambodia';

      OrderModel? placedOrder;
      sl.orderBloc.add(
        OrderPlaced(
          items: [cartItem],
          subtotal: 24.50,
          discount: 2.45,
          shipping: 1.50,
          tax: 1.88,
          total: 25.43,
          deliveryAddress: deliveryAddress,
          paymentMethod: 'Cash on Delivery',
          exchangeRate: 4100.0,
          onComplete: (order) {
            placedOrder = order;
          },
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(placedOrder, isNotNull);
      expect(placedOrder!.total, 25.43);
      expect(sl.orderBloc.state.orders.length, 1);

      // 6. Verify Push Notification was dispatched and logged in notification center
      expect(sl.notificationCubit.state.notifications.any((n) => n.orderId == placedOrder!.id), true);

      // 7. Render OrdersPage and verify the placed order is listed
      await tester.pumpWidget(_createTestApp(child: const OrdersPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Order History'), findsOneWidget);
      expect(find.text(placedOrder!.displayOrderCode), findsOneWidget);
    });
  });
}
