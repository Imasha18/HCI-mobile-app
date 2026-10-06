import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_management_provider.dart';
import '../theme/admin_theme.dart';

class CookManagementScreen extends ConsumerStatefulWidget {
  const CookManagementScreen({super.key});

  @override
  ConsumerState<CookManagementScreen> createState() => _CookManagementScreenState();
}

class _CookManagementScreenState extends ConsumerState<CookManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userManagementProvider.notifier).loadCooks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCookActions(Map<String, dynamic> cook) {
    final id = cook['_id'] as String? ?? cook['id'] as String? ?? '';
    final isBlocked = cook['isBlocked'] as bool? ?? false;
    final isVerified = cook['isVerified'] as bool? ?? false;
    final vStatus = cook['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'pending');

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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AdminTheme.primaryLight,
                  child: const Icon(Icons.restaurant_menu, color: AdminTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cook['kitchenName'] ?? cook['name'] ?? 'Home Cook Kitchen',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                      Text(
                        'Chef: ${cook['name'] ?? ''} (${cook['email'] ?? ''})',
                        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Verification Status:', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                Text(
                  vStatus.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: vStatus == 'approved'
                        ? AdminTheme.statusApproved
                        : vStatus == 'rejected'
                            ? AdminTheme.statusRejected
                            : AdminTheme.statusPending,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kitchen Rating:', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${cook['rating'] ?? 4.8}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kitchen Address:', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                Flexible(
                  child: Text(
                    cook['address'] ?? 'Colombo, Sri Lanka',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AdminTheme.textPrimary),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
                      await ref.read(userManagementProvider.notifier).verifyCook(id, 'approved');
                    },
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Approve Kitchen'),
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
                      await ref.read(userManagementProvider.notifier).verifyCook(id, 'rejected');
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject Kitchen'),
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
                label: Text(isBlocked ? 'Unblock Kitchen Profile' : 'Block Kitchen Profile'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final cooks = state.cooks.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final kitchen = (c['kitchenName'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || kitchen.contains(q);
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
          'Home Cook Management',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(userManagementProvider.notifier).loadCooks(),
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
                hintText: 'Search kitchen or chef...',
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
            child: state.isLoading && state.cooks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
                : cooks.isEmpty
                    ? const Center(
                        child: Text('No home cooks registered', style: TextStyle(color: AdminTheme.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cooks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = cooks[index];
                          final isVerified = c['isVerified'] as bool? ?? false;
                          final vStatus = c['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'pending');
                          final isBlocked = c['isBlocked'] as bool? ?? false;

                          Color statusColor = AdminTheme.statusApproved;
                          Color statusBg = AdminTheme.statusApprovedBg;
                          String statusText = 'Verified';

                          if (isBlocked) {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Blocked';
                          } else if (vStatus == 'pending' || !isVerified) {
                            statusColor = AdminTheme.statusPending;
                            statusBg = AdminTheme.statusPendingBg;
                            statusText = 'Pending Approval';
                          } else if (vStatus == 'rejected') {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Rejected';
                          }

                          return InkWell(
                            onTap: () => _showCookActions(c),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AdminTheme.cardDecoration(),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFFFE0B2),
                                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFFE65100), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['kitchenName'] ?? '${c['name']}\'s Kitchen',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cook: ${c['name'] ?? ''}',
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
                                                  '${c['rating'] ?? 4.8}',
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
