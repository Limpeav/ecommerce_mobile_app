import 'package:equatable/equatable.dart';
import '../../../../core/models/notification_item.dart';

class NotificationState extends Equatable {
  final List<NotificationItem> notifications;
  final NotificationType? selectedFilter;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.selectedFilter,
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get filteredNotifications {
    if (selectedFilter == null) {
      return notifications;
    }
    return notifications.where((n) => n.type == selectedFilter).toList();
  }

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    NotificationType? selectedFilter,
    bool clearFilter = false,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      selectedFilter: clearFilter ? null : (selectedFilter ?? this.selectedFilter),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [notifications, selectedFilter, isLoading];
}
