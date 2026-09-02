import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../../../features/notifications/presentation/bloc/notification_state.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/notification_item.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, notifState) {
        final notifications = notifState.filteredNotifications;
        final unreadTotal = notifState.unreadCount;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                ),
                if (unreadTotal > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.discountRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadTotal new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (unreadTotal > 0)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, size: 22),
                  tooltip: 'Mark All as Read',
                  onPressed: () {
                    context.read<NotificationCubit>().markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'clear_all') {
                    _showClearAllDialog(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.trash, color: AppColors.discountRed, size: 18),
                        SizedBox(width: 8),
                        Text('Clear all notifications', style: TextStyle(color: AppColors.discountRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Category Pills
              _buildCategoryFilters(context, notifState, isDark, borderColor),

              // Notification List or Empty State
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState(context, isDark, subtextColor)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _buildNotificationCard(
                            context,
                            item,
                            isDark,
                            cardColor,
                            textColor,
                            subtextColor,
                            borderColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    NotificationState state,
    bool isDark,
    Color borderColor,
  ) {
    final filters = [
      null, // All
      NotificationType.order,
      NotificationType.promo,
      NotificationType.flashSale,
      NotificationType.system,
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, idx) {
          final filter = filters[idx];
          final isSelected = state.selectedFilter == filter;
          final String title = filter == null ? 'All' : filter.displayName;

          int count = 0;
          if (filter == null) {
            count = state.notifications.length;
          } else {
            count = state.notifications.where((n) => n.type == filter).length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('$title ($count)'),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              selectedColor: AppColors.primary,
              backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : borderColor,
                  width: 1,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) {
                context.read<NotificationCubit>().setFilter(filter);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem item,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final iconData = _getIconForType(item.type);
    final iconColor = _getColorForType(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.discountRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        context.read<NotificationCubit>().deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification dismissed'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.warmAmber,
              onPressed: () {
                context.read<NotificationCubit>().addNotification(
                      title: item.title,
                      message: item.message,
                      type: item.type,
                      orderId: item.orderId,
                      orderNumber: item.orderNumber,
                      productId: item.productId,
                    );
              },
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<NotificationCubit>().markAsRead(item.id);
            _handleNotificationAction(context, item);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead
                    ? borderColor
                    : AppColors.accent.withAlpha(isDark ? 90 : 130),
                width: item.isRead ? 1 : 1.5,
              ),
              boxShadow: item.isRead
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(isDark ? 20 : 15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6, top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: subtextColor,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time + Action Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimeElapsed(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          if (item.orderId != null || item.orderNumber != null)
                            Row(
                              children: [
                                Text(
                                  'Track Order',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.accent),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.bell_slash,
                size: 38,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'You are completely caught up! Updates regarding orders, flash discounts, and delivery tracking will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subtextColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationAction(BuildContext context, NotificationItem item) {
    if (item.orderId != null || item.orderNumber != null) {
      final orders = context.read<OrderBloc>().state.orders;
      final matched = orders.where((o) =>
          o.id == item.orderId ||
          o.trackingNumber == item.orderNumber ||
          o.displayOrderCode == item.orderNumber).toList();

      if (matched.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderTrackingPage(order: matched.first),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OrdersPage(),
          ),
        );
      }
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear all notifications?'),
        content: const Text('This will delete all past notifications from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.discountRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<NotificationCubit>().clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_rounded;
      case NotificationType.promo:
        return Icons.local_offer_rounded;
      case NotificationType.flashSale:
        return Icons.bolt_rounded;
      case NotificationType.system:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.accent;
      case NotificationType.promo:
        return AppColors.warmAmber;
      case NotificationType.flashSale:
        return AppColors.discountRed;
      case NotificationType.system:
        return AppColors.primary;
    }
  }

  String _formatTimeElapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
