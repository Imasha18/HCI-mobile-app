import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/user_management_provider.dart';
import '../theme/admin_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Customers', 'Cooks', 'Riders', 'Admins'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> allUsers) {
    return allUsers.where((u) {
      final role = (u['role'] as String? ?? '').toLowerCase();
      final currentTab = _tabs[_tabController.index].toLowerCase();

      bool matchesTab = true;
      if (currentTab == 'customers') matchesTab = role == 'customer';
      if (currentTab == 'cooks') matchesTab = role == 'cook';
      if (currentTab == 'riders') matchesTab = role == 'rider';
      if (currentTab == 'admins') matchesTab = role == 'admin';

      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty || name.contains(query) || email.contains(query);

      return matchesTab && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT VIEWER DIALOG
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // REJECT DOCUMENT DIALOG WITH REASON
  // ---------------------------------------------------------------------------
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
              title: Text(
                'Reject $documentTitle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rider: $riderName',
                      style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rejection Reason *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                    ),
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
                        if (validationError != null) {
                          setDialogState(() => validationError = null);
                        }
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm Rejection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // USER DETAILS MODAL (WITH RIDER VERIFICATION DOCUMENTS SECTION)
  // ---------------------------------------------------------------------------
  void _showUserDetails(Map<String, dynamic> user) async {
    final role = user['role'] as String? ?? 'user';
    final id = user['_id'] as String? ?? user['id'] as String? ?? '';

    // If rider, fetch fresh details
    Map<String, dynamic> liveUser = Map<String, dynamic>.from(user);
    if (role == 'rider') {
      final fresh = await ref.read(userManagementProvider.notifier).fetchRiderDetails(id);
      if (fresh != null) {
        liveUser = fresh;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isBlocked = liveUser['isBlocked'] as bool? ?? false;
            final isVerified = liveUser['isVerified'] as bool? ?? false;
            final vStatus = liveUser['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'not_submitted');
            final vehicle = liveUser['vehicleDetails'] as Map? ?? {};
            final docs = liveUser['verificationDocuments'] as Map? ?? {};

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
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AdminTheme.primaryLight,
                          child: Text(
                            (liveUser['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liveUser['name'] as String? ?? 'User',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                              ),
                              Text(
                                liveUser['email'] as String? ?? '',
                                style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBlocked ? AdminTheme.statusRejectedBg : AdminTheme.statusApprovedBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBlocked ? 'Blocked' : 'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _detailRow('User ID', id),
                    _detailRow('Role', role.toUpperCase()),
                    _detailRow('Phone', liveUser['phone'] as String? ?? 'Not provided'),
                    _detailRow('Address', liveUser['address'] as String? ?? 'Not specified'),
                    if (role == 'cook') _detailRow('Kitchen Name', liveUser['kitchenName'] as String? ?? 'Not specified'),
                    if (role == 'rider') ...[
                      _detailRow('Vehicle', '${vehicle['type'] ?? 'Motorbike'} (${vehicle['plateNumber'] ?? 'Not set'})'),
                      if (vehicle['model'] != null && vehicle['model'].toString().isNotEmpty)
                        _detailRow('Vehicle Model', vehicle['model'].toString()),
                      _detailRow('Overall Status', _formatVerificationStatus(vStatus)),
                    ],

                    // ---------------------------------------------------------
                    // VERIFICATION DOCUMENTS SECTION (FOR RIDERS)
                    // ---------------------------------------------------------
                    if (role == 'rider') ...[
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
                                  Icon(icon, size: 20, color: AdminTheme.primary),
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
                                        child: Text(
                                          'Reason: $rejectionReason',
                                          style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                                        ),
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
                                    // Approve button
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
                                            liveUser = Map<String, dynamic>.from(res['data'] as Map);
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle_outline, size: 14),
                                      label: const Text('Approve', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 6),
                                    // Reject button
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
                                          liveUser['name'] ?? 'Rider',
                                          key,
                                          title,
                                          () async {
                                            final fresh = await ref.read(userManagementProvider.notifier).fetchRiderDetails(id);
                                            if (fresh != null) {
                                              setModalState(() {
                                                liveUser = fresh;
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
                    ],

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isBlocked ? AdminTheme.statusApproved : AdminTheme.statusPending,
                              side: BorderSide(color: isBlocked ? AdminTheme.statusApproved : AdminTheme.statusPending),
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
                            label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Delete User Account'),
                                  content: Text('Are you sure you want to permanently delete "${liveUser['name']}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.statusRejected),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(userManagementProvider.notifier).deleteUser(id);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatVerificationStatus(String status) {
    switch (status) {
      case 'approved':
        return '✓ Approved / Verified';
      case 'pending':
        return '⏳ Pending Admin Review';
      case 'rejected':
        return '✕ Rejected (Needs Attention)';
      default:
        return 'Not Submitted';
    }
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
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final filteredUsers = _filterUsers(state.users);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminTheme.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'User Management',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(userManagementProvider.notifier).loadAllUsers(forceRefresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AdminTheme.primary,
          indicatorWeight: 3,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
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
            child: state.isLoading && state.users.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (context, index) => const UserCardSkeleton(),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: AdminTheme.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No users matching "$_searchQuery"' : 'No users found',
                              style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final id = user['_id'] as String? ?? user['id'] as String? ?? '';
                          final isBlocked = user['isBlocked'] as bool? ?? false;
                          final role = user['role'] as String? ?? 'customer';
                          final isVerified = user['isVerified'] as bool? ?? false;
                          final vStatus = user['verificationStatus'] as String? ?? (isVerified ? 'approved' : 'not_submitted');

                          Color roleColor = AdminTheme.primary;
                          if (role == 'rider') roleColor = const Color(0xFF5E35B1);
                          if (role == 'cook') roleColor = const Color(0xFFE65100);
                          if (role == 'admin') roleColor = const Color(0xFFD81B60);

                          return InkWell(
                            onTap: () => _showUserDetails(user),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: AdminTheme.cardDecoration(),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: roleColor.withValues(alpha: 0.15),
                                    child: Text(
                                      (user['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user['name'] as String? ?? 'User',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                role.toUpperCase(),
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user['email'] as String? ?? '',
                                          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isBlocked ? 'Blocked' : 'Active Account',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                                              ),
                                            ),
                                            if (role == 'rider') ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: vStatus == 'approved'
                                                      ? AdminTheme.statusApprovedBg
                                                      : (vStatus == 'rejected'
                                                          ? AdminTheme.statusRejectedBg
                                                          : AdminTheme.statusPendingBg),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  vStatus == 'approved'
                                                      ? 'Verified'
                                                      : (vStatus == 'rejected' ? 'Needs Attention' : 'Pending Verification'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: vStatus == 'approved'
                                                      ? AdminTheme.statusApproved
                                                      : (vStatus == 'rejected' ? AdminTheme.statusRejected : AdminTheme.statusPending),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: AdminTheme.textSecondary),
                                    onSelected: (choice) async {
                                      if (choice == 'view') {
                                        _showUserDetails(user);
                                      } else if (choice == 'block') {
                                        await ref.read(userManagementProvider.notifier).blockUser(id);
                                      } else if (choice == 'unblock') {
                                        await ref.read(userManagementProvider.notifier).unblockUser(id);
                                      } else if (choice == 'delete') {
                                        await ref.read(userManagementProvider.notifier).deleteUser(id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: isBlocked ? 'unblock' : 'block',
                                        child: Row(
                                          children: [
                                            Icon(isBlocked ? Icons.check_circle_outline : Icons.block, size: 18),
                                            SizedBox(width: 8),
                                            Text(isBlocked ? 'Unblock User' : 'Block User'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: AdminTheme.statusRejected),
                                            SizedBox(width: 8),
                                            Text('Delete User', style: TextStyle(color: AdminTheme.statusRejected)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
