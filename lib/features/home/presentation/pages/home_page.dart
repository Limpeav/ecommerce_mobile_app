import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../../../features/notifications/presentation/bloc/notification_state.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_event.dart';
import '../../../../features/products/presentation/bloc/product_state.dart';
import '../../../../core/theme/bloc/theme_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product.dart';
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

class _HomePageState extends State<HomePage> {
  int _secondsRemaining = 4 * 3600 + 28 * 60 + 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _runAddToCartAnimation(GlobalKey sourceKey, Product product) {
    if (!mounted) return;
    context.read<CartBloc>().add(CartItemAdded(product: product));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.title} to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
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

                                  return Column(
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
                                          fontSize: 13,
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
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions: Theme toggle & Notifications
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
                                    size: 25,
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
                                    return IconButton(
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Notifications',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const NotificationCenterPage(),
                                          ),
                                        );
                                      },
                                      icon: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.bell,
                                            size: 25,
                                          ),
                                          if (unread > 0)
                                            Positioned(
                                              top: -4,
                                              right: -6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 4.5,
                                                  vertical: 1.5,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 17,
                                                  minHeight: 17,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE53935),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x33E53935),
                                                      blurRadius: 3,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    unread > 99 ? '99+' : '$unread',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w900,
                                                      height: 1.0,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
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


