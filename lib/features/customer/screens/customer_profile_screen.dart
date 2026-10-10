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

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
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
                            name,
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

  Future<void> _editProfileDialog(
    String currentName,
    String currentPhone,
    String currentAddress,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditCustomerProfileDialog(
        currentName: currentName,
        currentPhone: currentPhone,
        currentAddress: currentAddress,
        onSave: (name, phone, address) async {
          final ok = await ref.read(customerProvider.notifier).updateProfile({
            'name': name,
            'phone': phone,
            'address': address,
          });
          if (ok) return null;
          return ref.read(customerProvider).error ?? 'Unable to update profile.';
        },
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }
}

class _EditCustomerProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentAddress;
  final Future<String?> Function(String name, String phone, String address) onSave;

  const _EditCustomerProfileDialog({
    required this.currentName,
    required this.currentPhone,
    required this.currentAddress,
    required this.onSave,
  });

  @override
  State<_EditCustomerProfileDialog> createState() => _EditCustomerProfileDialogState();
}

class _EditCustomerProfileDialogState extends State<_EditCustomerProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _phoneCtrl = TextEditingController(text: widget.currentPhone);
    _addressCtrl = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final error = await widget.onSave(
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _addressCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Edit Delivery & Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Sanuthi Lihansa',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Full name cannot be empty';
                  }
                  if (val.trim().length < 2) {
                    return 'Full name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
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
                controller: _addressCtrl,
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
