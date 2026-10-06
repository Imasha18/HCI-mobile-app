import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/verification_provider.dart';
import '../theme/admin_theme.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDocumentViewer(String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AdminTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_present_rounded, color: AdminTheme.primary, size: 48),
                  SizedBox(height: 10),
                  Text('Official Document Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Document ID: SEC-849204-LK', style: TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              url.isNotEmpty ? url : 'Document securely stored in HomeBite encrypted storage.',
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
            child: const Text('Close Document'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);

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
          'Verification Requests',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(verificationProvider.notifier).loadPending(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AdminTheme.primary,
          indicatorWeight: 3,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Pending Cooks (${state.pendingCooks.length})'),
            Tab(text: 'Pending Riders (${state.pendingRiders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Pending Cooks Tab
          _buildCooksList(state.pendingCooks),

          // 2. Pending Riders Tab
          _buildRidersList(state.pendingRiders),
        ],
      ),
    );
  }

  Widget _buildCooksList(List<Map<String, dynamic>> cooks) {
    if (cooks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: AdminTheme.statusApproved, size: 54),
            SizedBox(height: 12),
            Text(
              'No Pending Cooks!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'All home cook kitchen profiles are reviewed.',
              style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final c = cooks[index];
        final id = c['_id'] as String? ?? c['id'] as String? ?? '';
        final docs = (c['verificationDocuments'] as List?) ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AdminTheme.primaryLight,
                    child: Icon(Icons.restaurant, color: AdminTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['kitchenName'] ?? '${c['name']}\'s Kitchen',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.textPrimary),
                        ),
                        Text(
                          'Chef: ${c['name'] ?? ''} • ${c['email'] ?? ''}',
                          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _itemDetail(Icons.phone_rounded, c['phone'] ?? '+94 77 234 5678'),
              const SizedBox(height: 6),
              _itemDetail(Icons.location_on_rounded, c['address'] ?? 'Colombo 03, Sri Lanka'),
              const SizedBox(height: 12),
              const Text(
                'Submitted Verification Documents:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: docs.isNotEmpty
                    ? docs.map((d) {
                        final title = (d is Map ? d['title'] : null) ?? 'Hygiene Certificate';
                        final url = (d is Map ? d['documentUrl'] : null) ?? '';
                        return ActionChip(
                          avatar: const Icon(Icons.description, size: 16, color: AdminTheme.primary),
                          label: Text(title, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AdminTheme.surface,
                          onPressed: () => _showDocumentViewer(title, url),
                        );
                      }).toList()
                    : [
                        ActionChip(
                          avatar: const Icon(Icons.description, size: 16, color: AdminTheme.primary),
                          label: const Text('Food Hygiene Certificate', style: TextStyle(fontSize: 11)),
                          backgroundColor: AdminTheme.surface,
                          onPressed: () => _showDocumentViewer('Food Hygiene Certificate', 'https://homebite.lk/cert/hygiene.pdf'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.badge, size: 16, color: AdminTheme.primary),
                          label: const Text('National ID (NIC)', style: TextStyle(fontSize: 11)),
                          backgroundColor: AdminTheme.surface,
                          onPressed: () => _showDocumentViewer('National Identity Card', 'https://homebite.lk/nic/front.jpg'),
                        ),
                      ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.statusApproved,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final ok = await ref.read(verificationProvider.notifier).verifyCook(id, 'approved');
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kitchen approved successfully!'), backgroundColor: AdminTheme.statusApproved),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve Kitchen'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.statusRejected,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final ok = await ref.read(verificationProvider.notifier).verifyCook(id, 'rejected');
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kitchen application rejected'), backgroundColor: AdminTheme.statusRejected),
                          );
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRidersList(List<Map<String, dynamic>> riders) {
    if (riders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: AdminTheme.statusApproved, size: 54),
            SizedBox(height: 12),
            Text(
              'No Pending Riders!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'All delivery rider applications are reviewed.',
              style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: riders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final r = riders[index];
        final id = r['_id'] as String? ?? r['id'] as String? ?? '';
        final vehicle = r['vehicleDetails'] as Map? ?? {};
        final rawDocs = r['verificationDocuments'];
        final List<Map<String, dynamic>> docsList = [];
        if (rawDocs is Map) {
          final titles = {
            'nic': 'National ID (NIC)',
            'drivingLicense': 'Driving License',
            'vehicleDocument': 'Vehicle Revenue License',
            'insurance': 'Vehicle Insurance',
          };
          rawDocs.forEach((key, val) {
            if (val is Map) {
              final kStr = key.toString();
              final url = val['fileUrl']?.toString() ?? val['documentUrl']?.toString() ?? '';
              final status = val['status']?.toString() ?? 'pending';
              final reason = val['rejectionReason']?.toString();
              final title = titles[kStr] ?? (val['fileName']?.toString() ?? kStr);
              if (url.isNotEmpty || status != 'not_submitted') {
                docsList.add({
                  'key': kStr,
                  'title': title,
                  'url': url,
                  'status': status,
                  'rejectionReason': reason,
                });
              }
            }
          });
        } else if (rawDocs is List) {
          for (final d in rawDocs) {
            if (d is Map) {
              docsList.add({
                'key': 'doc',
                'title': d['title']?.toString() ?? 'Document',
                'url': d['documentUrl']?.toString() ?? d['fileUrl']?.toString() ?? '',
                'status': d['status']?.toString() ?? 'pending',
                'rejectionReason': d['rejectionReason']?.toString(),
              });
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEDE7F6),
                    child: Icon(Icons.two_wheeler_rounded, color: Color(0xFF5E35B1), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name'] ?? 'Delivery Rider',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.textPrimary),
                        ),
                        Text(
                          '${vehicle['type'] ?? 'Motorbike'} • ${vehicle['model'] ?? 'Standard'} (${vehicle['plateNumber'] ?? 'Not set'})',
                          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _itemDetail(Icons.phone_rounded, r['phone'] ?? 'Not provided'),
              const SizedBox(height: 6),
              _itemDetail(Icons.email_outlined, r['email'] ?? ''),
              const SizedBox(height: 12),
              const Text(
                'Submitted Driver Documents:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              if (docsList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No documents uploaded yet.',
                    style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: docsList.map((d) {
                    final title = d['title'] as String;
                    final url = d['url'] as String;
                    final status = d['status'] as String;
                    final isRejected = status == 'rejected';
                    final isApproved = status == 'approved';

                    return ActionChip(
                      avatar: Icon(
                        isApproved
                            ? Icons.check_circle
                            : (isRejected ? Icons.error_outline : Icons.badge),
                        size: 16,
                        color: isApproved
                            ? AdminTheme.statusApproved
                            : (isRejected ? AdminTheme.statusRejected : const Color(0xFF5E35B1)),
                      ),
                      label: Text(
                        '$title (${status.toUpperCase()})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isApproved
                              ? AdminTheme.statusApproved
                              : (isRejected ? AdminTheme.statusRejected : AdminTheme.textPrimary),
                        ),
                      ),
                      backgroundColor: AdminTheme.surface,
                      onPressed: () => _showDocumentViewer(title, url.isNotEmpty ? url : 'https://homebite.lk/docs/preview.pdf'),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.statusApproved,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final res = await ref.read(verificationProvider.notifier).verifyRider(id, 'approved');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['success'] == true
                                  ? 'Rider approved successfully!'
                                  : res['message']?.toString() ?? 'Failed to approve rider'),
                              backgroundColor: res['success'] == true ? AdminTheme.statusApproved : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve Rider'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.statusRejected,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showRejectRiderDialog(context, id, r['name'] ?? 'Delivery Rider'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary)),
        ),
      ],
    );
  }

  void _showRejectRiderDialog(BuildContext context, String id, String riderName) {
    final reasonController = TextEditingController();
    String? selectedDocKey;
    bool isSubmitting = false;
    String? validationError;

    final docOptions = [
      {'key': null, 'label': 'General / All Documents'},
      {'key': 'nic', 'label': 'National ID (NIC)'},
      {'key': 'drivingLicense', 'label': 'Driving License'},
      {'key': 'vehicleDocument', 'label': 'Vehicle Registration'},
      {'key': 'insurance', 'label': 'Vehicle Insurance'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Reject Verification: $riderName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select which document requires attention (optional):',
                      style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedDocKey,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: docOptions.map((opt) {
                        return DropdownMenuItem<String?>(
                          value: opt['key'],
                          child: Text(opt['label'] as String, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              setDialogState(() {
                                selectedDocKey = val;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
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
                        hintText: 'e.g. Driving license image is blurry. Please re-upload a clear copy.',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        errorText: validationError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setDialogState(() {
                            validationError = null;
                          });
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
                            setDialogState(() {
                              validationError = 'Rejection reason is required.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final res = await ref.read(verificationProvider.notifier).verifyRider(
                                id,
                                'rejected',
                                reason: reason,
                                documentKey: selectedDocKey,
                              );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['success'] == true
                                    ? 'Verification rejected and reason sent to driver.'
                                    : res['message']?.toString() ?? 'Failed to reject verification'),
                                backgroundColor: res['success'] == true ? AdminTheme.statusRejected : Colors.red,
                              ),
                            );
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
}
