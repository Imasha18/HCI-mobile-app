import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cook_provider.dart';
import '../theme/cook_theme.dart';

class CookProfileScreen extends ConsumerStatefulWidget {
  const CookProfileScreen({super.key});

  @override
  ConsumerState<CookProfileScreen> createState() => _CookProfileScreenState();
}

class _CookProfileScreenState extends ConsumerState<CookProfileScreen> {
  void _editKitchenDialog(BuildContext context, String currentKitchen, String currentPhone, String currentAddress) {
    final kitchenCtrl = TextEditingController(text: currentKitchen);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final addressCtrl = TextEditingController(text: currentAddress);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Kitchen Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kitchenCtrl,
                decoration: const InputDecoration(labelText: 'Kitchen Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Kitchen Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CookTheme.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CookTheme.primaryOrange),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(cookProvider.notifier).updateProfile({
                'kitchenName': kitchenCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Kitchen profile updated!'),
                  backgroundColor: CookTheme.statusGreen,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 14, color: CookTheme.textMuted, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CookTheme.primaryOrange),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);
    final cook = state.cook;

    final cookName = cook?['name'] as String? ?? 'Chef Sunethra Silva';
    final kitchenName = cook?['kitchenName'] as String? ?? "Amma's Spice Kitchen";
    final phone = cook?['phone'] as String? ?? '+94 77 234 5678';
    final address = cook?['address'] as String? ?? '45/2 Galle Road, Colombo 03, Sri Lanka';
    final profileImage = cook?['profileImage'] as String? ?? '';
    final rating = (cook?['rating'] as num?)?.toDouble() ?? 4.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Cook Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: CookTheme.textDark, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: CookTheme.softShadow,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: CookTheme.primaryOrange, width: 3),
                          image: profileImage.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(profileImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: CookTheme.secondaryOrange,
                        ),
                        child: profileImage.isEmpty
                            ? const Icon(Icons.person, size: 48, color: CookTheme.primaryOrange)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: CookTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    cookName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kitchenName,
                    style: const TextStyle(fontSize: 14, color: CookTheme.primaryDark, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9C4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF57F17), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$rating Rating',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF57F17)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: CookTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            address.split(',').first,
                            style: const TextStyle(fontSize: 13, color: CookTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile Options Menu Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: CookTheme.softShadow,
              ),
              child: Column(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.storefront_rounded,
                    title: 'Kitchen Profile',
                    subtitle: 'Edit kitchen name, bio, and operational address',
                    onTap: () => _editKitchenDialog(context, kitchenName, phone, address),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank Account & Payouts',
                    subtitle: 'Direct deposit active • Commercial Bank ...4912',
                    onTap: () => _showInfoSheet(
                      context,
                      'Bank Account Settings',
                      'Your payout account is linked to Commercial Bank of Ceylon (Account ending in 4912, Kollupitiya Branch). Daily earnings automatically transfer in Sri Lankan Rupees (Rs.) every midnight via CEFTS.',
                    ),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.verified_user_rounded,
                    title: 'Food Safety & Documents',
                    subtitle: 'Public Health Inspector (PHI) verified',
                    onTap: () => _showInfoSheet(
                      context,
                      'Verified Kitchen Documents',
                      'PHI Hygiene Certification: Active (Valid until 2027)\nColombo Municipal Council (CMC) Food Handling Registration: Approved\nKitchen Inspection: Grade A approved\nLiability Insurance: Enrolled via HomeBite Guarantee.',
                    ),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Push notifications & order alerts',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.cookNotifications),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Preferences, language, and kitchen hours',
                    onTap: () => _showInfoSheet(
                      context,
                      'Kitchen Settings',
                      'Operating Hours: 11:00 AM - 10:00 PM\nDelivery Coverage: Colombo & Western Province (7.0 km)\nCurrency: Sri Lankan Rupee (LKR / Rs.)\nAuto-Accept Orders: Enabled',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: CookTheme.statusRed,
                  side: const BorderSide(color: CookTheme.statusRed, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  await ref.read(cookProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.cookLogin, (_) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out of Kitchen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CookTheme.secondaryOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: CookTheme.primaryOrange, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CookTheme.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: CookTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}
