import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_event.dart';
import '../../../../features/orders/presentation/bloc/order_state.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_event.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/product_review_service.dart';
import '../../../../core/services/review_requirement_service.dart';
import '../../../products/domain/entities/product_entity.dart';

class PendingReviewsPage extends StatefulWidget {
  const PendingReviewsPage({super.key});

  @override
  State<PendingReviewsPage> createState() => _PendingReviewsPageState();
}

class _PendingReviewsPageState extends State<PendingReviewsPage> {
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _submitting = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderBloc>().add(const OrderPendingReviewsRefreshed());
    });
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _commentControllerFor(PendingReviewItem item) {
    return _commentControllers.putIfAbsent(
      item.key,
      () => TextEditingController(),
    );
  }

  Future<void> _submitReview(PendingReviewItem item) async {
    final rating = _ratings[item.key] ?? 0;
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a star rating before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _submitting.add(item.key);
    });

    final comment = _commentControllerFor(item).text.trim();
    final user = context.read<AuthBloc>().state.currentUser;
    final review = ProductReviewEntity(
      userName: user?.name.isNotEmpty == true ? user!.name : 'Verified Buyer',
      userAvatar: '',
      rating: rating.toDouble(),
      comment: comment.isNotEmpty ? comment : 'Rated after delivery.',
      date: _formatToday(),
    );

    context.read<ProductBloc>().add(ProductAddReviewRequested(
          productId: item.productId,
          review: review,
        ));

    await ProductReviewService.submitReview(
      productId: item.productId,
      rating: rating.toDouble(),
      comment: review.comment,
      authToken: user?.token,
    );

    await ReviewRequirementService.markRated(
      orderId: item.orderId,
      productId: item.productId,
    );

    if (!mounted) return;

    _commentControllers.remove(item.key)?.dispose();
    _ratings.remove(item.key);
    _submitting.remove(item.key);
    context.read<OrderBloc>().add(const OrderPendingReviewsRefreshed());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you. Your review was submitted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Ratings'),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, orderState) {
          final pending = orderState.pendingReviewItems;

          if (pending.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.successGreen,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All Ratings Complete',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can continue shopping and place new orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = pending[index];
              return _buildReviewCard(item, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(PendingReviewItem item, bool isDark) {
    final rating = _ratings[item.key] ?? 0;
    final isSubmitting = _submitting.contains(item.key);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64,
                  height: 64,
                  color: isDark ? AppColors.surfaceSoftDark : const Color(0xFFF1F5F9),
                  child: item.productImage.isNotEmpty
                      ? Image.network(
                          item.productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.shopping_bag_outlined),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ${item.orderId.replaceAll('#', '')}',
                      style: TextStyle(
                        fontSize: 12,
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
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 42, height: 42),
                icon: Icon(
                  star <= rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.warmAmber,
                  size: 34,
                ),
                onPressed: isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _ratings[item.key] = star;
                        });
                      },
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentControllerFor(item),
            enabled: !isSubmitting,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : () => _submitReview(item),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Rating'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
