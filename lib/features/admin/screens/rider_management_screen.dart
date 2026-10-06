import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_management_provider.dart';
import '../theme/admin_theme.dart';

class RiderManagementScreen extends ConsumerStatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  ConsumerState<RiderManagementScreen> createState() => _RiderManagementScreenState();
}

class _RiderManagementScreenState extends ConsumerState<RiderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userManagementProvider.notifier).loadRiders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRiderActions(Map<String, dynamic> rider) {
    final id = rider['_id'] as String? ?? rider['id'] as String? ?? '';
    final isBlocked = rider['isBlocked'] as bool? ?? false;
    final isVerified = rider['isVerified'] as bool? ?? false;
    final vStatus = rider['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'pending');
    final vehicle = rider['vehicleDetails'] as Map? ?? {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.two_wheeler_rounded, color: Color(0xFF5E35B1), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider['name'] ?? 'Delivery Rider',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                      Text(
                        rider['email'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _infoRow('Vehicle Type', vehicle['type'] ?? 'Motorbike'),
            _infoRow('Vehicle Model', vehicle['model'] ?? 'Honda Dio'),
            _infoRow('Plate Number', vehicle['plateNumber'] ?? 'WP BZ-4892'),
            _infoRow('Phone', rider['phone'] ?? '+94 77 555 9876'),
            _infoRow('Verification', vStatus.toUpperCase()),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.statusApproved,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(userManagementProvider.notifier).verifyRider(id, 'approved');
                    },
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Approve Rider'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.statusRejected,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(userManagementProvider.notifier).verifyRider(id, 'rejected');
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject Rider'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isBlocked ? AdminTheme.statusApproved : AdminTheme.textSecondary,
                  side: BorderSide(color: isBlocked ? AdminTheme.statusApproved : AdminTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (isBlocked) {
                    await ref.read(userManagementProvider.notifier).unblockUser(id);
                  } else {
                    await ref.read(userManagementProvider.notifier).blockUser(id);
                  }
                },
                icon: Icon(isBlocked ? Icons.check_circle_outline : Icons.block, size: 18),
                label: Text(isBlocked ? 'Unblock Rider' : 'Block Rider Account'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final riders = state.riders.where((r) {
      final name = (r['name'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q);
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
          'Delivery Rider Management',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(userManagementProvider.notifier).loadRiders(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search delivery riders...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AdminTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && state.riders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
                : riders.isEmpty
                    ? const Center(
                        child: Text('No delivery riders found', style: TextStyle(color: AdminTheme.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: riders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = riders[index];
                          final isVerified = r['isVerified'] as bool? ?? false;
                          final vStatus = r['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'pending');
                          final isBlocked = r['isBlocked'] as bool? ?? false;
                          final vehicle = r['vehicleDetails'] as Map? ?? {};

                          Color statusColor = AdminTheme.statusApproved;
                          Color statusBg = AdminTheme.statusApprovedBg;
                          String statusText = 'Approved';

                          if (isBlocked) {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Blocked';
                          } else if (vStatus == 'pending' || !isVerified) {
                            statusColor = AdminTheme.statusPending;
                            statusBg = AdminTheme.statusPendingBg;
                            statusText = 'Pending';
                          } else if (vStatus == 'rejected') {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Rejected';
                          }

                          return InkWell(
                            onTap: () => _showRiderActions(r),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AdminTheme.cardDecoration(),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFEDE7F6),
                                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF5E35B1), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['name'] ?? 'Rider',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${vehicle['type'] ?? 'Motorbike'} • ${vehicle['plateNumber'] ?? 'WP BZ-4892'}',
                                          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${r['rating'] ?? 4.9}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AdminTheme.textSecondary),
                                ],
                              ),
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
