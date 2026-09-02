import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_event.dart';
import '../../../../features/orders/presentation/bloc/order_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/order.dart';
import '../../../../core/services/review_requirement_service.dart';
import 'order_tracking_page.dart';
import 'pending_reviews_page.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback? onBrowseMore;

  const OrdersPage({super.key, this.onBrowseMore});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    final userToken = context.read<AuthBloc>().state.currentUser?.token;
    context.read<OrderBloc>().add(OrderFetchRequested(authToken: userToken));
  }

  List<OrderModel> _filterOrders(List<OrderModel> allOrders, int tabIndex) {
    var list = allOrders;

    // Filter by Tab
    switch (tabIndex) {
      case 1: // Active / In-transit
        list = list.where((o) =>
            o.status == OrderStatus.placed ||
            o.status == OrderStatus.processing ||
            o.status == OrderStatus.shipped ||
            o.status == OrderStatus.outForDelivery).toList();
        break;
      case 2: // Delivered
        list = list.where((o) => o.status == OrderStatus.delivered).toList();
        break;
      case 3: // Cancelled
        list = list.where((o) => o.status == OrderStatus.cancelled).toList();
        break;
      case 0:
      default:
        break;
    }

    // Filter by Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) {
        final matchesId = o.id.toLowerCase().contains(q) ||
            o.trackingNumber.toLowerCase().contains(q) ||
            o.displayOrderCode.toLowerCase().contains(q);
        final matchesName = o.recipientName?.toLowerCase().contains(q) == true;
        final matchesItem = o.items.any((i) => i.product.title.toLowerCase().contains(q));
        return matchesId || matchesName || matchesItem;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Orders',
            onPressed: () async {
              await _refreshOrders();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orders synced with backend'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, tracking or item...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.accent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                  ),
                ),
              ),
              // Filter Tabs
              BlocBuilder<OrderBloc, OrderState>(
                builder: (context, orderState) {
                  final all = orderState.orders;
                  final active = all.where((o) =>
                      o.status == OrderStatus.placed ||
                      o.status == OrderStatus.processing ||
                      o.status == OrderStatus.shipped ||
                      o.status == OrderStatus.outForDelivery).length;
                  final delivered = all.where((o) => o.status == OrderStatus.delivered).length;
                  final cancelled = all.where((o) => o.status == OrderStatus.cancelled).length;

                  return TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.accent,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    onTap: (_) => setState(() {}),
                    tabs: [
                      Tab(text: 'All (${all.length})'),
                      Tab(text: 'Active ($active)'),
                      Tab(text: 'Delivered ($delivered)'),
                      Tab(text: 'Cancelled ($cancelled)'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, orderState) {
          final prompt = orderState.deliveryReviewPrompt;
          if (prompt == null) return;

          context.read<OrderBloc>().add(const OrderDeliveryReviewPromptCleared());
          _showDeliveredReviewPrompt(prompt);
        },
        builder: (context, orderState) {
          final allOrders = orderState.orders;

          if (orderState.isLoading && allOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final orders = _filterOrders(allOrders, _tabController.index);

          if (orders.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _refreshOrders,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching orders found'
                              : 'No Orders In This Category',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching with another keyword or clear search.'
                              : 'Orders placed on the website or mobile app will appear here with live tracking status.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: widget.onBrowseMore ?? () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Browse Products'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _refreshOrders,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final pendingReviewCount = orderState.pendingReviewItems
                    .where((item) => item.orderId == order.id)
                    .length;
                return _buildOrderCard(order, isDark, pendingReviewCount);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    OrderModel order,
    bool isDark,
    int pendingReviewCount,
  ) {
    final canCancel = order.status == OrderStatus.placed || order.status == OrderStatus.processing;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order Code & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    order.displayOrderCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 6),

          // Date & Payment Method
          Row(
            children: [
              Text(
                _formatDate(order.date),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                order.paymentMethod,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (order.isPaid) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 10, color: Colors.green),
                      SizedBox(width: 3),
                      Text('Paid', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Items Thumbnails Row
          if (order.items.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.length,
                itemBuilder: (context, idx) {
                  final item = order.items[idx];
                  return Container(
                    width: 52,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.product.image.isNotEmpty
                          ? Image.network(
                              item.product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, size: 20),
                            )
                          : const Icon(Icons.shopping_bag_outlined, size: 20),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),

          // Address preview
          if (order.deliveryAddress.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (pendingReviewCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warmAmber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warmAmber.withAlpha(90)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    color: AppColors.warmAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rate ${pendingReviewCount == 1 ? 'this product' : '$pendingReviewCount products'} to continue shopping.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF7C2D12),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openPendingReviews,
                    child: const Text('Rate Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Total & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${order.items.length} ${order.items.length == 1 ? 'item' : 'items'})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (canCancel)
                    TextButton(
                      onPressed: () => _confirmCancelOrder(order),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.discountRed,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (pendingReviewCount > 0) {
                        _openPendingReviews();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingPage(order: order),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    icon: Icon(
                      pendingReviewCount > 0
                          ? Icons.rate_review_outlined
                          : Icons.location_searching_rounded,
                      size: 15,
                    ),
                    label: Text(
                      pendingReviewCount > 0 ? 'Rate Products' : 'Track Order',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeliveredReviewPrompt(PendingReviewItem item) {
    if (!mounted) return;
    _openPendingReviews();
  }

  void _openPendingReviews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PendingReviewsPage(),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.placed:
        bg = Colors.amber.withAlpha(35);
        fg = const Color(0xFFD97706);
        break;
      case OrderStatus.processing:
        bg = Colors.blue.withAlpha(35);
        fg = const Color(0xFF2563EB);
        break;
      case OrderStatus.shipped:
        bg = Colors.purple.withAlpha(35);
        fg = const Color(0xFF7C3AED);
        break;
      case OrderStatus.outForDelivery:
        bg = Colors.orange.withAlpha(35);
        fg = const Color(0xFFEA580C);
        break;
      case OrderStatus.delivered:
        bg = Colors.green.withAlpha(35);
        fg = const Color(0xFF16A34A);
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.withAlpha(35);
        fg = AppColors.discountRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _confirmCancelOrder(OrderModel order) {
    final userToken = context.read<AuthBloc>().state.currentUser?.token;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${order.displayOrderCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.discountRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<OrderBloc>().add(OrderCancelled(
                orderId: order.id,
                authToken: userToken,
              ));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
