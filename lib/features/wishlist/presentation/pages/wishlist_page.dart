import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class WishlistPage extends StatelessWidget {
  final VoidCallback? onBrowseMore;

  const WishlistPage({super.key, this.onBrowseMore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved & Wishlist'),
        actions: [
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, wishlistState) {
              final items = wishlistState.items;
              if (items.isEmpty) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () {
                  AuthGuard.requireAuth(
                    context,
                    title: 'Sign In to Buy',
                    message:
                        'Please sign in to transfer your saved items to cart and checkout.',
                    onAuthenticated: () {
                      for (var p in items) {
                        context.read<CartBloc>().add(CartItemAdded(product: p));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${items.length} items to your shopping bag!'),
                          backgroundColor: AppColors.accent,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(CupertinoIcons.cart_badge_plus, size: 18),
                label: const Text('Add All to Bag'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, wishlistState) {
          final items = wishlistState.items;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceSoftDark
                            : AppColors.discountRed.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.heart,
                        size: 64,
                        color: AppColors.discountRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Saved List is Empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save baby essentials you love by tapping the heart icon on any product card.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: onBrowseMore ?? () => Navigator.of(context).pop(),
                      icon: const Icon(CupertinoIcons.compass),
                      label: const Text('Explore Catalog'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} saved ${items.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'In Stock',
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
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    childAspectRatio: isMobile ? 0.62 : 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: items[index],
                      heroTagPrefix: 'wishlist',
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
