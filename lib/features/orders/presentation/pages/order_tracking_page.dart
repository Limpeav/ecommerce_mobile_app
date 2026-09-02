import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_event.dart';
import '../../../../features/orders/presentation/bloc/order_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/notification_item.dart';
import '../../../../core/models/order.dart';
import '../../../../core/services/review_requirement_service.dart';
import '../widgets/live_tracking_map.dart';
import 'pending_reviews_page.dart';

class OrderTrackingPage extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  Timer? _pollingTimer;
  DateTime _lastSynced = DateTime.now();
  late OrderStatus _previousStatus;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _previousStatus = widget.order.status;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLiveTracking();
      _startLivePolling();
    });
  }

  void _startLivePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final currentOrder = context.read<OrderBloc>().state.orders.firstWhere(
            (o) => o.id == widget.order.id || o.trackingNumber == widget.order.trackingNumber,
            orElse: () => widget.order,
          );
      if (currentOrder.status != OrderStatus.delivered &&
          currentOrder.status != OrderStatus.cancelled) {
        _refreshLiveTracking(silent: true);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshLiveTracking({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final userToken = context.read<AuthBloc>().state.currentUser?.token;
    context.read<OrderBloc>().add(OrderTrackRequested(
      orderIdOrNumber: widget.order.id,
      authToken: userToken,
      onResult: (updatedOrder) {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _lastSynced = DateTime.now();
          });
        }
      },
    ));
  }

  void _onOrderStatusAdvanced(OrderModel currentOrder) {
    final title = '📦 Order Update: ${currentOrder.status.displayName}';
    final message = 'Your order ${currentOrder.displayOrderCode} is now marked as ${currentOrder.status.displayName.toLowerCase()}.';

    try {
      context.read<NotificationCubit>().addNotification(
            title: title,
            message: message,
            type: NotificationType.order,
            orderId: currentOrder.id,
            orderNumber: currentOrder.displayOrderCode,
          );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order status updated: ${currentOrder.status.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, orderState) {
        final currentOrder = orderState.orders.firstWhere(
          (o) => o.id == widget.order.id || o.trackingNumber == widget.order.trackingNumber,
          orElse: () => widget.order,
        );

        if (currentOrder.status != _previousStatus) {
          _onOrderStatusAdvanced(currentOrder);
          _previousStatus = currentOrder.status;
        }

        final prompt = orderState.deliveryReviewPrompt;
        if (prompt == null) return;

        context.read<OrderBloc>().add(const OrderDeliveryReviewPromptCleared());
        _showDeliveredReviewPrompt(prompt);
      },
      builder: (context, orderState) {
        // Retrieve latest updated instance of this order from bloc state
        final currentOrder = orderState.orders.firstWhere(
          (o) => o.id == widget.order.id || o.trackingNumber == widget.order.trackingNumber,
          orElse: () => widget.order,
        );

        final isCancelled = currentOrder.status == OrderStatus.cancelled;
        final isDelivered = currentOrder.status == OrderStatus.delivered;
        final canCancel = currentOrder.status == OrderStatus.placed || currentOrder.status == OrderStatus.processing;
        final pendingReviewCount = orderState.pendingReviewItems
            .where((item) => item.orderId == currentOrder.id)
            .length;

        final steps = [
          {
            'title': 'Order Placed',
            'desc': 'Received and verified on backend database',
            'icon': Icons.assignment_turned_in_outlined,
          },
          {
            'title': 'Processing',
            'desc': 'Items packaged and prepared at fulfillment hub',
            'icon': Icons.inventory_2_outlined,
          },
          {
            'title': 'Shipped & In Transit',
            'desc': 'Package dispatched via Express courier',
            'icon': Icons.local_shipping_outlined,
          },
          {
            'title': 'Out for Delivery',
            'desc': 'Courier driver is en route to your address',
            'icon': Icons.delivery_dining_outlined,
          },
          {
            'title': 'Delivered',
            'desc': 'Package delivered to recipient successfully',
            'icon': Icons.home_outlined,
          },
        ];

        final currentStep = currentOrder.status.stepIndex;

        return Scaffold(
          appBar: AppBar(
            title: Text('Track ${currentOrder.displayOrderCode}'),
            actions: [
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Status from Backend',
                onPressed: _refreshLiveTracking,
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _refreshLiveTracking,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Sync Status Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.green.withAlpha(80)
                            : const Color(0xFF86EFAC),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentOrder.status == OrderStatus.delivered
                                ? 'Delivered • Finalized'
                                : currentOrder.status == OrderStatus.cancelled
                                    ? 'Cancelled'
                                    : 'Live Real-Time Polling Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        Text(
                          'Synced ${_formatLastSynced(_lastSynced)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero Status Card
                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.discountRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.discountRed.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.discountRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order Cancelled',
                                  style: TextStyle(
                                    color: AppColors.discountRed,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'This order was cancelled. If you already made an online payment, a refund will be processed within 1-3 business days.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isDelivered)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withAlpha(70)),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check_circle_outline, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Delivered 🎉',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your package has been successfully delivered. Thank you for shopping with us!',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E6144), Color(0xFF4A7C59)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E6144).withAlpha(50),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Estimated Delivery',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(45),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        currentOrder.status.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentOrder.estimatedDelivery,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tracking: ${currentOrder.trackingNumber}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  if (pendingReviewCount > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warmAmber.withAlpha(28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warmAmber.withAlpha(90)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.rate_review_outlined,
                                color: AppColors.warmAmber,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Rating Required',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF7C2D12),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please rate ${pendingReviewCount == 1 ? 'this delivered product' : 'these $pendingReviewCount delivered products'} before placing another order.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openPendingReviews,
                              icon: const Icon(Icons.star_rate_rounded, size: 18),
                              label: const Text('Rate Products Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Live Courier Map (For active delivery)
                  if (!isCancelled) ...[
                    LiveTrackingMap(
                      orderId: currentOrder.id,
                      destinationAddress: currentOrder.deliveryAddress,
                    ),
                    const SizedBox(height: 20),

                    // Delivery Timeline Section
                    const Text(
                      'Shipment Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline Steps
                    ...List.generate(steps.length, (index) {
                      final step = steps[index];
                      final isCompleted = index <= currentStep;
                      final isCurrent = index == currentStep;
                      final isLast = index == steps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Step Indicator
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppColors.accent
                                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                                  border: isCurrent
                                      ? Border.all(color: AppColors.accentLight, width: 3)
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    isCompleted ? Icons.check : (step['icon'] as IconData),
                                    size: 15,
                                    color: isCompleted ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2.5,
                                  height: 48,
                                  color: isCompleted && index < currentStep
                                      ? AppColors.accent
                                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Step Description
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                                      color: isCompleted
                                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const Divider(height: 24),
                  ],

                  // Recipient & Shipping Information Card
                  Container(
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
                        const Row(
                          children: [
                            Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text(
                              'Recipient & Delivery Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (currentOrder.recipientName?.isNotEmpty == true) ...[
                          _buildDetailRow('Recipient Name', currentOrder.recipientName!, isDark),
                          const SizedBox(height: 6),
                        ],
                        if (currentOrder.recipientPhone?.isNotEmpty == true) ...[
                          _buildDetailRow('Phone Number', currentOrder.recipientPhone!, isDark),
                          const SizedBox(height: 6),
                        ],
                        _buildDetailRow('Delivery Address', currentOrder.deliveryAddress, isDark),
                        const SizedBox(height: 6),
                        _buildDetailRow('Payment Method', currentOrder.paymentMethod, isDark),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                          'Payment Status',
                          currentOrder.isPaid ? 'Paid' : 'Cash on Delivery (Pending Delivery)',
                          isDark,
                          valueColor: currentOrder.isPaid ? Colors.green : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Items Summary Card
                  Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Items (${currentOrder.items.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '\$${currentOrder.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...currentOrder.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.product.image,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Qty: ${item.quantity}${item.selectedColor.isNotEmpty ? ' • ${item.selectedColor}' : ''}${item.selectedSize.isNotEmpty ? ' • ${item.selectedSize}' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cancel Order Action for Customer (if order is in early processing stage)
                  if (canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.discountRed,
                          side: const BorderSide(color: AppColors.discountRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Order'),
                              content: Text('Are you sure you want to cancel order ${currentOrder.displayOrderCode}?'),
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
                                    final userToken = context.read<AuthBloc>().state.currentUser?.token;
                                    context.read<OrderBloc>().add(OrderCancelled(
                                      orderId: currentOrder.id,
                                      authToken: userToken,
                                    ));
                                    if (context.mounted) {
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
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel This Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildDetailRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  String _formatLastSynced(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
