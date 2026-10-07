import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/rider_provider.dart';
import '../theme/rider_theme.dart';

class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderProvider.notifier).fetchProfile();
    });
  }

  void _showEditVehicleDialog(BuildContext context, Map<String, dynamic>? currentVehicle) {
    final typeController = TextEditingController(text: currentVehicle?['type'] ?? 'Motorbike');
    final modelController = TextEditingController(text: currentVehicle?['model'] ?? 'Honda Dio');
    final plateController = TextEditingController(text: currentVehicle?['plateNumber'] ?? 'WP BZ-4892');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.two_wheeler_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model & Make',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.motorcycle_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: RiderTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final updatedVehicle = {
                  'type': typeController.text.trim(),
                  'model': modelController.text.trim(),
                  'plateNumber': plateController.text.trim(),
                };
                final scaffold = ScaffoldMessenger.of(context);
                final success = await ref.read(riderProvider.notifier).updateProfile({
                  'vehicleDetails': updatedVehicle,
                });
                if (!mounted) return;
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Vehicle updated successfully!' : 'Failed to update vehicle',
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      typeController.dispose();
      modelController.dispose();
      plateController.dispose();
    });
  }

  void _showBankAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Direct Payout Bank Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RiderTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bank', style: TextStyle(color: RiderTheme.textMuted)),
                        Text('Commercial Bank of Ceylon', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Branch', style: TextStyle(color: RiderTheme.textMuted)),
                        Text('Kollupitiya (Code 032)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Account No.', style: TextStyle(color: RiderTheme.textMuted)),
                        Text('8001 •••• •••• 4912', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rider Verification Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDocumentRow('Driving License (Class A / B)', 'Verified', true),
              _buildDocumentRow('Vehicle Revenue License (2026)', 'Verified', true),
              _buildDocumentRow('Third Party / Comprehensive Insurance', 'Verified', true),
              _buildDocumentRow('Police Clearance Certificate', 'Approved', true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentRow(String title, String status, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: RiderTheme.secondaryGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.check, size: 12, color: RiderTheme.primaryDark),
                const SizedBox(width: 4),
                Text(status,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: RiderTheme.primaryDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderProvider);
    final rider = state.rider;

    final name = rider?['name'] as String? ?? 'Delivery Rider';
    final email = rider?['email'] as String? ?? '';
    final phone = rider?['phone'] as String? ?? '';
    final profileImage = rider?['profileImage'] as String?;
    final rating = (rider?['rating'] ?? 5.0).toString();
    final vehicle = rider?['vehicleDetails'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'Rider Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: RiderTheme.textDark,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        color: RiderTheme.primaryGreen,
        onRefresh: () => ref.read(riderProvider.notifier).fetchProfile(forceRefresh: true),
        child: ListView(
          key: const PageStorageKey<String>('rider_profile_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: RiderTheme.softShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: RiderTheme.secondaryGreen,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(profileImage)
                        : null,
                    child: profileImage == null || profileImage.isEmpty
                        ? const Icon(Icons.person, color: RiderTheme.primaryGreen, size: 36)
                        : null,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: RiderTheme.primaryGreen, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(phone, style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted)),
                      Text(email, style: const TextStyle(fontSize: 12, color: RiderTheme.textMuted)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating Rider Rating',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF57F17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Vehicle Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: RiderTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditVehicleDialog(context, vehicle),
                      icon: const Icon(Icons.edit, size: 16, color: RiderTheme.primaryDark),
                      label: const Text('Edit', style: TextStyle(color: RiderTheme.primaryDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVehicleRow(Icons.two_wheeler_rounded, 'Type', vehicle?['type'] ?? 'Motorbike'),
                const Divider(height: 18),
                _buildVehicleRow(Icons.motorcycle_rounded, 'Model', vehicle?['model'] ?? 'Honda Dio'),
                const Divider(height: 18),
                _buildVehicleRow(Icons.credit_card_rounded, 'Plate Number', vehicle?['plateNumber'] ?? 'WP BZ-4892'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Options & Settings Menu
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: RiderTheme.softShadow,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF1565C0), size: 20),
                  ),
                  title: const Text('Bank Account & Payouts', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Commercial Bank · Direct Deposit', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: RiderTheme.textMuted),
                  onTap: () => _showBankAccountModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                    child: const Icon(Icons.description_rounded, color: Color(0xFFFF9800), size: 20),
                  ),
                  title: const Text('Documents & License', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('All 4 documents verified', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: RiderTheme.textMuted),
                  onTap: () => _showDocumentsModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: RiderTheme.secondaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active_rounded, color: RiderTheme.primaryGreen, size: 20),
                  ),
                  title: const Text('Rider Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeTrackColor: RiderTheme.primaryGreen,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFF3E5F5), shape: BoxShape.circle),
                    child: const Icon(Icons.settings_rounded, color: Color(0xFF8E24AA), size: 20),
                  ),
                  title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Language, Sound, Navigation App', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: RiderTheme.textMuted),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigation default: HomeBite In-App Maps')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                await ref.read(riderProvider.notifier).logout();
                if (!mounted) return;
                nav.pushNamedAndRemoveUntil(
                  AppRoutes.roleSelection,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  Widget _buildVehicleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: RiderTheme.textMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: RiderTheme.textMuted, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
