import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_event.dart';
import '../../../../core/constants/app_colors.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late SortOption _selectedSort;
  late double _maxPrice;
  late double _minRating;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final productState = context.read<ProductBloc>().state;
      _selectedSort = productState.sortOption;
      _maxPrice = productState.maxPriceFilter;
      _minRating = productState.minRatingFilter;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E2320) : AppColors.surfaceLight;
    final unselectedChipColor = isDark ? const Color(0xFF2B312E) : const Color(0xFFEFEBE6);
    final selectedChipColor = isDark ? const Color(0xFF4A6B56) : AppColors.accent;

    return Container(
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Reset Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSort = SortOption.featured;
                      _maxPrice = 1000.0;
                      _minRating = 0.0;
                    });
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9EABA2) : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Sort By Section
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChoice(SortOption.featured, 'Featured', selectedChipColor, unselectedChipColor, isDark),
                _buildSortChoice(SortOption.priceLowToHigh, 'Price: Low to High', selectedChipColor, unselectedChipColor, isDark),
                _buildSortChoice(SortOption.priceHighToLow, 'Price: High to Low', selectedChipColor, unselectedChipColor, isDark),
                _buildSortChoice(SortOption.ratingHighToLow, 'Highest Rated', selectedChipColor, unselectedChipColor, isDark),
              ],
            ),
            const SizedBox(height: 22),

            // 2. Max Price Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Max Price',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _maxPrice >= 1000 ? '\$1000' : '\$${_maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF8BB599) : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isDark ? const Color(0xFF6B997B) : AppColors.accent,
                inactiveTrackColor: isDark ? const Color(0xFF333A36) : const Color(0xFFE2DDD8),
                thumbColor: isDark ? const Color(0xFF8BB599) : AppColors.accent,
                overlayColor: AppColors.accent.withAlpha(30),
                trackHeight: 4.5,
              ),
              child: Slider(
                value: _maxPrice,
                min: 0,
                max: 1000,
                divisions: 100,
                onChanged: (val) {
                  setState(() {
                    _maxPrice = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // 3. Minimum Rating Section
            const Text(
              'Minimum Rating',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                final isSelected = _minRating == rating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _minRating = rating;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedChipColor : unselectedChipColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? selectedChipColor : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && rating == 0) ...[
                          const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        if (rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE5A93C)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          rating == 0 ? 'All' : '$rating+',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white.withAlpha(200) : const Color(0xFF4A4E4B)),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // 4. Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final bloc = context.read<ProductBloc>();
                  bloc.add(ProductSortChanged(_selectedSort));
                  bloc.add(ProductPriceFilterChanged(_maxPrice));
                  bloc.add(ProductRatingFilterChanged(_minRating));
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF6B997B) : AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChoice(
    SortOption option,
    String label,
    Color selectedColor,
    Color unselectedColor,
    bool isDark,
  ) {
    final isSelected = _selectedSort == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = option;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white.withAlpha(200) : const Color(0xFF4A4E4B)),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
