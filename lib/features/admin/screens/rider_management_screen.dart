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

  void _showDocumentViewer(BuildContext context, String title, String url) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPdf && url.startsWith('http')) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AdminTheme.surface,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_present_rounded, color: AdminTheme.primary, size: 48),
                        SizedBox(height: 8),
                        Text('Official Document File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                      color: isPdf ? Colors.red : AdminTheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPdf ? 'PDF Official Document' : 'Document File Stored',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text('Encrypted HomeBite Document', style: TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SelectableText(
              url.isNotEmpty ? url : 'Document securely stored in HomeBite encrypted cloud.',
              style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRejectDocumentDialog(
    BuildContext context,
    String riderId,
    String riderName,
    String documentKey,
    String documentTitle,
    VoidCallback onSuccess,
  ) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    String? validationError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Reject $documentTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rider: $riderName', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
                    const SizedBox(height: 12),
                    const Text('Rejection Reason *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'e.g. Image is unclear. Please upload a clearer copy.',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        errorText: validationError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) {
                        if (validationError != null) setDialogState(() => validationError = null);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.statusRejected,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            setDialogState(() => validationError = 'Rejection reason is required.');
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final res = await ref.read(userManagementProvider.notifier).verifyRiderDocument(
                                riderId,
                                documentKey,
                                'rejected',
                                reason: reason,
                              );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['success'] == true
                                    ? '$documentTitle rejected and reason saved.'
                                    : res['message']?.toString() ?? 'Failed to reject document'),
                                backgroundColor: res['success'] == true ? AdminTheme.statusRejected : Colors.red,
                              ),
                            );
                          }
                          if (res['success'] == true) {
                            onSuccess();
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Rejection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRiderActions(Map<String, dynamic> rider) async {
    final id = rider['_id'] as String? ?? rider['id'] as String? ?? '';
    Map<String, dynamic> liveRider = Map<String, dynamic>.from(rider);

    final fresh = await ref.read(userManagementProvider.notifier).fetchRiderDetails(id);
    if (fresh != null) {
      liveRider = fresh;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isBlocked = liveRider['isBlocked'] as bool? ?? false;
          final isVerified = liveRider['isVerified'] as bool? ?? false;
          final vStatus = liveRider['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'not_submitted');
          final vehicle = liveRider['vehicleDetails'] as Map? ?? {};
          final docs = liveRider['verificationDocuments'] as Map? ?? {};

          final docConfig = [
            {'key': 'drivingLicense', 'title': 'Driving License', 'icon': Icons.drive_eta_outlined},
            {'key': 'nic', 'title': 'National ID (NIC)', 'icon': Icons.badge_outlined},
            {'key': 'vehicleDocument', 'title': 'Vehicle Registration', 'icon': Icons.receipt_long_outlined},
            {'key': 'insurance', 'title': 'Vehicle Insurance', 'icon': Icons.security_outlined},
          ];

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
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
                              liveRider['name'] ?? 'Delivery Rider',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                            ),
                            Text(
                              liveRider['email'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: vStatus == 'approved'
                              ? AdminTheme.statusApprovedBg
                              : (vStatus == 'rejected' ? AdminTheme.statusRejectedBg : AdminTheme.statusPendingBg),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: vStatus == 'approved'
                                ? AdminTheme.statusApproved
                                : (vStatus == 'rejected' ? AdminTheme.statusRejected : AdminTheme.statusPending),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _infoRow('Vehicle Type', vehicle['type'] ?? 'Motorbike'),
                  _infoRow('Vehicle Model', (vehicle['model'] != null && vehicle['model'].toString().isNotEmpty) ? vehicle['model'] : 'Not set'),
                  _infoRow('Plate Number', vehicle['plateNumber'] ?? 'Not set'),
                  _infoRow('Phone', liveRider['phone'] ?? 'Not provided'),
                  _infoRow('Overall Status', vStatus.toUpperCase()),

                  // -----------------------------------------------------------
                  // VERIFICATION DOCUMENTS SECTION
                  // -----------------------------------------------------------
                  const SizedBox(height: 18),
                  const Text(
                    'Verification Documents',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review uploaded driver documents. You can approve or reject each individually.',
                    style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ...docConfig.map((cfg) {
                    final key = cfg['key'] as String;
                    final title = cfg['title'] as String;
                    final icon = cfg['icon'] as IconData;

                    final docData = docs[key] is Map ? docs[key] as Map : null;
                    final fileUrl = docData?['fileUrl']?.toString() ?? '';
                    final docStatus = docData?['status']?.toString() ?? 'not_submitted';
                    final rejectionReason = docData?['rejectionReason']?.toString();
                    final hasFile = fileUrl.trim().isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: docStatus == 'rejected'
                              ? Colors.red.shade300
                              : (docStatus == 'approved' ? Colors.green.shade300 : AdminTheme.border),
                          width: docStatus == 'rejected' || docStatus == 'approved' ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 20, color: const Color(0xFF5E35B1)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.textPrimary),
                                ),
                              ),
                              _buildDocStatusBadge(docStatus),
                            ],
                          ),
                          if (docStatus == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text('Reason: $rejectionReason', style: TextStyle(fontSize: 11, color: Colors.red.shade900)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (hasFile) ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showDocumentViewer(context, title, fileUrl),
                                  icon: const Icon(Icons.visibility_outlined, size: 14),
                                  label: const Text('View Document', style: TextStyle(fontSize: 11)),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminTheme.statusApproved,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final res = await ref.read(userManagementProvider.notifier).verifyRiderDocument(
                                          id,
                                          key,
                                          'approved',
                                        );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['success'] == true
                                              ? '$title approved successfully!'
                                              : res['message']?.toString() ?? 'Approval failed'),
                                          backgroundColor: res['success'] == true ? AdminTheme.statusApproved : Colors.red,
                                        ),
                                      );
                                    }
                                    if (res['success'] == true && res['data'] is Map) {
                                      setModalState(() {
                                        liveRider = Map<String, dynamic>.from(res['data'] as Map);
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 14),
                                  label: const Text('Approve', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminTheme.statusRejected,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    _showRejectDocumentDialog(
                                      context,
                                      id,
                                      liveRider['name'] ?? 'Rider',
                                      key,
                                      title,
                                      () async {
                                        final freshRider = await ref.read(userManagementProvider.notifier).fetchRiderDetails(id);
                                        if (freshRider != null) {
                                          setModalState(() {
                                            liveRider = freshRider;
                                          });
                                        }
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.close_rounded, size: 14),
                                  label: const Text('Reject', style: TextStyle(fontSize: 11)),
                                ),
                              ] else ...[
                                const Text(
                                  'No document uploaded yet',
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AdminTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 18),
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
        },
      ),
    );
  }

  Widget _buildDocStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'approved':
        bg = AdminTheme.statusApprovedBg;
        fg = AdminTheme.statusApproved;
        label = 'APPROVED';
        break;
      case 'pending':
        bg = AdminTheme.statusPendingBg;
        fg = AdminTheme.statusPending;
        label = 'PENDING';
        break;
      case 'rejected':
        bg = AdminTheme.statusRejectedBg;
        fg = AdminTheme.statusRejected;
        label = 'REJECTED';
        break;
      default:
        bg = AdminTheme.surface;
        fg = AdminTheme.textSecondary;
        label = 'NOT SUBMITTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
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
            onPressed: () => ref.read(userManagementProvider.notifier).loadRiders(forceRefresh: true),
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
                          final vStatus = r['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'not_submitted');
                          final isBlocked = r['isBlocked'] as bool? ?? false;
                          final vehicle = r['vehicleDetails'] as Map? ?? {};

                          Color statusColor = AdminTheme.statusApproved;
                          Color statusBg = AdminTheme.statusApprovedBg;
                          String statusText = 'Verified';

                          if (isBlocked) {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Blocked';
                          } else if (vStatus == 'pending') {
                            statusColor = AdminTheme.statusPending;
                            statusBg = AdminTheme.statusPendingBg;
                            statusText = 'Pending';
                          } else if (vStatus == 'rejected') {
                            statusColor = AdminTheme.statusRejected;
                            statusBg = AdminTheme.statusRejectedBg;
                            statusText = 'Needs Attention';
                          } else if (vStatus == 'not_submitted') {
                            statusColor = AdminTheme.textSecondary;
                            statusBg = AdminTheme.surface;
                            statusText = 'Unverified';
                          }

                          return InkWell(
                            onTap: () => _showRiderActions(r),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AdminTheme.cardDecoration(),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFEDE7F6),
                                    child: Icon(Icons.two_wheeler_rounded, color: Color(0xFF5E35B1), size: 24),
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
                                          '${vehicle['type'] ?? 'Motorbike'} • ${vehicle['plateNumber'] ?? 'Plate not set'}',
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
                                                  '${r['rating'] ?? 5.0}',
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
