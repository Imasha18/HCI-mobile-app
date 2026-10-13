import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../theme/rider_theme.dart';

class RiderNotificationsScreen extends ConsumerStatefulWidget {
  const RiderNotificationsScreen({super.key});

  @override
  ConsumerState<RiderNotificationsScreen> createState() =>
      _RiderNotificationsScreenState();
}

class _RiderNotificationsScreenState extends ConsumerState<RiderNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderNotificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(riderNotificationProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(riderNotificationProvider.notifier).markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: RiderTheme.primaryDark),
              ),
            ),
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') {
                  _confirmClearNotifications(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: Color(0xFFE53935),
                      ),
                      SizedBox(width: 10),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(riderNotificationProvider.notifier).fetchNotifications(),
          ),
        ],
      ),
      body: notifState.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: RiderTheme.primaryGreen))
          : RefreshIndicator(
              color: RiderTheme.primaryGreen,
              onRefresh: () =>
                  ref.read(riderNotificationProvider.notifier).fetchNotifications(),
              child: notifications.isEmpty
                  ? _buildFallbackList(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final id = (item['_id'] ?? item['id'] ?? '').toString();
                        return Dismissible(
                          key: ValueKey(id.isEmpty ? 'notification-$index' : id),
                          direction: id.isEmpty
                              ? DismissDirection.none
                              : DismissDirection.endToStart,
                          background: _buildDeleteBackground(),
                          confirmDismiss: (_) async {
                            await _confirmDeleteNotification(context, id);
                            return false;
                          },
                          child: _NotificationCard(
                            notification: item,
                            onTap: () {
                              if (id.isNotEmpty) {
                                ref
                                    .read(riderNotificationProvider.notifier)
                                    .markAsRead(id);
                              }
                            },
                            onDelete: id.isEmpty
                                ? null
                                : () => _confirmDeleteNotification(context, id),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }

  Future<bool> _confirmDeleteNotification(
    BuildContext context,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text('This notification will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    final deleted = await ref
        .read(riderNotificationProvider.notifier)
        .deleteNotification(id);
    if (!context.mounted) return deleted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Notification deleted' : 'Unable to delete notification',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return deleted;
  }

  Future<void> _confirmClearNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('All rider notifications in this list will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deletedCount = await ref
        .read(riderNotificationProvider.notifier)
        .deleteAllNotifications();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deletedCount > 0
              ? 'Notifications cleared'
              : 'No notifications were deleted',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFallbackList(BuildContext context) {
    final sampleNotifs = [
      {
        '_id': '1',
        'title': 'New delivery request',
        'body':
            "Delivery available from Amma's Spice Kitchen (3.8 km away). Tap to view.",
        'read': false,
        'createdAt':
            DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        '_id': '2',
        'title': 'Delivery accepted',
        'body':
            'You accepted delivery for Order #HB-9142. Please proceed to kitchen.',
        'read': false,
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
      },
      {
        '_id': '3',
        'title': 'Customer location updated',
        'body': 'Nimal Jayasuriya updated drop notes: "Leave at security guard desk".',
        'read': true,
        'createdAt':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        '_id': '4',
        'title': 'Delivery completed',
        'body':
            'Order #HB-8492 completed! Rs. 450.00 added to your daily earnings.',
        'read': true,
        'createdAt':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sampleNotifs.length,
      itemBuilder: (context, index) {
        return _NotificationCard(
          notification: sampleNotifs[index],
          onTap: () {},
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['read'] == true;
    final dateStr = notification['createdAt'] as String?;

    final iconData = _getNotificationIcon(title);
    final iconColor = _getNotificationColor(title);
    final iconBg = iconColor.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF1FBF4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: RiderTheme.softShadow,
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : RiderTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: RiderTheme.textDark,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: RiderTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete notification',
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: RiderTheme.textMuted,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRead ? RiderTheme.textMuted : RiderTheme.textDark,
                      height: 1.35,
                    ),
                  ),
                  if (dateStr != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(dateStr),
                      style: const TextStyle(fontSize: 11, color: RiderTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('new delivery')) {
      return Icons.delivery_dining_rounded;
    } else if (lower.contains('accepted')) {
      return Icons.assignment_turned_in_rounded;
    } else if (lower.contains('location') || lower.contains('customer')) {
      return Icons.edit_location_alt_rounded;
    } else if (lower.contains('completed')) {
      return Icons.task_alt_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('new delivery')) {
      return RiderTheme.primaryDark;
    } else if (lower.contains('accepted')) {
      return const Color(0xFFFF9800);
    } else if (lower.contains('location') || lower.contains('customer')) {
      return const Color(0xFF1565C0);
    } else if (lower.contains('completed')) {
      return RiderTheme.primaryGreen;
    }
    return RiderTheme.primaryGreen;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes.clamp(1, 59)}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (_) {
      return 'Recent';
    }
  }
}
