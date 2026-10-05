import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../providers/customer_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(customerProvider);
      if (state.user == null && !state.isLoading) {
        ref.read(customerProvider.notifier).loadProfile();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
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

  Future<void> _refreshProfile() async {
    final success = await ref
        .read(customerProvider.notifier)
        .loadProfile(forceRefresh: true);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to refresh profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(customerProvider);
    final user = state.user;

    if (user == null && state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null && !state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 16),
                Text(
                  state.error ?? 'Unable to load your profile.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(customerProvider.notifier).loadProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = (user?['name'] as String?) ?? 'HomeBite customer';
    final email = (user?['email'] as String?) ?? '';
    final phone = (user?['phone'] as String?) ?? '';
    final address = (user?['address'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF9800),
        onRefresh: _refreshProfile,
        child: ListView(
          key: const PageStorageKey<String>('customer_profile_scroll'),
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          children: [
            Center(
              child: AppCachedImage(
                imageUrl: (user?['profileImage'] as String?)?.isNotEmpty == true
                    ? user!['profileImage'] as String
                    : null,
                width: 96,
                height: 96,
                borderRadius: 48,
                fallbackIcon: Icons.person,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                key: ValueKey(name),
                name,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                key: ValueKey(email),
                email,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),

            // Delivery & Contact Card
            Card(
              elevation: 0,
              color: const Color(0xFFFAF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEFEAE3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery & Contact Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _editProfileDialog(
                            context,
                            phone,
                            address,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFFF7A00)),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFFFF7A00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _profileInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: phone.isNotEmpty ? phone : 'No phone number provided',
                      isMissing: phone.isEmpty,
                    ),
                    const Divider(height: 20),
                    _profileInfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Delivery Address',
                      value: address.isNotEmpty ? address : 'No delivery address provided',
                      isMissing: address.isEmpty,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: const Color(0xFFFAF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEFEAE3)),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFFFF7A00),
                  ),
                ),
                title: const Text(
                  'Food Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                subtitle: const Text(
                  'Diet, favourite cuisines, spice & budget',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.foodPreferences),
              ),
            ),

            const SizedBox(height: 16),
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
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isMissing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF7A00)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isMissing ? FontWeight.normal : FontWeight.w600,
                  color: isMissing ? Colors.red.shade400 : const Color(0xFF252525),
                  fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editProfileDialog(BuildContext context, String currentPhone, String currentAddress) {
    final phoneCtrl = TextEditingController(text: currentPhone);
    final addressCtrl = TextEditingController(text: currentAddress);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Delivery & Contact'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '077 123 4567 or +94 77 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    final cleaned = val.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
                    final regex = RegExp(r'^(?:(?:\+94|0094|94|0)?[1-9]\d{8})$');
                    if (!regex.hasMatch(cleaned)) {
                      return 'Enter a valid Sri Lankan phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: addressCtrl,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'No. 25, Main Street, Nugegoda',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (val) => val == null || val.trim().length < 5
                      ? 'Please enter a complete delivery address'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await ref.read(customerProvider.notifier).updateProfile({
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
