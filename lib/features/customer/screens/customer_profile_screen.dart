import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/customer_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(customerProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(
            user?['name'] as String? ?? 'HomeBite customer',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(user?['email'] as String? ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Order history'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}
