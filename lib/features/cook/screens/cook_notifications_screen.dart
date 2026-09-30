import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cook_notification_provider.dart';
import '../theme/cook_theme.dart';

class CookNotificationsScreen extends ConsumerStatefulWidget {
  const CookNotificationsScreen({super.key});

  @override
  ConsumerState<CookNotificationsScreen> createState() => _CookNotificationsScreenState();
}

class _CookNotificationsScreenState extends ConsumerState<CookNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cookNotificationProvider.notifier).fetchNotifications();
    });
  }

  IconData _getNotificationIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('new order')) return Icons.receipt_long_rounded;
    if (lower.contains('accepted')) return Icons.check_circle_rounded;
    if (lower.contains('cancelled') || lower.contains('rejected')) return Icons.cancel_rounded;
    if (lower.contains('payment') || lower.contains('payout')) return Icons.payments_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('new order')) return CookTheme.primaryOrange;
    if (lower.contains('accepted')) return CookTheme.statusGreen;
    if (lower.contains('cancelled') || lower.contains('rejected')) return CookTheme.statusRed;
    if (lower.contains('payment') || lower.contains('payout')) return const Color(0xFF1976D2);
    return CookTheme.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookNotificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cookNotificationProvider.notifier).markAllAsRead();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: CookTheme.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: CookTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(cookNotificationProvider.notifier).fetchNotifications();
        },
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: CookTheme.primaryOrange))
            : state.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No alerts right now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You are all caught up on your kitchen orders!',
                          style: TextStyle(color: CookTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final n = state.notifications[index] as Map<String, dynamic>;
                      final id = n['_id'] as String? ?? '';
                      final title = n['title'] as String? ?? 'Kitchen Alert';
                      final body = n['body'] as String? ?? '';
                      final isRead = n['read'] as bool? ?? false;
                      final icon = _getNotificationIcon(title);
                      final color = _getNotificationColor(title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFFFFBF5),
                          borderRadius: BorderRadius.circular(18),
                          border: isRead
                              ? null
                              : Border.all(color: CookTheme.primaryOrange.withValues(alpha: 0.2)),
                          boxShadow: CookTheme.softShadow,
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead && id.isNotEmpty) {
                              ref.read(cookNotificationProvider.notifier).markAsRead(id);
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 15,
                                    color: CookTheme.textDark,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: CookTheme.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              body,
                              style: const TextStyle(fontSize: 13, color: CookTheme.textMuted, height: 1.3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
