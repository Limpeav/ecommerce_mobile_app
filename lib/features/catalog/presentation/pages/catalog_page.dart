import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../../features/products/presentation/bloc/product_event.dart';
import '../../../../features/products/presentation/bloc/product_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/category_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../widgets/filter_modal.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatefulWidget {
  final bool focusSearchOnOpen;
  final VoidCallback? onSearchFocusHandled;

  const CatalogPage({
    super.key,
    this.focusSearchOnOpen = false,
    this.onSearchFocusHandled,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  bool _isSearchFocused = false;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _recentSearches = ServiceLocator.instance.searchHistoryService.getHistory();

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
      }
    });

    if (widget.focusSearchOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
        widget.onSearchFocusHandled?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSearchOnOpen && !oldWidget.focusSearchOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
        widget.onSearchFocusHandled?.call();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      context.read<ProductBloc>().add(const ProductLoadMoreRequested());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productState = context.read<ProductBloc>().state;
    if (_searchController.text != productState.searchQuery) {
      _searchController.text = productState.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'clothing':
      case 'fashion':
      case 'baby clothing':
      case 'rompers':
      case "men's clothing":
      case "women's clothing":
        return Icons.checkroom_rounded;
      case 'travel & gear':
      case 'strollers':
      case 'gear':
        return Icons.child_friendly_rounded;
      case 'furniture':
      case 'home & decor':
      case 'cribs':
      case 'nursery':
        return Icons.crib_rounded;
      case 'bath & skin':
      case 'bath':
      case 'skincare':
        return Icons.bathtub_rounded;
      case 'toy & play':
      case 'toys':
        return Icons.toys_rounded;
      case 'diapering & care':
      case 'diapering':
      case 'diapers':
        return Icons.baby_changing_station_rounded;
      case 'milk':
      case 'feeding & nursing':
      case 'feeding':
      case 'bottles':
        return Icons.local_drink_rounded;
      case 'shoes':
      case 'shoe':
      case 'footwear':
      case 'booties':
      case 'sneakers':
      case 'sandals':
        return Icons.roller_skating_rounded;
      case 'all':
        return Icons.child_care_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog & Explore'),
        actions: [
          // View mode toggle (Grid vs List)
          IconButton(
            icon: Icon(
              _isGridView
                  ? CupertinoIcons.list_bullet
                  : CupertinoIcons.square_grid_2x2,
              size: 22,
            ),
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),

          // Shopping Bag / Cart Action with live badge
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final count = cartState.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.bag, size: 22),
                    tooltip: 'Shopping Cart',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Filter & Sort Action with active filter counter badge
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              final filterCount = productState.activeFilterCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, size: 24),
                    tooltip: 'Filter & Sort',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const FilterModal(),
                      );
                    },
                  ),
                  if (filterCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.discountRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$filterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, productState) {
          final products = productState.filteredProducts;

          return Column(
            children: [
              // Search Input Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleSearchSubmit,
                  decoration: InputDecoration(
                    hintText: 'Search baby clothes, cribs, bottles...',
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductBloc>().add(
                                const ProductSearchChanged(''),
                              );
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    context.read<ProductBloc>().add(ProductSearchChanged(val));
                  },
                ),
              ),

              // Recent Searches & Trending Tags Panel (shown on focus or when empty)
              if (_isSearchFocused && _searchController.text.isEmpty)
                _buildSearchDiscoveryPanel(context, isDark),

              // Category Horizontal Chips
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: productState.categories.length,
                  itemBuilder: (context, index) {
                    final cat = productState.categories[index];
                    final isSelected = productState.selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: cat != 'All'
                            ? CategoryIconWidget(
                                category: cat,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                                customFallbackIcon: _getCategoryIcon(cat),
                              )
                            : null,
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<ProductBloc>().add(
                              ProductCategorySelected(cat),
                            );
                          }
                        },
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Active Filter Tags & Reset Action (if any custom filters are active)
              if (productState.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${productState.activeFilterCount} active',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<ProductBloc>().add(
                            const ProductFiltersReset(),
                          );
                          setState(() {});
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Active Filter Chips Strip (if any custom filters are active)
              if (productState.hasActiveFilters)
                Container(
                  height: 34,
                  margin: const EdgeInsets.only(top: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (productState.selectedCategory != 'All')
                        _buildFilterChip(
                          label: 'Category: ${productState.selectedCategory}',
                          onDeleted: () {
                            context.read<ProductBloc>().add(
                              const ProductCategorySelected('All'),
                            );
                          },
                          isDark: isDark,
                        ),
                      if (productState.searchQuery.isNotEmpty)
                        _buildFilterChip(
                          label: 'Search: "${productState.searchQuery}"',
                          onDeleted: () {
                            _searchController.clear();
                            context.read<ProductBloc>().add(
                              const ProductSearchChanged(''),
                            );
                            setState(() {});
                          },
                          isDark: isDark,
                        ),
                      if (productState.maxPriceFilter < 1000)
                        _buildFilterChip(
                          label:
                              'Under \$${productState.maxPriceFilter.toStringAsFixed(0)}',
                          onDeleted: () {
                            context.read<ProductBloc>().add(
                              const ProductPriceFilterChanged(1000.0),
                            );
                          },
                          isDark: isDark,
                        ),
                      if (productState.minRatingFilter > 0)
                        _buildFilterChip(
                          label: '★ ${productState.minRatingFilter}+',
                          onDeleted: () {
                            context.read<ProductBloc>().add(
                              const ProductRatingFilterChanged(0.0),
                            );
                          },
                          isDark: isDark,
                        ),
                      if (productState.sortOption != SortOption.featured)
                        _buildFilterChip(
                          label:
                              'Sort: ${_getSortLabel(productState.sortOption)}',
                          onDeleted: () {
                            context.read<ProductBloc>().add(
                              const ProductSortChanged(SortOption.featured),
                            );
                          },
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),

              const Divider(height: 16),

              // Products List / Grid with Infinite Scroll & Pull-to-Refresh
              Expanded(
                child: productState.isLoading && products.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    : products.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.search_circle_fill,
                                size: 72,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try adjusting your search query or reset your filters.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<ProductBloc>().add(
                                    const ProductFiltersReset(),
                                  );
                                  setState(() {});
                                },
                                icon: const Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: 16,
                                ),
                                label: const Text('Reset All Filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () async {
                          context.read<ProductBloc>().add(
                            const ProductRefreshRequested(),
                          );
                        },
                        child: _isGridView
                            ? GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 2
                                              : 4,
                                      childAspectRatio:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 0.62
                                              : 0.68,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount:
                                    products.length +
                                    (productState.isLoadingMore ? 2 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= products.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    );
                                  }
                                  return ProductCard(
                                    product: products[index],
                                    heroTagPrefix: 'catalog_grid',
                                  );
                                },
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount:
                                    products.length +
                                    (productState.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= products.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    );
                                  }
                                  final item = products[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      height: 150,
                                      child: ProductCard(
                                        product: item,
                                        compact: true,
                                        heroTagPrefix: 'catalog_list',
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: isDark
            ? const Color(0xFF26302A)
            : const Color(0xFFE8F2EC),
        side: BorderSide(
          color: isDark ? const Color(0xFF3B4A40) : const Color(0xFFB8D9C4),
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        deleteIcon: const Icon(
          Icons.close_rounded,
          size: 14,
          color: AppColors.accent,
        ),
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.priceLowToHigh:
        return 'Price: Low';
      case SortOption.priceHighToLow:
        return 'Price: High';
      case SortOption.ratingHighToLow:
        return 'Rating';
      case SortOption.featured:
        return 'Featured';
    }
  }

  void _handleSearchSubmit(String query) {
    final clean = query.trim();
    if (clean.isNotEmpty) {
      ServiceLocator.instance.searchHistoryService.addSearch(clean).then((updated) {
        if (mounted) setState(() => _recentSearches = updated);
      });
      context.read<ProductBloc>().add(ProductSearchChanged(clean));
    }
    _searchFocusNode.unfocus();
  }

  void _selectSearchTag(String tag) {
    _searchController.text = tag;
    _handleSearchSubmit(tag);
  }

  void _removeRecentSearch(String item) {
    ServiceLocator.instance.searchHistoryService.removeSearch(item).then((updated) {
      if (mounted) setState(() => _recentSearches = updated);
    });
  }

  void _clearRecentSearches() {
    ServiceLocator.instance.searchHistoryService.clearHistory().then((_) {
      if (mounted) setState(() => _recentSearches = []);
    });
  }

  Widget _buildSearchDiscoveryPanel(BuildContext context, bool isDark) {
    final trending = SearchHistoryService.trendingSearches;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recent Searches Section
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.clock, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _clearRecentSearches,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.discountRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _recentSearches.map((term) {
                return InkWell(
                  onTap: () => _selectSearchTag(term),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          term,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeRecentSearch(term),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
          ],

          // Trending Searches Section
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Trending Searches',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: trending.map((tag) {
              return ActionChip(
                label: Text(tag),
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
                backgroundColor: isDark
                    ? AppColors.accent.withAlpha(25)
                    : const Color(0xFFEBF5F0),
                side: BorderSide(
                  color: AppColors.accent.withAlpha(isDark ? 60 : 80),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () => _selectSearchTag(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
