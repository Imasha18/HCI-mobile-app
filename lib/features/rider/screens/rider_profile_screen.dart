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
      ref.read(riderProvider.notifier).fetchProfile(forceRefresh: true);
    });
  }

  // ---------------------------------------------------------------------------
  // VEHICLE DETAILS EDIT DIALOG
  // ---------------------------------------------------------------------------
  void _showEditVehicleDialog(BuildContext context, Map<String, dynamic>? currentVehicle) {
    final typeController = TextEditingController(text: currentVehicle?['type'] ?? 'Motorbike');
    final modelController = TextEditingController(text: currentVehicle?['model'] ?? '');
    final plateController = TextEditingController(text: currentVehicle?['plateNumber'] ?? '');
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: typeController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        hintText: 'e.g. Motorbike, Scooter',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.two_wheeler_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Model & Make',
                        hintText: 'e.g. Honda Dio 110',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.motorcycle_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: plateController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'License Plate Number',
                        hintText: 'e.g. WP BDF-4821',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: RiderTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RiderTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });

                          final updatedVehicle = {
                            'type': typeController.text.trim(),
                            'model': modelController.text.trim(),
                            'plateNumber': plateController.text.trim(),
                          };

                          final res = await ref.read(riderProvider.notifier).updateProfile({
                            'vehicleDetails': updatedVehicle,
                          });

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vehicle details updated successfully!'),
                                  backgroundColor: RiderTheme.primaryGreen,
                                ),
                              );
                            }
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorMessage = res['message']?.toString() ?? 'Failed to update vehicle details';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BANK ACCOUNT MODAL
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // DOCUMENT VERIFICATION MODAL & UPLOAD FLOW
  // ---------------------------------------------------------------------------
  void _showDocumentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final state = ref.watch(riderProvider);
            final rider = state.rider;
            final verificationStatus = rider?['verificationStatus'] as String? ?? 'not_submitted';
            final rawDocs = (rider?['verificationDocuments'] as Map?) ?? {};

            final requiredDocsConfig = [
              {
                'key': 'nic',
                'title': 'National ID (NIC)',
                'description': 'Front & back of your Sri Lankan National Identity Card',
                'icon': Icons.badge_outlined,
                'sampleUrl': 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600',
              },
              {
                'key': 'drivingLicense',
                'title': 'Driving License',
                'description': 'Valid Class A/B Motor Traffic Department driving license',
                'icon': Icons.drive_eta_outlined,
                'sampleUrl': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600',
              },
              {
                'key': 'vehicleDocument',
                'title': 'Vehicle Revenue License',
                'description': 'Valid annual revenue license matching your vehicle plate',
                'icon': Icons.receipt_long_outlined,
                'sampleUrl': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=600',
              },
              {
                'key': 'insurance',
                'title': 'Vehicle Insurance',
                'description': 'Active third-party or comprehensive insurance certificate',
                'icon': Icons.security_outlined,
                'sampleUrl': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600',
              },
            ];

            // Count uploaded
            int uploadedCount = 0;
            for (final cfg in requiredDocsConfig) {
              final k = cfg['key'] as String;
              final d = rawDocs[k] is Map ? rawDocs[k] as Map : null;
              final url = d?['fileUrl']?.toString() ?? '';
              if (url.trim().isNotEmpty) {
                uploadedCount++;
              }
            }

            final bool allUploaded = uploadedCount == requiredDocsConfig.length;
            final bool isApproved = verificationStatus == 'approved';
            final bool isPending = verificationStatus == 'pending';

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification Documents',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'All 4 documents are required for delivery partner approval.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(verificationStatus),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Document List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: requiredDocsConfig.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (itemCtx, index) {
                        final cfg = requiredDocsConfig[index];
                        final key = cfg['key'] as String;
                        final title = cfg['title'] as String;
                        final description = cfg['description'] as String;
                        final icon = cfg['icon'] as IconData;
                        final sampleUrl = cfg['sampleUrl'] as String;

                        final docData = rawDocs[key] is Map ? rawDocs[key] as Map : null;
                        final fileUrl = docData?['fileUrl']?.toString() ?? '';
                        final docStatus = docData?['status']?.toString() ?? 'not_submitted';
                        final rejectionReason = docData?['rejectionReason']?.toString();
                        final hasFile = fileUrl.trim().isNotEmpty;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: docStatus == 'rejected'
                                  ? Colors.red.shade300
                                  : (docStatus == 'approved'
                                      ? Colors.green.shade300
                                      : Colors.grey.shade200),
                              width: docStatus == 'rejected' ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: docStatus == 'approved'
                                          ? Colors.green.shade50
                                          : (docStatus == 'rejected'
                                              ? Colors.red.shade50
                                              : const Color(0xFFF1F7F3)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 22,
                                      color: docStatus == 'approved'
                                          ? Colors.green.shade700
                                          : (docStatus == 'rejected'
                                              ? Colors.red.shade700
                                              : RiderTheme.primaryGreen),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          description,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildDocBadge(docStatus, hasFile),
                                ],
                              ),

                              // Rejection Reason Box
                              if (docStatus == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Rejection Reason:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              rejectionReason,
                                              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Upload info & Actions
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (hasFile) ...[
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showDocumentPreview(context, title, fileUrl),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.attachment, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'View Attachment',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade700,
                                                  decoration: TextDecoration.underline,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Text(
                                        'No document uploaded',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                                      ),
                                    ),
                                  ],
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(
                                        color: docStatus == 'rejected'
                                            ? Colors.red
                                            : RiderTheme.primaryGreen,
                                      ),
                                      foregroundColor: docStatus == 'rejected'
                                          ? Colors.red
                                          : RiderTheme.primaryGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      _showUploadDialog(
                                        context: context,
                                        documentKey: key,
                                        documentTitle: title,
                                        currentUrl: fileUrl,
                                        sampleUrl: sampleUrl,
                                        onSaved: (newUrl, newName) async {
                                          final res = await ref.read(riderProvider.notifier).uploadOrReplaceDocument(
                                                documentKey: key,
                                                fileUrl: newUrl,
                                                fileName: newName,
                                              );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['success'] == true
                                                    ? '$title uploaded and submitted for admin review.'
                                                    : res['message']?.toString() ?? 'Failed to upload document'),
                                                backgroundColor: res['success'] == true ? RiderTheme.primaryGreen : Colors.red,
                                              ),
                                            );
                                          }
                                          setModalState(() {});
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      docStatus == 'rejected'
                                          ? Icons.refresh_rounded
                                          : (hasFile ? Icons.edit_outlined : Icons.upload_file_rounded),
                                      size: 14,
                                    ),
                                    label: Text(
                                      docStatus == 'rejected'
                                          ? 'Upload New'
                                          : (hasFile ? 'Replace' : 'Upload'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isApproved) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: RiderTheme.secondaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: RiderTheme.primaryDark, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Documents Verified. You are approved for deliveries.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: RiderTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isPending) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, color: Color(0xFFE65100), size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Verification Pending: Your documents have been submitted and are waiting for admin approval.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: allUploaded ? RiderTheme.primaryGreen : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                if (!allUploaded) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please upload all required documents before submitting for verification.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final submitRes = await ref.read(riderProvider.notifier).submitVerification(
                                      Map<String, dynamic>.from(rawDocs),
                                    );
                                if (!context.mounted) return;

                                if (submitRes['success'] == true) {
                                  Navigator.pop(modalCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Documents submitted for verification successfully! Waiting for admin approval.'),
                                      backgroundColor: RiderTheme.primaryGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(submitRes['message']?.toString() ?? 'Submission failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                allUploaded
                                    ? 'Submit for Verification'
                                    : 'Upload All Documents ($uploadedCount/4)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            child: const Text('Close', style: TextStyle(color: RiderTheme.textMuted)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UPLOAD DOCUMENT DIALOG
  // ---------------------------------------------------------------------------
  void _showUploadDialog({
    required BuildContext context,
    required String documentKey,
    required String documentTitle,
    required String currentUrl,
    required String sampleUrl,
    required Future<void> Function(String url, String name) onSaved,
  }) {
    final urlController = TextEditingController(text: currentUrl.isNotEmpty ? currentUrl : '');
    final nameController = TextEditingController(text: '$documentTitle Document');
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Upload $documentTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provide a valid document image or secure file URL:',
                      style: TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: urlController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        labelText: 'Document URL',
                        hintText: 'https://...',
                        errorText: errorText,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.link_rounded),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(() => errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Document Label / File Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Quick sample autofill
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () {
                              setDialogState(() {
                                urlController.text = sampleUrl;
                                errorText = null;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Use verified sample document template',
                                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: RiderTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RiderTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final url = urlController.text.trim();
                          if (url.isEmpty) {
                            setDialogState(() => errorText = 'Document URL is required');
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await onSaved(url, nameController.text.trim());
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorText = 'Failed to save document: $e';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Document'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT PREVIEW MODAL
  // ---------------------------------------------------------------------------
  void _showDocumentPreview(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey.shade100,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_present_rounded, color: RiderTheme.primaryGreen, size: 48),
                      SizedBox(height: 8),
                      Text('Official Document File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              url,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderTheme.primaryGreen,
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
  // BADGES & HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'approved':
        bg = RiderTheme.secondaryGreen;
        fg = RiderTheme.primaryDark;
        label = '✓ APPROVED';
        break;
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = '⏳ PENDING REVIEW';
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = Colors.red;
        label = '✕ REJECTED';
        break;
      default:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF546E7A);
        label = 'NOT SUBMITTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildDocBadge(String status, bool hasFile) {
    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: RiderTheme.secondaryGreen, borderRadius: BorderRadius.circular(6)),
        child: const Text(
          'APPROVED',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RiderTheme.primaryDark),
        ),
      );
    }
    if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
        child: const Text(
          'REJECTED',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      );
    }
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)),
        child: const Text(
          'PENDING',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hasFile ? 'ATTACHED' : 'REQUIRED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: hasFile ? RiderTheme.primaryDark : const Color(0xFF546E7A),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
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

    final verificationStatus = rider?['verificationStatus'] as String? ?? 'not_submitted';
    final isVerified = rider?['isVerified'] == true || verificationStatus == 'approved';
    final rawDocs = (rider?['verificationDocuments'] as Map?) ?? {};

    // Check if there are rejected documents
    final List<Map<String, String>> rejectedDocs = [];
    final docLabelMap = {
      'nic': 'National ID (NIC)',
      'drivingLicense': 'Driving License',
      'vehicleDocument': 'Vehicle Revenue License',
      'insurance': 'Vehicle Insurance',
    };
    rawDocs.forEach((k, v) {
      if (v is Map && v['status'] == 'rejected') {
        rejectedDocs.add({
          'key': k.toString(),
          'title': docLabelMap[k.toString()] ?? k.toString(),
          'reason': (v['rejectionReason']?.toString()) ?? 'Please upload a clear, valid copy.',
        });
      }
    });

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
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: RiderTheme.primaryGreen, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: RiderTheme.secondaryGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: RiderTheme.primaryDark),
                                SizedBox(width: 4),
                                Text(
                                  '✓ Verified Delivery Partner',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: RiderTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (verificationStatus == 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFE65100)),
                                SizedBox(width: 4),
                                Text(
                                  'Verification Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (verificationStatus == 'rejected')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  'Verification Needs Attention',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF546E7A)),
                                SizedBox(width: 4),
                                Text(
                                  'Documents Required',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF546E7A),
                                  ),
                                ),
                              ],
                            ),
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

            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // VERIFICATION STATUS BANNER
            // -----------------------------------------------------------------
            if (isVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: RiderTheme.primaryDark, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ Verified Delivery Partner',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RiderTheme.primaryDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Documents Verified. Your profile is active to receive deliveries.',
                            style: TextStyle(fontSize: 12, color: RiderTheme.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (verificationStatus == 'pending') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Color(0xFFE65100), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Verification Pending',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Verification Pending: Your documents have been submitted and are waiting for admin approval.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBF360C)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFE65100)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showDocumentsModal(context),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Submitted Documents', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ] else if (verificationStatus == 'rejected') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Verification Needs Attention',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (rejectedDocs.isNotEmpty) ...[
                      ...rejectedDocs.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    '${r['title']}: ${r['reason']}',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ] else ...[
                      const Text(
                        'One or more documents require attention. Please re-upload clear copies to resubmit.',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showDocumentsModal(context),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload New Document & Resubmit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RiderTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_late_outlined, color: RiderTheme.primaryGreen, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Verification Documents Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RiderTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please upload all 4 required documents (NIC, Driving License, Vehicle Revenue License, and Insurance) before submitting for verification.',
                      style: TextStyle(fontSize: 12, color: RiderTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RiderTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showDocumentsModal(context),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload Verification Documents', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

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
                  _buildVehicleRow(
                    Icons.motorcycle_rounded,
                    'Model',
                    (vehicle?['model'] != null && vehicle!['model'].toString().isNotEmpty) ? vehicle['model'] : 'Not set',
                  ),
                  const Divider(height: 18),
                  _buildVehicleRow(
                    Icons.credit_card_rounded,
                    'Plate Number',
                    (vehicle?['plateNumber'] != null && vehicle!['plateNumber'].toString().isNotEmpty) ? vehicle['plateNumber'] : 'Not set',
                  ),
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
                      decoration: BoxDecoration(
                        color: isVerified
                            ? RiderTheme.secondaryGreen
                            : (verificationStatus == 'rejected' ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVerified
                            ? Icons.verified_user_rounded
                            : (verificationStatus == 'rejected' ? Icons.error_outline : Icons.description_rounded),
                        color: isVerified
                            ? RiderTheme.primaryGreen
                            : (verificationStatus == 'rejected' ? Colors.red : const Color(0xFFFF9800)),
                        size: 20,
                      ),
                    ),
                    title: const Text('Documents & License', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isVerified
                          ? 'Documents Verified'
                          : (verificationStatus == 'pending'
                              ? 'Verification pending admin review'
                              : (verificationStatus == 'rejected'
                                  ? 'Action required · Document rejected'
                                  : '4 documents required for verification')),
                      style: TextStyle(
                        fontSize: 12,
                        color: verificationStatus == 'rejected' ? Colors.red : RiderTheme.textMuted,
                        fontWeight: verificationStatus == 'rejected' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusChip(verificationStatus),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: RiderTheme.textMuted),
                      ],
                    ),
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
