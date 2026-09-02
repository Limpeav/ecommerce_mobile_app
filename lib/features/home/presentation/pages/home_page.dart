import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../../../features/notifications/presentation/bloc/notification_state.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_event.dart';
import '../../../../features/products/presentation/bloc/product_state.dart';
import '../../../../core/theme/bloc/theme_cubit.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/cart_fly_animation.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../../notifications/presentation/pages/notification_center_page.dart';
import '../widgets/category_pill.dart';
import '../widgets/flash_sale_card.dart';
import '../widgets/promo_banner.dart';

class HomePage extends StatefulWidget {
  final void Function(int index, {bool focusSearch}) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 4 * 3600 + 28 * 60 + 15;
  Timer? _timer;
  final GlobalKey _cartKey = GlobalKey();
  late AnimationController _cartBounceController;
  late Animation<double> _cartBounceScale;

  @override
  void initState() {
    super.initState();
    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cartBounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_cartBounceController);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cartBounceController.dispose();
    super.dispose();
  }

  void _runAddToCartAnimation(GlobalKey sourceKey, Product product) {
    CartFlyAnimation.run(
      context: context,
      sourceKey: sourceKey,
      targetKey: _cartKey,
      imageUrl: product.image,
      onComplete: () {
        if (!mounted) return;
        context.read<CartBloc>().add(CartItemAdded(product: product));
        _cartBounceController.forward(from: 0.0);
      },
    );
  }

  String _formatTimer(int totalSecs) {
    final hours = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSecs % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'clothing':
      case 'fashion':
      case 'baby clothing':
      case 'rompers':
      case "men's clothing":
      case "women's clothing":
        return Icons.checkroom_rounded;
      case 'travel & gear':
      case 'strollers':
      case 'gear':
        return Icons.child_friendly_rounded;
      case 'furniture':
      case 'home & decor':
      case 'cribs':
      case 'nursery':
        return Icons.crib_rounded;
      case 'bath & skin':
      case 'bath':
      case 'skincare':
        return Icons.bathtub_rounded;
      case 'toy & play':
      case 'toys':
        return Icons.toys_rounded;
      case 'diapering & care':
      case 'diapering':
      case 'diapers':
        return Icons.baby_changing_station_rounded;
      case 'milk':
      case 'feeding & nursing':
      case 'feeding':
      case 'bottles':
        return Icons.local_drink_rounded;
      case 'shoes':
      case 'shoe':
      case 'footwear':
      case 'booties':
      case 'sneakers':
      case 'sandals':
        return Icons.roller_skating_rounded;
      case 'all':
        return Icons.child_care_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: isMobile
          ? PreferredSize(
              preferredSize: const Size.fromHeight(128),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Greeting & Brand
                            Expanded(
                              child: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, authState) {
                                  final isAuth =
                                      authState.status == AuthStatus.authenticated;
                                  final userName = authState.currentUser?.name.split(' ').first ?? '';

                                  return Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(isDark ? 30 : 10),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'Assets/splash_screen/app_icon.png',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isAuth && userName.isNotEmpty
                                                  ? 'Hello, $userName 👋'
                                                  : 'Welcome to Cherish 👋',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                            const Text(
                                              'Cherish Baby Store',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions: Theme toggle, Wishlist badge & Cart badge
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isDark
                                        ? CupertinoIcons.sun_max_fill
                                        : CupertinoIcons.moon_fill,
                                    size: 20,
                                    color: isDark ? AppColors.warmAmber : null,
                                  ),
                                  onPressed: () {
                                    context.read<ThemeCubit>().toggleTheme();
                                  },
                                ),
                                const SizedBox(width: 4),
                                BlocBuilder<NotificationCubit, NotificationState>(
                                  builder: (context, notifState) {
                                    final unread = notifState.unreadCount;
                                    return Badge(
                                      isLabelVisible: unread > 0,
                                      label: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: AppColors.accent,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          CupertinoIcons.bell,
                                          size: 21,
                                        ),
                                        tooltip: 'Notifications',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const NotificationCenterPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                BlocBuilder<WishlistBloc, WishlistState>(
                                  builder: (context, wishlistState) {
                                    final wishCount = wishlistState.count;
                                    return Badge(
                                      isLabelVisible: wishCount > 0,
                                      label: Text(
                                        '$wishCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: AppColors.discountRed,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          CupertinoIcons.heart,
                                          size: 21,
                                        ),
                                        onPressed: () => widget.onTabChange(3),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                BlocBuilder<CartBloc, CartState>(
                                  builder: (context, cartState) {
                                    final count = cartState.itemCount;
                                    return ScaleTransition(
                                      scale: _cartBounceScale,
                                      child: Stack(
                                        key: _cartKey,
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              CupertinoIcons.bag,
                                              size: 21,
                                            ),
                                            onPressed: () => widget.onTabChange(2),
                                          ),
                                          if (count > 0)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  '$count',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Search Trigger Bar
                        GestureDetector(
                          onTap: () {
                            widget.onTabChange(1, focusSearch: true);
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceSoftDark
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.search,
                                  color: AppColors.accent,
                                  size: 17,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Search clothes, cribs, skincare, toys...',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Explore',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, productState) {
          if (productState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              context.read<ProductBloc>().add(const ProductRefreshRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hero Promo Banner
                        PromoBanner(
                          banners: productState.banners,
                          onShopNow: () => widget.onTabChange(1),
                        ),

                        const SizedBox(height: 20),

                        // 3. Category Showcase
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shop by Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<ProductBloc>().add(
                                  const ProductCategorySelected('All'),
                                );
                                widget.onTabChange(1);
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: productState.categories.map((cat) {
                              final isSelected =
                                  productState.selectedCategory == cat;
                              return CategoryPill(
                                title: cat,
                                icon: _getCategoryIcon(cat),
                                isSelected: isSelected,
                                onTap: () {
                                  context.read<ProductBloc>().add(
                                    ProductCategorySelected(cat),
                                  );
                                  widget.onTabChange(1);
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // 4. Flash Sale Section
                        if (productState.flashDeals.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '⚡ Flash Deals',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.discountRedLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.discountRed.withAlpha(40),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.timer,
                                          size: 12,
                                          color: AppColors.discountRed,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimer(_secondsRemaining),
                                          style: const TextStyle(
                                            color: AppColors.discountRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<ProductBloc>().add(
                                    const ProductSortChanged(
                                      SortOption.priceLowToHigh,
                                    ),
                                  );
                                  widget.onTabChange(1);
                                },
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: productState.flashDeals.length,
                              itemBuilder: (context, index) {
                                final product = productState.flashDeals[index];
                                return FlashSaleCard(
                                  product: product,
                                  cartTargetKey: _cartKey,
                                  onAddToCartAnimate: _runAddToCartAnimation,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                        ],

                        // 5. Featured / Top Highlights Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🔥 Popular Essentials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<ProductBloc>().add(
                                  const ProductRatingFilterChanged(4.5),
                                );
                                widget.onTabChange(1);
                              },
                              child: const Text('Explore All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 4,
                            childAspectRatio: isMobile ? 0.62 : 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: productState.featuredProducts.length.clamp(
                            0,
                            isMobile ? 6 : 8,
                          ),
                          itemBuilder: (context, index) {
                            final product = productState.featuredProducts[index];
                            return ProductCard(
                              product: product,
                              heroTagPrefix: 'home_featured',
                              cartTargetKey: _cartKey,
                              onAddToCartAnimate: _runAddToCartAnimation,
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


}


