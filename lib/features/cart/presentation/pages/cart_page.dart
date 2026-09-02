import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/review_requirement_service.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../../orders/presentation/pages/pending_reviews_page.dart';
import '../widgets/cart_item_tile.dart';

class CartPage extends StatelessWidget {
  final VoidCallback? onBrowseMore;

  const CartPage({super.key, this.onBrowseMore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Bag'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(CupertinoIcons.trash, size: 20),
                tooltip: 'Clear Cart',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Clear Shopping Bag?'),
                      content: const Text(
                        'Are you sure you want to remove all items from your bag?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<CartBloc>().add(const CartCleared());
                            Navigator.of(ctx).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.discountRed,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.bag,
                        size: 56,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Bag is Empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looks like you haven\'t added any baby essentials yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: onBrowseMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(CupertinoIcons.compass, size: 18),
                      label: const Text(
                        'Start Shopping',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final itemsSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<OrderBloc, OrderState>(
                builder: (context, orderState) {
                  final pendingCount = orderState.pendingReviewItems.length;
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warmAmber.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warmAmber.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warmAmber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingCount delivered item${pendingCount == 1 ? '' : 's'} must be rated before checkout.',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PendingReviewsPage()),
                          ),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text('Rate Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Items list
              ...cartState.items.map((item) => CartItemTile(cartItem: item)),
            ],
          );

          final summarySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 20 : 6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryRow(
                      'Subtotal (${cartState.itemCount} items)',
                      '\$${cartState.subtotal.toStringAsFixed(2)}',
                      isDark,
                    ),
                    if (cartState.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Promo Discount',
                        '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                        isDark,
                        isDiscount: true,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Estimated Delivery',
                      cartState.shippingFee == 0
                          ? 'FREE'
                          : '\$${cartState.shippingFee.toStringAsFixed(2)}',
                      isDark,
                      isFree: cartState.shippingFee == 0,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Estimated Tax (8%)',
                      '\$${cartState.taxAmount.toStringAsFixed(2)}',
                      isDark,
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '\$${cartState.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    if (isWide) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            _startCheckout(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.arrow_right, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          if (isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: itemsSection),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: summarySection),
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                itemsSection,
                const SizedBox(height: 16),
                summarySection,
              ],
            ),
          );
        },
      ),
      bottomSheet: isWide
          ? null
          : BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                if (cartState.items.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 15),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '\$${cartState.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _startCheckout(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Checkout Now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(CupertinoIcons.arrow_right, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _startCheckout(BuildContext context) {
    AuthGuard.requireAuth(
      context,
      title: 'Sign In to Checkout',
      message: 'Please sign in or create an account to complete your checkout.',
      onAuthenticated: () async {
        final pending = await ReviewRequirementService.getPendingReviewItems();
        if (!context.mounted) return;

        if (pending.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PendingReviewsPage(),
            ),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CheckoutPage(),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount
                ? AppColors.discountRed
                : isFree
                    ? AppColors.successGreen
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
