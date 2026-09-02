import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/widgets/app_cached_image.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const CartItemTile({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = cartItem.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: AppCachedImage(
                imageUrl: product.image,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info and Quantity Controller
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final userToken = context.read<AuthBloc>().state.currentUser?.token;
                        context.read<CartBloc>().add(CartItemRemoved(
                          item: cartItem,
                          authToken: userToken,
                        ));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Selected variant info
                Text(
                  '${cartItem.selectedColor} • Size: ${cartItem.selectedSize}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),

                // Price and Quantity Adjuster
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              final userToken = context.read<AuthBloc>().state.currentUser?.token;
                              context.read<CartBloc>().add(CartItemQuantityUpdated(
                                item: cartItem,
                                newQuantity: cartItem.quantity - 1,
                                authToken: userToken,
                              ));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.remove, size: 14),
                            ),
                          ),
                          Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final userToken = context.read<AuthBloc>().state.currentUser?.token;
                              context.read<CartBloc>().add(CartItemQuantityUpdated(
                                item: cartItem,
                                newQuantity: cartItem.quantity + 1,
                                authToken: userToken,
                              ));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.add, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
