import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: const Color(0xFFFF9800),
        onRefresh: () async {
          ref.invalidate(notificationProvider);
        },
        child: notifications.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  key: const PageStorageKey<String>('notifications_scroll'),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(
                        item.read
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: const Color(0xFFFF7A00),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.body),
                    );
                  },
                ),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const NotificationSkeleton(),
          ),
        ),
      ),
    );
  }
}
