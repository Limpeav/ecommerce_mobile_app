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
  bool _isSubmittingAll = false;

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

  int _ratingFor(PendingReviewItem item) {
    // 5 filled stars by default as requested
    return _ratings[item.key] ?? 5;
  }

  Future<void> _submitAllReviews(List<PendingReviewItem> items) async {
    if (items.isEmpty || _isSubmittingAll) return;

    setState(() {
      _isSubmittingAll = true;
    });

    final productBloc = context.read<ProductBloc>();
    final orderBloc = context.read<OrderBloc>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = context.read<AuthBloc>().state.currentUser;
      final userName =
          user?.name.isNotEmpty == true ? user!.name : 'Verified Buyer';
      final today = _formatToday();

      for (final item in items) {
        final rating = _ratingFor(item);
        final comment = _commentControllerFor(item).text.trim();
        final review = ProductReviewEntity(
          userName: userName,
          userAvatar: '',
          rating: rating.toDouble(),
          comment: comment.isNotEmpty ? comment : 'Rated 5/5 after delivery.',
          date: today,
        );

        // 1. Add review in ProductBloc
        productBloc.add(ProductAddReviewRequested(
              productId: item.productId,
              review: review,
            ));

        // 2. Submit to backend
        try {
          await ProductReviewService.submitReview(
            productId: item.productId,
            rating: rating.toDouble(),
            comment: review.comment,
            authToken: user?.token,
          );
        } catch (e) {
          debugPrint('⚠️ Error submitting review to backend: $e');
        }

        // 3. Mark as rated
        await ReviewRequirementService.markRated(
          orderId: item.orderId,
          productId: item.productId,
        );
      }

      if (!mounted) return;

      // Clear local controllers and ratings
      for (final controller in _commentControllers.values) {
        controller.dispose();
      }
      _commentControllers.clear();
      _ratings.clear();

      orderBloc.add(const OrderPendingReviewsRefreshed());

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your ratings have been submitted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAll = false;
        });
      }
    }
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back to Orders'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: pending.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = pending[index];
              return _buildReviewCard(item, isDark);
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, orderState) {
          final pending = orderState.pendingReviewItems;
          if (pending.isEmpty) return const SizedBox.shrink();

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingAll
                      ? null
                      : () => _submitAllReviews(pending),
                  icon: _isSubmittingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined, size: 20),
                  label: Text(
                    _isSubmittingAll
                        ? 'Submitting Ratings...'
                        : (pending.length > 1
                            ? 'Submit All Ratings (${pending.length})'
                            : 'Submit Rating'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(PendingReviewItem item, bool isDark) {
    final rating = _ratingFor(item);

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
                  color: isDark
                      ? AppColors.surfaceSoftDark
                      : const Color(0xFFF1F5F9),
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
                constraints:
                    const BoxConstraints.tightFor(width: 42, height: 42),
                icon: Icon(
                  star <= rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.warmAmber,
                  size: 34,
                ),
                onPressed: _isSubmittingAll
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
            enabled: !_isSubmittingAll,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product',
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
