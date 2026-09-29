import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No notifications yet'))
            : ListView(
                children: items
                    .map(
                      (item) => ListTile(
                        leading: Icon(
                          item.read
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: const Color(0xFFFF7A00),
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.body),
                      ),
                    )
                    .toList(),
              ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
