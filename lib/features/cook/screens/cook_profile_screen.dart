import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cook_provider.dart';
import '../theme/cook_theme.dart';

const List<String> _sriLankanBanks = [
  'Commercial Bank of Ceylon',
  'Bank of Ceylon (BOC)',
  "People's Bank",
  'Sampath Bank',
  'Hatton National Bank (HNB)',
  'Nations Trust Bank (NTB)',
  'Seylan Bank',
  'National Development Bank (NDB)',
  'DFCC Bank',
];

class CookProfileScreen extends ConsumerStatefulWidget {
  const CookProfileScreen({super.key});

  @override
  ConsumerState<CookProfileScreen> createState() => _CookProfileScreenState();
}

class _CookProfileScreenState extends ConsumerState<CookProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(cookProvider.notifier);
      notifier.fetchMyProfile();
      notifier.fetchKitchen();
      notifier.fetchBankDetails();
      notifier.fetchDocuments();
      notifier.fetchSettings();
    });
  }

  // Edit Chef Name & Profile Avatar
  void _editChefDialog(BuildContext context, String currentName, String currentPhone, String currentImage) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final imageCtrl = TextEditingController(text: currentImage);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Chef Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Chef Full Name *',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().length < 2 ? 'Enter a valid name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageCtrl,
                  decoration: InputDecoration(
                    labelText: 'Profile Photo URL',
                    hintText: 'https://images.unsplash.com/...',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
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
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await ref.read(cookProvider.notifier).updateProfile({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                if (imageCtrl.text.trim().isNotEmpty) 'profileImage': imageCtrl.text.trim(),
              });
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Chef profile updated!' : 'Failed to update profile'),
                  backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // Edit Kitchen Profile Modal
  void _editKitchenModal(BuildContext context) {
    final state = ref.read(cookProvider);
    final kitchen = state.kitchen;
    final cook = state.cook;

    final kitchenCtrl = TextEditingController(
      text: kitchen?['kitchenName'] as String? ?? cook?['kitchenName'] as String? ?? '',
    );
    final bioCtrl = TextEditingController(text: kitchen?['bio'] as String? ?? '');
    final phoneCtrl = TextEditingController(
      text: kitchen?['phone'] as String? ?? cook?['phone'] as String? ?? '',
    );
    final addressCtrl = TextEditingController(
      text: kitchen?['address'] as String? ?? cook?['address'] as String? ?? '',
    );
    final hoursCtrl = TextEditingController(
      text: kitchen?['openingHours'] as String? ?? '11:00 AM - 10:00 PM',
    );
    final imageCtrl = TextEditingController(text: kitchen?['image'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kitchen Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: kitchenCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kitchen Name *',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().length < 2 ? 'Enter kitchen name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Kitchen Bio / Story',
                    hintText: 'Fresh homemade traditional dishes crafted with passion...',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone Number',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kitchen Operational Address',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hoursCtrl,
                  decoration: InputDecoration(
                    labelText: 'Operating Hours',
                    hintText: '11:00 AM - 10:00 PM',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kitchen Banner / Photo URL',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: CookTheme.primaryOrange),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final success = await ref.read(cookProvider.notifier).updateKitchen({
                        'kitchenName': kitchenCtrl.text.trim(),
                        'bio': bioCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'openingHours': hoursCtrl.text.trim(),
                        if (imageCtrl.text.trim().isNotEmpty) 'image': imageCtrl.text.trim(),
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Kitchen profile saved!' : 'Failed to update kitchen'),
                          backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                        ),
                      );
                    },
                    child: const Text('Save Kitchen Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bank Account & Payouts Modal
  void _editBankDetailsModal(BuildContext context) {
    final state = ref.read(cookProvider);
    final bank = state.bankDetails;

    final holderCtrl = TextEditingController(text: bank?['accountHolderName'] as String? ?? '');
    String selectedBank = bank?['bankName'] as String? ?? _sriLankanBanks[0];
    if (!_sriLankanBanks.contains(selectedBank)) {
      selectedBank = _sriLankanBanks[0];
    }
    final branchCtrl = TextEditingController(text: bank?['branchName'] as String? ?? '');
    final accCtrl = TextEditingController(text: bank?['accountNumber'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bank Account & Payouts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Direct deposits are processed nightly in Sri Lankan Rupees (LKR) via CEFTS.',
                    style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: holderCtrl,
                    decoration: InputDecoration(
                      labelText: 'Account Holder Name *',
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Enter account holder name' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBank,
                    decoration: InputDecoration(
                      labelText: 'Select Sri Lankan Bank *',
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _sriLankanBanks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedBank = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: branchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Branch Name *',
                      hintText: 'e.g. Kollupitiya, Nugegoda, Kandy',
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter branch name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Account Number *',
                      hintText: '6 to 16 digits',
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter account number';
                      final digits = v.trim().replaceAll(' ', '');
                      if (!RegExp(r'^\d{6,20}$').hasMatch(digits)) {
                        return 'Enter a valid 6-20 digit account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: CookTheme.primaryOrange),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final success = await ref.read(cookProvider.notifier).updateBankDetails(
                              accountHolderName: holderCtrl.text.trim(),
                              bankName: selectedBank,
                              branchName: branchCtrl.text.trim(),
                              accountNumber: accCtrl.text.trim(),
                            );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Payout bank details saved!' : 'Failed to save bank details'),
                            backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                          ),
                        );
                      },
                      child: const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Food Safety & Documents Modal
  void _editDocumentsModal(BuildContext context) {
    final state = ref.read(cookProvider);
    final docs = state.documents;

    final docList = [
      {
        'key': 'nic',
        'title': 'National Identity Card (NIC)',
        'subtitle': 'Required for identity verification & safety assurance',
        'data': docs?['nic'] as Map<String, dynamic>?,
      },
      {
        'key': 'phiCertificate',
        'title': 'Public Health Inspector (PHI) Approval',
        'subtitle': 'Kitchen hygiene inspection certificate',
        'data': docs?['phiCertificate'] as Map<String, dynamic>?,
      },
      {
        'key': 'foodHandlingCertificate',
        'title': 'Food Handling Certificate',
        'subtitle': 'Municipal council approved food handling compliance',
        'data': docs?['foodHandlingCertificate'] as Map<String, dynamic>?,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Food Safety & Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text(
              'HomeBite requires kitchen certifications to ensure customer food safety.',
              style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ...docList.map((item) {
              final key = item['key'] as String;
              final title = item['title'] as String;
              final subtitle = item['subtitle'] as String;
              final data = item['data'] as Map<String, dynamic>?;
              final status = (data?['status'] as String?) ?? 'not_submitted';

              Color badgeColor;
              Color badgeBg;
              String statusLabel;

              switch (status.toLowerCase()) {
                case 'approved':
                  badgeColor = CookTheme.statusGreen;
                  badgeBg = CookTheme.statusGreenBg;
                  statusLabel = 'VERIFIED';
                  break;
                case 'pending':
                  badgeColor = CookTheme.primaryDark;
                  badgeBg = CookTheme.secondaryOrange;
                  statusLabel = 'IN REVIEW';
                  break;
                case 'rejected':
                  badgeColor = CookTheme.statusRed;
                  badgeBg = const Color(0xFFFFEBEE);
                  statusLabel = 'REJECTED';
                  break;
                default:
                  badgeColor = Colors.grey.shade600;
                  badgeBg = Colors.grey.shade200;
                  statusLabel = 'NOT SUBMITTED';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CookTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: CookTheme.textDark),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 11, color: CookTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.upload_file_rounded, color: CookTheme.primaryOrange),
                      tooltip: 'Submit Document',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDocumentSubmitDialog(context, key, title);
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDocumentSubmitDialog(BuildContext context, String documentType, String title) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Submit $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter document URL or reference link for official PHI/CMC compliance review:',
              style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'Document Link / Reference',
                hintText: 'https://docs.homebite.com/cert.pdf',
                filled: true,
                fillColor: CookTheme.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
              final link = urlCtrl.text.trim().isNotEmpty
                  ? urlCtrl.text.trim()
                  : 'https://homebite.com/docs/$documentType-verified.pdf';
              final success = await ref.read(cookProvider.notifier).submitDocument(
                    documentType: documentType,
                    fileUrl: link,
                    fileName: '$documentType.pdf',
                  );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '$title submitted for review!' : 'Submission failed'),
                  backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                ),
              );
            },
            child: const Text('Submit Document'),
          ),
        ],
      ),
    );
  }

  // Settings Modal
  void _editSettingsModal(BuildContext context) {
    final state = ref.read(cookProvider);
    final settings = state.settings;

    final hoursCtrl = TextEditingController(
      text: settings?['operatingHours'] as String? ?? '11:00 AM - 10:00 PM',
    );
    bool autoAccept = settings?['autoAcceptOrders'] as bool? ?? true;
    double radius = (settings?['deliveryRadiusKm'] as num?)?.toDouble() ?? 7.0;
    final notifications = (settings?['notifications'] as Map<String, dynamic>?) ?? {};
    bool orderAlerts = notifications['orderAlerts'] as bool? ?? true;
    bool emailAlerts = notifications['emailAlerts'] as bool? ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kitchen Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CookTheme.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hoursCtrl,
                  decoration: InputDecoration(
                    labelText: 'Operating Hours',
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-Accept Incoming Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Instantly confirm orders from nearby customers', style: TextStyle(fontSize: 12, color: CookTheme.textMuted)),
                  value: autoAccept,
                  activeThumbColor: CookTheme.primaryOrange,
                  activeTrackColor: CookTheme.secondaryOrange,
                  onChanged: (v) => setModalState(() => autoAccept = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Radius: ${radius.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CookTheme.textDark),
                ),
                Slider(
                  value: radius,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  activeColor: CookTheme.primaryOrange,
                  inactiveColor: Colors.grey.shade300,
                  label: '${radius.toStringAsFixed(1)} km',
                  onChanged: (v) => setModalState(() => radius = v),
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Push Notification Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Sound alarm when new order arrives', style: TextStyle(fontSize: 12, color: CookTheme.textMuted)),
                  value: orderAlerts,
                  activeThumbColor: CookTheme.primaryOrange,
                  activeTrackColor: CookTheme.secondaryOrange,
                  onChanged: (v) => setModalState(() => orderAlerts = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email Summary & Receipts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive daily sales digest by email', style: TextStyle(fontSize: 12, color: CookTheme.textMuted)),
                  value: emailAlerts,
                  activeThumbColor: CookTheme.primaryOrange,
                  activeTrackColor: CookTheme.secondaryOrange,
                  onChanged: (v) => setModalState(() => emailAlerts = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: CookTheme.primaryOrange),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final success = await ref.read(cookProvider.notifier).updateSettings({
                        'operatingHours': hoursCtrl.text.trim(),
                        'autoAcceptOrders': autoAccept,
                        'deliveryRadiusKm': radius,
                        'notifications': {
                          'orderAlerts': orderAlerts,
                          'emailAlerts': emailAlerts,
                        },
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Kitchen settings saved!' : 'Failed to update settings'),
                          backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                        ),
                      );
                    },
                    child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);
    final cook = state.cook;
    final kitchen = state.kitchen;
    final bank = state.bankDetails;
    final settings = state.settings;

    final cookName = cook?['name'] as String? ?? 'Home Cook';
    final kitchenName = kitchen?['kitchenName'] as String? ??
        cook?['kitchenName'] as String? ??
        (cook?['name'] != null ? "${cook!['name']}'s Kitchen" : 'Home Kitchen');
    final phone = kitchen?['phone'] as String? ?? cook?['phone'] as String? ?? '';
    final address = kitchen?['address'] as String? ?? cook?['address'] as String? ?? 'Colombo, Sri Lanka';
    final profileImage = cook?['profileImage'] as String? ?? '';
    final rating = (cook?['rating'] as num?)?.toDouble() ?? 5.0;

    // Subtitle texts based on real loaded state
    final bankSubtitle = (bank != null && bank['accountNumber'] != null && (bank['accountNumber'] as String).isNotEmpty)
        ? '${bank['bankName'] ?? 'Bank'} • ${bank['maskedAccountNumber'] ?? '****4912'}'
        : 'Set up Sri Lankan direct deposit bank details';

    final settingsSubtitle = (settings != null && settings['operatingHours'] != null)
        ? '${settings['operatingHours']} • Radius ${settings['deliveryRadiusKm'] ?? 7.0} km'
        : 'Hours, auto-accept, delivery radius & alerts';

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
                  GestureDetector(
                    onTap: () => _editChefDialog(context, cookName, phone, profileImage),
                    child: Stack(
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
                    onTap: () => _editKitchenModal(context),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank Account & Payouts',
                    subtitle: bankSubtitle,
                    onTap: () => _editBankDetailsModal(context),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                  _ProfileOptionTile(
                    icon: Icons.verified_user_rounded,
                    title: 'Food Safety & Documents',
                    subtitle: 'NIC, PHI certification & compliance records',
                    onTap: () => _editDocumentsModal(context),
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
                    subtitle: settingsSubtitle,
                    onTap: () => _editSettingsModal(context),
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
