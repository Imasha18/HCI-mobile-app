import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _pushNotifications = true;
  bool _auditAlerts = true;

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final user = adminState.adminUser ?? {};

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
          'Admin Profile & Settings',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Admin Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AdminTheme.cardDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AdminTheme.primaryLight,
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AdminTheme.primary, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user['name'] ?? 'System Administrator',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'admin@homebite.com',
                    style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SUPER ADMIN • FULL ACCESS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // System Infrastructure Information
            _sectionHeader('System Infrastructure'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AdminTheme.cardDecoration(),
              child: Column(
                children: [
                  _infraRow(Icons.storage_rounded, 'Database Engine', 'MongoDB Atlas (Connected)', AdminTheme.statusApproved),
                  const Divider(height: 20),
                  _infraRow(Icons.security_rounded, 'Authentication', 'JWT + Role Middleware', AdminTheme.statusApproved),
                  const Divider(height: 20),
                  _infraRow(Icons.notifications_active_rounded, 'Push Gateway', 'Firebase Cloud Messaging', const Color(0xFF1976D2)),
                  const Divider(height: 20),
                  _infraRow(Icons.cloud_done_rounded, 'Media Hosting', 'Cloudinary Asset CDN', const Color(0xFF00897B)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Administrative Preferences
            _sectionHeader('Administrative Preferences'),
            const SizedBox(height: 10),
            Container(
              decoration: AdminTheme.cardDecoration(),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Live Activity Push Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive notifications for new cook registrations & complaints', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    value: _pushNotifications,
                    activeThumbColor: AdminTheme.primary,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Security & Audit Logging', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Audit block/unblock actions and meal moderation changes', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                    value: _auditAlerts,
                    activeThumbColor: AdminTheme.primary,
                    onChanged: (val) => setState(() => _auditAlerts = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.statusRejectedBg,
                  foregroundColor: AdminTheme.statusRejected,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await ref.read(adminProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Logout of Admin Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
      ),
    );
  }

  Widget _infraRow(IconData icon, String title, String subtitle, Color statusColor) {
    return Row(
      children: [
        Icon(icon, color: AdminTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminTheme.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: statusColor, size: 16),
      ],
    );
  }
}
