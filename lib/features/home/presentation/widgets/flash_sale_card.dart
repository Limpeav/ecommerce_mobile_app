import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/cart_fly_animation.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../product_details/presentation/pages/product_details_page.dart';

class FlashSaleCard extends StatelessWidget {
  final Product product;
  final GlobalKey? cartTargetKey;
  final void Function(GlobalKey sourceKey, Product product)? onAddToCartAnimate;

  const FlashSaleCard({
    super.key,
    required this.product,
    this.cartTargetKey,
    this.onAddToCartAnimate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonKey = GlobalKey();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: product,
              heroTag: 'flash_sale_${product.id}',
            ),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: AppCachedImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      height: 120,
                      width: double.infinity,
                    ),
                  ),
                ),
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.discountRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discountPercentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (product.originalPrice != null && product.discountPercentage > 0)
                              Text(
                                '\$${product.originalPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Material(
                        key: buttonKey,
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () {
                            AuthGuard.requireAuth(
                              context,
                              title: 'Sign In to Buy',
                              message: 'Please sign in to add items to your cart and proceed with orders.',
                              onAuthenticated: () {
                                if (onAddToCartAnimate != null) {
                                  onAddToCartAnimate!(buttonKey, product);
                                } else if (cartTargetKey != null) {
                                  CartFlyAnimation.run(
                                    context: context,
                                    sourceKey: buttonKey,
                                    targetKey: cartTargetKey!,
                                    imageUrl: product.image,
                                    onComplete: () {
                                      context.read<CartBloc>().add(CartItemAdded(product: product));
                                    },
                                  );
                                } else {
                                  context.read<CartBloc>().add(CartItemAdded(product: product));
                                }
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${product.title}" to cart'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.cart_badge_plus,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress stock bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (product.stock / 50).clamp(0.15, 0.9),
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.discountRed),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.stock} items left',
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
