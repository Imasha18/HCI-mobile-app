import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../theme/admin_theme.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchComplaints());
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _showResolutionDialog(Map<String, dynamic> complaint) {
    final id = complaint['_id'] as String? ?? '';
    _responseController.text = 'We investigated the issue with the restaurant/driver and have processed a resolution.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complaint: "${complaint['subject'] ?? ''}"',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Resolution Note for User:',
              style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _responseController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter explanation or compensation note...',
                filled: true,
                fillColor: AdminTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.statusApproved,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await ref.read(notificationProvider.notifier).resolveComplaint(id, _responseController.text.trim());
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Complaint marked as resolved!'), backgroundColor: AdminTheme.statusApproved),
                );
              }
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final complaints = state.complaints;

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
          'Customer Complaints',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(notificationProvider.notifier).fetchComplaints(),
          ),
        ],
      ),
      body: complaints.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: AdminTheme.statusApproved, size: 54),
                  SizedBox(height: 12),
                  Text(
                    'No Complaints Reported!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Customer satisfaction is currently 100%.',
                    style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final c = complaints[index];
                final id = c['_id'] as String? ?? '';
                final user = c['user'] as Map? ?? {};
                final order = c['order'] as Map? ?? {};
                final status = c['status'] as String? ?? 'open';
                final isResolved = status == 'resolved';
                final isRejected = status == 'rejected';

                Color statusColor = AdminTheme.statusPending;
                Color statusBg = AdminTheme.statusPendingBg;

                if (isResolved) {
                  statusColor = AdminTheme.statusApproved;
                  statusBg = AdminTheme.statusApprovedBg;
                } else if (isRejected) {
                  statusColor = AdminTheme.statusRejected;
                  statusBg = AdminTheme.statusRejectedBg;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AdminTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                          Text(
                            c['createdAt'] != null ? (c['createdAt'] as String).substring(0, 10) : 'Recent',
                            style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c['subject'] ?? 'Complaint Subject',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary, height: 1.4),
                      ),
                      const Divider(height: 22),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: AdminTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Filed by: ${user['name'] ?? 'User'} (${user['email'] ?? ''})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary),
                          ),
                        ],
                      ),
                      if (order.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 16, color: AdminTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Related Order: #${(order['_id'] as String? ?? '').substring(0, 8)}',
                              style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                      if (!isResolved && !isRejected) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminTheme.statusApproved,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => _showResolutionDialog(c),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Resolve Complaint'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminTheme.statusRejected,
                                  side: const BorderSide(color: AdminTheme.statusRejected),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await ref.read(notificationProvider.notifier).rejectComplaint(id);
                                  if (!mounted) return;
                                  if (ok) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Complaint closed and rejected'), backgroundColor: AdminTheme.statusRejected),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Dismiss'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
