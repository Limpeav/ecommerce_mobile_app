import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_event.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/category_assets.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/cart_fly_animation.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../product_details/presentation/pages/product_details_page.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool compact;
  final String? heroTagPrefix;
  final GlobalKey? cartTargetKey;
  final void Function(GlobalKey sourceKey, Product product)? onAddToCartAnimate;

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.heroTagPrefix,
    this.cartTargetKey,
    this.onAddToCartAnimate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroTag = '${heroTagPrefix ?? 'prod'}_img_${product.id}';
    final buttonKey = GlobalKey();

    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, wishlistState) {
        final isFav = wishlistState.isFavorite(product.id);

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailsPage(product: product, heroTag: heroTag),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Stack(
                  children: [
                    Container(
                      height: compact ? 130 : 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Hero(
                          tag: heroTag,
                          child: AppCachedImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            height: compact ? 130 : 160,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),

                    // Discount Tag
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.discountRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discountPercentage}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AuthGuard.requireAuth(
                              context,
                              title: 'Sign In to Save Favorites',
                              message:
                                  'Please sign in or create an account to save items to your wishlist.',
                              onAuthenticated: () {
                                context.read<WishlistBloc>().add(
                                  WishlistToggleRequested(product: product),
                                );
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFav
                                          ? 'Removed from wishlist'
                                          : 'Added to wishlist',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withAlpha(150)
                                  : Colors.white.withAlpha(220),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: isFav
                                  ? AppColors.discountRed
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CategoryIconWidget(
                                  category: product.category,
                                  size: 11,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    product.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppColors.accent,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Title
                            Text(
                              product.title,
                              style: TextStyle(
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        // Rating & Price row
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  size: 13,
                                  color: AppColors.warmAmber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${product.ratingCount})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Price and Add to Cart
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      if (product.originalPrice != null &&
                                          product.discountPercentage > 0)
                                        Text(
                                          '\$${product.originalPrice!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Quick Add Button
                                Material(
                                  key: buttonKey,
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      AuthGuard.requireAuth(
                                        context,
                                        title: 'Sign In to Buy',
                                        message:
                                            'Please sign in to add items to your cart and proceed with orders.',
                                        onAuthenticated: () {
                                          if (onAddToCartAnimate != null) {
                                            onAddToCartAnimate!(
                                              buttonKey,
                                              product,
                                            );
                                          } else if (cartTargetKey != null) {
                                            CartFlyAnimation.run(
                                              context: context,
                                              sourceKey: buttonKey,
                                              targetKey: cartTargetKey!,
                                              imageUrl: product.image,
                                              onComplete: () {
                                                context.read<CartBloc>().add(
                                                  CartItemAdded(
                                                    product: product,
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            context.read<CartBloc>().add(
                                              CartItemAdded(product: product),
                                            );
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).clearSnackBars();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Added "${product.title}" to cart',
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        CupertinoIcons.cart_badge_plus,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
