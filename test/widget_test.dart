import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/constants/category_assets.dart';
import 'package:flutter_application_1/features/profile/presentation/bloc/address_cubit.dart';
import 'package:flutter_application_1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:flutter_application_1/features/cart/presentation/bloc/cart_event.dart';
import 'package:flutter_application_1/features/orders/presentation/bloc/order_bloc.dart';
import 'package:flutter_application_1/features/orders/presentation/bloc/order_event.dart';
import 'package:flutter_application_1/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_application_1/features/products/presentation/bloc/product_event.dart';
import 'package:flutter_application_1/core/theme/bloc/theme_cubit.dart';
import 'package:flutter_application_1/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:flutter_application_1/features/wishlist/presentation/bloc/wishlist_event.dart';
import 'package:flutter_application_1/core/di/service_locator.dart';
import 'package:flutter_application_1/core/models/cart_item.dart';
import 'package:flutter_application_1/core/models/product.dart';
import 'package:flutter_application_1/core/models/order.dart';
import 'package:flutter_application_1/core/services/review_requirement_service.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/verify_account_page.dart';
import 'package:flutter_application_1/features/checkout/presentation/pages/checkout_page.dart';
import 'package:flutter_application_1/features/checkout/presentation/widgets/map_location_picker_sheet.dart';
import 'package:flutter_application_1/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:flutter_application_1/features/orders/presentation/pages/orders_page.dart';
import 'package:flutter_application_1/features/orders/presentation/pages/pending_reviews_page.dart';
import 'package:flutter_application_1/features/products/data/datasources/product_remote_datasource.dart';

Widget _buildTestApp({required Widget child}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>.value(value: ServiceLocator.instance.themeCubit),
      BlocProvider<AuthBloc>.value(value: ServiceLocator.instance.authBloc),
      BlocProvider<ProductBloc>.value(value: ServiceLocator.instance.productBloc),
      BlocProvider<CartBloc>.value(value: ServiceLocator.instance.cartBloc),
      BlocProvider<WishlistBloc>.value(value: ServiceLocator.instance.wishlistBloc),
      BlocProvider<OrderBloc>.value(value: ServiceLocator.instance.orderBloc),
      BlocProvider<AddressCubit>.value(value: ServiceLocator.instance.addressCubit),
      BlocProvider<NotificationCubit>.value(value: ServiceLocator.instance.notificationCubit),
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

  group('Clean Architecture - Domain & Data Layer Tests', () {
    test('GetProductsUseCase returns list of product entities from repository', () async {
      final useCase = ServiceLocator.instance.getProductsUseCase;
      final products = await useCase();

      expect(products.isNotEmpty, true);
      expect(products.first.id, '6a6c6019382bd53f1e45a7b1');
      expect(products.first.title.isNotEmpty, true);
    });

    test('ProductRepository gets individual product by ID', () async {
      final repo = ServiceLocator.instance.productRepository;
      final product = await repo.getProductById('6965df69241e5bb141e8bf0a');

      expect(product, isNotNull);
      expect(product!.id, '6965df69241e5bb141e8bf0a');
      expect(product.category, 'Toys');
    });

    test('CategoryAssetHelper maps shoes category to shoes.png asset', () {
      expect(
        CategoryAssetHelper.getAssetPath('Shoes'),
        'Assets/categories_icon/shoes.png',
      );
      expect(
        CategoryAssetHelper.getAssetPath('shoes'),
        'Assets/categories_icon/shoes.png',
      );
    });

    test('CategoryAssetHelper maps milk category to milk icon asset', () {
      expect(
        CategoryAssetHelper.getAssetPath('Milk'),
        'Assets/categories_icon/5eef4eaa2330203a89f01ddbc89298c8-removebg-preview.png',
      );
      expect(
        CategoryAssetHelper.getAssetPath('milk'),
        'Assets/categories_icon/5eef4eaa2330203a89f01ddbc89298c8-removebg-preview.png',
      );
    });
  });

  group('CartBloc Unit Tests', () {
    late CartBloc cartBloc;
    late Product sampleProduct;

    setUp(() {
      cartBloc = CartBloc();
      sampleProduct = ProductRemoteDataSourceImpl.getMockProductModels().first;
    });

    test('Initial cart is empty', () {
      expect(cartBloc.state.items.isEmpty, true);
      expect(cartBloc.state.itemCount, 0);
      expect(cartBloc.state.total, 0.0);
    });

    test('Add item to cart increments item count and computes subtotal', () async {
      cartBloc.add(CartItemAdded(product: sampleProduct, quantity: 2));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(cartBloc.state.items.length, 1);
      expect(cartBloc.state.itemCount, 2);
      expect(cartBloc.state.subtotal, sampleProduct.price * 2);
    });

    test('Applying SAVE20 promo code applies 20% discount', () async {
      cartBloc.add(CartItemAdded(product: sampleProduct, quantity: 1));
      cartBloc.add(const CartPromoCodeApplied('SAVE20'));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(cartBloc.state.appliedPromoCode, 'SAVE20');
      expect(cartBloc.state.discountAmount, closeTo(sampleProduct.price * 0.20, 0.01));
    });

    test('Clearing cart resets all items and coupons', () async {
      cartBloc.add(CartItemAdded(product: sampleProduct, quantity: 2));
      cartBloc.add(const CartPromoCodeApplied('SAVE20'));
      cartBloc.add(const CartCleared());
      await Future.delayed(const Duration(milliseconds: 10));
      expect(cartBloc.state.items.isEmpty, true);
      expect(cartBloc.state.appliedPromoCode, null);
    });
  });

  group('WishlistBloc Unit Tests', () {
    test('Toggling wishlist adds and removes products', () async {
      final wishlistBloc = WishlistBloc();
      final product = ProductRemoteDataSourceImpl.getMockProductModels().first;

      expect(wishlistBloc.state.isFavorite(product.id), false);
      wishlistBloc.add(WishlistToggleRequested(product: product));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(wishlistBloc.state.isFavorite(product.id), true);
      expect(wishlistBloc.state.count, 1);

      wishlistBloc.add(WishlistToggleRequested(product: product));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(wishlistBloc.state.isFavorite(product.id), false);
      expect(wishlistBloc.state.count, 0);
    });
  });

  group('ThemeCubit Unit Tests', () {
    test('ThemeCubit saves and loads darkMode preference from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'is_dark_mode_preference_v1': true});
      final prefs = await SharedPreferences.getInstance();
      final themeCubit = ThemeCubit(preferences: prefs);

      expect(themeCubit.state.isDarkMode, true);
      expect(themeCubit.state.themeMode, ThemeMode.dark);

      themeCubit.toggleTheme();
      expect(themeCubit.state.isDarkMode, false);
      expect(prefs.getBool('is_dark_mode_preference_v1'), false);
    });
  });

  group('OrderBloc Unit Tests', () {
    test('Placing an order creates an order with tracking and processing status', () async {
      final orderBloc = OrderBloc();
      final product = ProductRemoteDataSourceImpl.getMockProductModels().first;
      final cartItem = CartItem(product: product, quantity: 1);

      orderBloc.add(OrderPlaced(
        items: [cartItem],
        subtotal: product.price,
        discount: 0,
        shipping: 0,
        tax: 0,
        total: product.price,
        deliveryAddress: '123 Test St, San Francisco, CA',
        paymentMethod: 'Cash on Delivery',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(orderBloc.state.orders.isNotEmpty, true);
      final order = orderBloc.state.orders.first;
      expect(order.id.startsWith('#ORD-'), true);
      expect(order.items.length, 1);

      orderBloc.add(OrderMarkedAsPaid(orderId: order.id));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(orderBloc.state.orders.first.isPaid, true);
    });
  });

  group('Auth & Verify Account Page Tests', () {
    testWidgets('VerifyAccountPage renders email, 6-digit pin boxes, and verify button', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const VerifyAccountPage(
            email: 'newuser@gmail.com',
            password: 'Password123!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Account'), findsOneWidget);
      expect(find.text('newuser@gmail.com'), findsOneWidget);
      expect(find.text('Verify Account'), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6));
    });

    test('Wishlist badge updates when item is added', () async {
      final wishlistBloc = ServiceLocator.instance.wishlistBloc;
      final sampleProduct = ProductRemoteDataSourceImpl.getMockProductModels().first;

      wishlistBloc.add(WishlistToggleRequested(product: sampleProduct));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(wishlistBloc.state.count, 1);
    });
  });

  group('Checkout Screen & Map Location Tests', () {
    testWidgets('CheckoutPage renders Shipping Address, Pin Location, Payment, and Order Summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const CheckoutPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cherish Baby Store'), findsOneWidget);
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('PIN LOCATION'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Bakong KHQR'), findsWidgets);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Exchange Rate'), findsOneWidget);
      expect(find.text('1 USD = 4,100 KHR'), findsOneWidget);
      expect(find.text('Place Order'), findsOneWidget);
      expect(find.text('Secure Payment'), findsOneWidget);
    });

    testWidgets('MapLocationPickerSheet renders map controls, delivery location card, and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapLocationPickerSheet(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Confirm delivery location'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
    });
  });

  group('Catalog & FilterModal Tests', () {
    test('ProductBloc filters by category, price, rating, and sorts accurately', () async {
      final productBloc = ProductBloc(getProductsUseCase: ServiceLocator.instance.getProductsUseCase);
      productBloc.add(const ProductLoadRequested());
      await Future.delayed(const Duration(milliseconds: 150));

      expect(productBloc.state.allProducts.isNotEmpty, true);

      // Test Category Filter
      productBloc.add(const ProductCategorySelected('Clothing'));
      await Future.delayed(const Duration(milliseconds: 10));
      for (final p in productBloc.state.filteredProducts) {
        expect(p.category.toLowerCase(), 'clothing');
      }

      // Test Max Price Filter
      productBloc.add(const ProductFiltersReset());
      productBloc.add(const ProductPriceFilterChanged(100.0));
      await Future.delayed(const Duration(milliseconds: 10));
      for (final p in productBloc.state.filteredProducts) {
        expect(p.price <= 100.0, true);
      }

      // Test Min Rating Filter
      productBloc.add(const ProductFiltersReset());
      productBloc.add(const ProductRatingFilterChanged(4.5));
      await Future.delayed(const Duration(milliseconds: 10));
      for (final p in productBloc.state.filteredProducts) {
        expect(p.rating >= 4.5, true);
      }

      // Test Sort: Price Low to High
      productBloc.add(const ProductFiltersReset());
      productBloc.add(const ProductSortChanged(SortOption.priceLowToHigh));
      await Future.delayed(const Duration(milliseconds: 10));
      final sortedLowToHigh = productBloc.state.filteredProducts;
      for (int i = 0; i < sortedLowToHigh.length - 1; i++) {
        expect(sortedLowToHigh[i].price <= sortedLowToHigh[i + 1].price, true);
      }

      // Test Sort: Price High to Low
      productBloc.add(const ProductSortChanged(SortOption.priceHighToLow));
      await Future.delayed(const Duration(milliseconds: 10));
      final sortedHighToLow = productBloc.state.filteredProducts;
      for (int i = 0; i < sortedHighToLow.length - 1; i++) {
        expect(sortedHighToLow[i].price >= sortedHighToLow[i + 1].price, true);
      }
    });

    testWidgets('OrdersPage renders tab filters, search bar, and sync action', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const OrdersPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Order History'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Active ('), findsOneWidget);
      expect(find.textContaining('Delivered ('), findsOneWidget);
      expect(find.textContaining('Cancelled ('), findsOneWidget);
    });

    testWidgets('PendingReviewsPage renders pending reviews UI and empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const PendingReviewsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Required Ratings'), findsOneWidget);
    });

    testWidgets('PendingReviewsPage renders 5 filled stars by default and only one bottom submit button',
        (WidgetTester tester) async {
      // Simulate delivered order with review requirement
      final dummyProduct = Product(
        id: 'prod-item-1',
        title: 'Baby Cotton Romper',
        price: 15.0,
        image: 'https://example.com/romper.jpg',
        images: ['https://example.com/romper.jpg'],
        category: 'clothing',
        description: 'Cotton romper',
        rating: 4.8,
        ratingCount: 10,
        availableColors: ['White'],
        availableSizes: ['0-3M'],
        reviews: [],
      );

      final dummyOrder = OrderModel(
        id: '#ORD-111222',
        date: DateTime.now(),
        items: [CartItem(product: dummyProduct, quantity: 1)],
        subtotal: 15.0,
        discount: 0.0,
        shipping: 0.0,
        tax: 0.0,
        total: 15.0,
        deliveryAddress: 'Phnom Penh',
        paymentMethod: 'Cash on Delivery',
        status: OrderStatus.delivered,
        trackingNumber: 'TRK-111-222',
        estimatedDelivery: 'Sep 3, 2026',
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await ReviewRequirementService.registerDeliveredOrders([dummyOrder]);
        ServiceLocator.instance.orderBloc.add(const OrderPendingReviewsRefreshed());
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpWidget(
        _buildTestApp(
          child: const PendingReviewsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify all 5 stars are filled (Icons.star_rounded) by default
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);

      // Verify exactly ONE submit button exists on the screen
      expect(find.widgetWithText(ElevatedButton, 'Submit Rating'), findsOneWidget);

      // Clean up
      await tester.runAsync(() async {
        await ReviewRequirementService.markRated(orderId: '#ORD-111222', productId: 'prod-item-1');
      });
    });

    test('ReviewRequirementService registers delivered orders and enforces rating requirement', () async {
      SharedPreferences.setMockInitialValues({});
      const dummyProduct = Product(
        id: 'deliv-prod-123',
        title: 'Baby Stroller Deluxe',
        price: 120.0,
        image: 'https://example.com/stroller.jpg',
        images: ['https://example.com/stroller.jpg'],
        category: 'Gear',
        description: 'Test stroller',
        rating: 4.8,
        ratingCount: 10,
        availableColors: ['Blue'],
        availableSizes: ['Standard'],
        reviews: [],
      );

      final deliveredOrder = OrderModel(
        id: '#ORD-999111',
        date: DateTime.now(),
        items: [
          CartItem(product: dummyProduct, quantity: 1),
        ],
        subtotal: 120.0,
        discount: 0.0,
        shipping: 0.0,
        tax: 0.0,
        total: 120.0,
        deliveryAddress: 'Phnom Penh, Cambodia',
        paymentMethod: 'Cash on Delivery',
        status: OrderStatus.delivered,
        trackingNumber: 'EXP-999-111',
        estimatedDelivery: 'Sep 1, 2026',
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );

      // Register delivered order
      final newlyRequired = await ReviewRequirementService.registerDeliveredOrders([deliveredOrder]);
      expect(newlyRequired.length, 1);
      expect(newlyRequired.first.productId, 'deliv-prod-123');

      // Check requirement active
      final hasPending = await ReviewRequirementService.hasPendingReviews();
      expect(hasPending, true);

      // Rate the item
      await ReviewRequirementService.markRated(
        orderId: '#ORD-999111',
        productId: 'deliv-prod-123',
      );

      // Check requirement cleared
      final hasPendingAfter = await ReviewRequirementService.hasPendingReviews();
      expect(hasPendingAfter, false);
    });
  });
}
