import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';

class ProductReviewsPage extends StatefulWidget {
  final Product product;

  const ProductReviewsPage({super.key, required this.product});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  late Product _product;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchLiveReviews();
  }

  Future<void> _fetchLiveReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final liveProduct = await ServiceLocator.instance.productRepository
          .getProductById(widget.product.id);
      if (liveProduct != null && mounted) {
        setState(() {
          _product = liveProduct;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load the latest reviews from server.';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate rating percentage distribution from backend review data
  Map<int, double> _calculateDistribution() {
    if (_product.reviews.isNotEmpty) {
      final total = _product.reviews.length;
      final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final r in _product.reviews) {
        final star = r.rating.clamp(1.0, 5.0).round();
        counts[star] = (counts[star] ?? 0) + 1;
      }
      return {
        5: (counts[5] ?? 0) / total,
        4: (counts[4] ?? 0) / total,
        3: (counts[3] ?? 0) / total,
        2: (counts[2] ?? 0) / total,
        1: (counts[1] ?? 0) / total,
      };
    }

    // Default distribution based on product rating
    final rating = _product.rating;
    if (rating >= 4.7) {
      return {5: 0.67, 4: 0.20, 3: 0.08, 2: 0.03, 1: 0.02};
    } else if (rating >= 4.0) {
      return {5: 0.52, 4: 0.28, 3: 0.12, 2: 0.05, 1: 0.03};
    } else if (rating >= 3.0) {
      return {5: 0.30, 4: 0.35, 3: 0.20, 2: 0.10, 1: 0.05};
    } else {
      return {5: 0.15, 4: 0.20, 3: 0.25, 2: 0.25, 1: 0.15};
    }
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Color _getAvatarBgColor(String name, bool isDark) {
    final colorsLight = [
      const Color(0xFFE0E7FF), // Indigo soft
      const Color(0xFFFEF3C7), // Amber soft
      const Color(0xFFFCE7F3), // Pink soft
      const Color(0xFFD1FAE5), // Emerald soft
      const Color(0xFFE2E8F0), // Slate soft
      const Color(0xFFEDE9FE), // Purple soft
      const Color(0xFFFFEDD5), // Orange soft
    ];
    final colorsDark = [
      const Color(0xFF312E81),
      const Color(0xFF78350F),
      const Color(0xFF831843),
      const Color(0xFF064E3B),
      const Color(0xFF334155),
      const Color(0xFF4C1D95),
      const Color(0xFF7C2D12),
    ];
    final index = name.hashCode.abs() % colorsLight.length;
    return isDark ? colorsDark[index] : colorsLight[index];
  }

  Color _getAvatarTextColor(String name, bool isDark) {
    final textColorsLight = [
      const Color(0xFF4338CA),
      const Color(0xFFB45309),
      const Color(0xFFBE185D),
      const Color(0xFF047857),
      const Color(0xFF334155),
      const Color(0xFF6D28D9),
      const Color(0xFFC2410C),
    ];
    final textColorsDark = [
      const Color(0xFFC7D2FE),
      const Color(0xFFFDE68A),
      const Color(0xFFFBCFE8),
      const Color(0xFFA7F3D0),
      const Color(0xFFE2E8F0),
      const Color(0xFFDDD6FE),
      const Color(0xFFFED7AA),
    ];
    final index = name.hashCode.abs() % textColorsLight.length;
    return isDark ? textColorsDark[index] : textColorsLight[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distribution = _calculateDistribution();
    final primaryImg = _product.images.isNotEmpty
        ? _product.images.first
        : _product.image;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh Reviews from API',
              onPressed: _fetchLiveReviews,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveReviews,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              if (_isLoading && _product.reviews.isEmpty)
                const LinearProgressIndicator(minHeight: 2),

              // 1. Product Summary Card Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        child: Image.network(
                          primaryImg,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.shopping_bag_outlined, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${_product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Error notification if failed to refresh
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  color: AppColors.discountRedLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.discountRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.discountRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchLiveReviews,
                        child: const Text('RETRY',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // 2. Rating Breakdown Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top score row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Big Score & OUT OF 5
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'OUT OF 5',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Stars & Total Ratings count
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final starRating = _product.rating;
                                return Icon(
                                  index < starRating.floor()
                                      ? Icons.star_rounded
                                      : (index < starRating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded),
                                  color: index < starRating
                                      ? AppColors.warmAmber
                                      : Colors.grey.withAlpha(80),
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_product.ratingCount} ratings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rating Bars (5 to 1)
                    ...[5, 4, 3, 2, 1].map((star) {
                      final percent = distribution[star] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                '$star',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.warmAmber,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? Colors.grey.withAlpha(50)
                                      : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark
                                        ? Colors.white70
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(percent * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 32, indent: 20, endIndent: 20),

              // 3. Reviews Header (Read-Only - No write review action)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_product.reviews.length} Reviews',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Reviews List
              if (_product.reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No customer reviews yet for this product.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _product.reviews.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 28, thickness: 0.8),
                  itemBuilder: (context, index) {
                    final review = _product.reviews[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Avatar with First Letter of Name
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              _getAvatarBgColor(review.userName, isDark),
                          child: Text(
                            _getInitial(review.userName),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  _getAvatarTextColor(review.userName, isDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // User Details & Comment
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Name
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Stars + Rating & Date Text
                              Row(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (idx) {
                                      final isFilled =
                                          idx < review.rating.round();
                                      return Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 15,
                                        color: isFilled
                                            ? AppColors.warmAmber
                                            : Colors.grey.withAlpha(90),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${review.rating.toInt()} OUT OF 5, ${review.date}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Review Comment
                              Text(
                                review.comment,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
