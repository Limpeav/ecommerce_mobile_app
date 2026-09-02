import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_state.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_event.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/category_assets.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import 'product_reviews_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final String? heroTag;

  const ProductDetailsPage({super.key, required this.product, this.heroTag});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _selectedImageIndex = 0;
  late String _selectedColor;
  late String _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.availableColors.isNotEmpty
        ? widget.product.availableColors.first
        : 'Default';
    _selectedSize = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes.first
        : 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        final product =
            productState.getProductById(widget.product.id) ?? widget.product;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              BlocBuilder<WishlistBloc, WishlistState>(
                builder: (context, wishlistState) {
                  final isFav = wishlistState.isFavorite(product.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.discountRed : null,
                    ),
                    onPressed: () {
                      AuthGuard.requireAuth(
                        context,
                        title: 'Sign In to Save Favorites',
                        message:
                            'Please sign in or create an account to add this product to your wishlist.',
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
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product link copied to clipboard!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Preview Container
                Container(
                  height: 320,
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: product.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: widget.heroTag ?? 'prod_img_${product.id}',
                            child: AppCachedImage(
                              imageUrl: product.images[index],
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                      // Image pagination indicator
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _selectedImageIndex == idx ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _selectedImageIndex == idx
                                      ? AppColors.accent
                                      : Colors.grey.withAlpha(100),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Stock Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CategoryIconWidget(
                                  category: product.category,
                                  size: 13,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  product.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: AppColors.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'In Stock (${product.stock})',
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Product Title
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rating & Reviews row with button/tap to open reviews page
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductReviewsPage(product: product),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.warmAmber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${product.ratingCount} reviews)',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceSoftDark
                                          : AppColors.accentLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Reviews',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 14,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (product.originalPrice != null && product.discountPercentage > 0) ...[
                            Text(
                              '\$${product.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.discountRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SAVE ${product.discountPercentage}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 32),

                      // Color Variant Selector (if available)
                      if (product.availableColors.isNotEmpty) ...[
                        const Text(
                          'Color Variant',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.availableColors.map((color) {
                            final isSelected = _selectedColor == color;
                            return ChoiceChip(
                              label: Text(color),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedColor = color;
                                  });
                                }
                              },
                              selectedColor: AppColors.accent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Size Variant Selector (if available)
                      if (product.availableSizes.isNotEmpty) ...[
                        const Text(
                          'Size / Specification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.availableSizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return ChoiceChip(
                              label: Text(size),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSize = size;
                                  });
                                }
                              },
                              selectedColor: AppColors.accent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Quantity Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: _quantity > 1
                                      ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      : null,
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: _quantity < product.stock
                                      ? () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Description
                      const Text(
                        'About This Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(
                        height: 80,
                      ), // padding for sticky bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Add to Cart Secondary Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        AuthGuard.requireAuth(
                          context,
                          title: 'Sign In to Buy',
                          message:
                              'Please sign in or create an account before adding items to your cart.',
                          onAuthenticated: () {
                            context.read<CartBloc>().add(
                              CartItemAdded(
                                product: product,
                                quantity: _quantity,
                                color: _selectedColor,
                                size: _selectedSize,
                              ),
                            );
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${widget.product.title} to cart',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'VIEW CART',
                                  textColor: AppColors.accent,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: AppColors.accent,
                      ),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Buy Now Primary Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        AuthGuard.requireAuth(
                          context,
                          title: 'Sign In to Checkout',
                          message:
                              'Please sign in or create an account to proceed directly with your order.',
                          onAuthenticated: () {
                            context.read<CartBloc>().add(
                              CartItemAdded(
                                product: product,
                                quantity: _quantity,
                                color: _selectedColor,
                                size: _selectedSize,
                              ),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutPage(),
                              ),
                            );
                          },
                        );
                      },
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
