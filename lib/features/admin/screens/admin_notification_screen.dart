import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../theme/admin_theme.dart';

class AdminNotificationScreen extends ConsumerStatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  ConsumerState<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends ConsumerState<AdminNotificationScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Verifications', 'Complaints', 'Orders'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final all = state.notifications;

    final filtered = all.where((n) {
      if (_selectedFilter == 'All') return true;
      final type = (n['type'] as String? ?? '').toLowerCase();
      if (_selectedFilter == 'Verifications') return type.contains('verification');
      if (_selectedFilter == 'Complaints') return type.contains('complaint');
      if (_selectedFilter == 'Orders') return type.contains('order');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'System Notifications',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(notificationProvider.notifier).fetchNotifications(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(f),
                    selectedColor: AdminTheme.primaryLight,
                    checkmarkColor: AdminTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AdminTheme.primaryDark : AdminTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: AdminTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AdminTheme.primary : AdminTheme.border),
                    ),
                    onSelected: (val) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: state.isLoading && all.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
                : filtered.isEmpty
                    ? const Center(
                        child: Text('No notifications found', style: TextStyle(color: AdminTheme.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = filtered[index];
                          final type = notif['type'] as String? ?? 'alert';
                          final title = notif['title'] as String? ?? 'Notification';
                          final body = notif['body'] as String? ?? '';
                          final isRead = notif['read'] as bool? ?? false;

                          IconData icon;
                          Color iconColor;
                          Color iconBg;

                          if (type.contains('verification')) {
                            icon = Icons.verified_user_rounded;
                            iconColor = AdminTheme.primary;
                            iconBg = AdminTheme.primaryLight;
                          } else if (type.contains('complaint')) {
                            icon = Icons.warning_amber_rounded;
                            iconColor = AdminTheme.statusRejected;
                            iconBg = AdminTheme.statusRejectedBg;
                          } else if (type.contains('order')) {
                            icon = Icons.receipt_long_rounded;
                            iconColor = const Color(0xFF1976D2);
                            iconBg = const Color(0xFFE3F2FD);
                          } else {
                            icon = Icons.info_outline_rounded;
                            iconColor = const Color(0xFF00897B);
                            iconBg = const Color(0xFFE0F2F1);
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AdminTheme.cardDecoration(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 14,
                                                color: AdminTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AdminTheme.primary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
