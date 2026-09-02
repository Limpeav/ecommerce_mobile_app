import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/pages/complete_phone_page.dart';
import '../../cart/presentation/pages/cart_page.dart';
import '../../catalog/presentation/pages/catalog_page.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../wishlist/presentation/pages/wishlist_page.dart';

import '../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../features/orders/presentation/bloc/order_event.dart';
import '../../../features/orders/presentation/bloc/order_state.dart';
import '../../../core/services/review_requirement_service.dart';
import '../../orders/presentation/pages/pending_reviews_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  bool _focusExploreSearch = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhoneRequirement();
    });
  }

  void _checkPhoneRequirement() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.currentUser != null &&
        authState.currentUser!.phone.trim().isEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompletePhonePage()),
        (route) => false,
      );
    }
  }

  void _showDeliveredReviewPrompt(PendingReviewItem item) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PendingReviewsPage()),
    );
  }

  @override
  void didUpdateWidget(covariant MainNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  void _onTabTapped(int index, {bool focusSearch = false}) {
    setState(() {
      _currentIndex = index;
      _focusExploreSearch = (index == 1 && focusSearch);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      HomePage(onTabChange: _onTabTapped),
      CatalogPage(
        focusSearchOnOpen: _focusExploreSearch,
        onSearchFocusHandled: () {
          if (_focusExploreSearch) {
            setState(() {
              _focusExploreSearch = false;
            });
          }
        },
      ),
      CartPage(onBrowseMore: () => _onTabTapped(1)),
      WishlistPage(onBrowseMore: () => _onTabTapped(1)),
      ProfilePage(onTabChange: (idx) => _onTabTapped(idx)),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState.status == AuthStatus.authenticated &&
                authState.currentUser != null &&
                authState.currentUser!.phone.trim().isEmpty) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CompletePhonePage()),
                (route) => false,
              );
            }
          },
        ),
        BlocListener<OrderBloc, OrderState>(
          listener: (context, orderState) {
            final prompt = orderState.deliveryReviewPrompt;
            if (prompt == null) return;
            context.read<OrderBloc>().add(const OrderDeliveryReviewPromptCleared());
            _showDeliveredReviewPrompt(prompt);
          },
        ),
      ],
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            return BlocBuilder<WishlistBloc, WishlistState>(
              builder: (context, wishlistState) {
                final cartCount = cartState.itemCount;
                final wishlistCount = wishlistState.count;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 10),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabTapped,
                    backgroundColor: Colors.transparent,
                    indicatorColor: AppColors.accent.withAlpha(30),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(CupertinoIcons.house),
                        selectedIcon: const Icon(
                          CupertinoIcons.house_fill,
                          color: AppColors.accent,
                        ),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: const Icon(CupertinoIcons.compass),
                        selectedIcon: const Icon(
                          CupertinoIcons.compass_fill,
                          color: AppColors.accent,
                        ),
                        label: 'Explore',
                      ),
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: cartCount > 0,
                          label: Text(
                            '$cartCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.accent,
                          child: const Icon(CupertinoIcons.bag),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: cartCount > 0,
                          label: Text(
                            '$cartCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.accent,
                          child: const Icon(
                            CupertinoIcons.bag_fill,
                            color: AppColors.accent,
                          ),
                        ),
                        label: 'Bag',
                      ),
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: wishlistCount > 0,
                          label: Text(
                            '$wishlistCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.discountRed,
                          child: const Icon(CupertinoIcons.heart),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: wishlistCount > 0,
                          label: Text(
                            '$wishlistCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.discountRed,
                          child: const Icon(
                            CupertinoIcons.heart_fill,
                            color: AppColors.discountRed,
                          ),
                        ),
                        label: 'Saved',
                      ),
                      NavigationDestination(
                        icon: const Icon(CupertinoIcons.person),
                        selectedIcon: const Icon(
                          CupertinoIcons.person_fill,
                          color: AppColors.accent,
                        ),
                        label: 'Profile',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
