import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _address = '';
  String _phone = '';
  bool _saveAsDefault = false;
  bool _initialized = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customer = ref.read(customerProvider);
      if (customer.user == null && !customer.isLoading) {
        ref.read(customerProvider.notifier).loadProfile();
      }
    });
  }

  void _syncSavedDetails(Map<String, dynamic>? user) {
    if (!_initialized && user != null) {
      _address = (user['address'] as String?)?.trim() ?? '';
      _phone = (user['phone'] as String?)?.trim() ?? '';
      _initialized = true;
    }
  }

  void _openAddressDialog(BuildContext context) {
    final addressCtrl = TextEditingController(text: _address);
    final phoneCtrl = TextEditingController(text: _phone);
    bool saveDefault = _saveAsDefault;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Change Delivery Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify the delivery address and phone number for this order.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressCtrl,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      hintText: 'No. 25, Main Street, Nugegoda, Colombo',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (val) => val == null || val.trim().length < 5
                        ? 'Please enter a complete delivery address'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '077 123 4567 or +94 77 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final cleaned = val.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
                      final regex = RegExp(r'^(?:(?:\+94|0094|94|0)?[1-9]\d{8})$');
                      if (!regex.hasMatch(cleaned)) {
                        return 'Enter a valid Sri Lankan phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFFFF7A00),
                    title: const Text(
                      'Save this as my default address',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    value: saveDefault,
                    onChanged: (val) {
                      setDialogState(() {
                        saveDefault = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                setState(() {
                  _address = addressCtrl.text.trim();
                  _phone = phoneCtrl.text.trim();
                  _saveAsDefault = saveDefault;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Use for this order'),
            ),
          ],
        ),
      ),
    ).then((_) {
      addressCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  Future<void> _placeOrder() async {
    if (_loading) return;
    if (_address.trim().isEmpty || _phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add your delivery address and phone number before placing an order.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.items.isEmpty) return;

    setState(() => _loading = true);
    try {
      final order = await ref.read(orderProvider.notifier).createOrder(
            cart,
            _address.trim(),
            phone: _phone.trim(),
            saveAsDefault: _saveAsDefault,
          );

      if (_saveAsDefault) {
        ref.read(customerProvider.notifier).updateProfile({
          'address': _address.trim(),
          'phone': _phone.trim(),
        });
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.payment,
          arguments: {'orderId': order.id, 'amount': order.total},
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final cart = ref.watch(cartProvider);

    _syncSavedDetails(customerState.user);

    final customerName =
        (customerState.user?['name'] as String?) ?? 'HomeBite Customer';
    final hasMissingInfo = _address.isEmpty || _phone.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        data: (value) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Warning for existing customers without address/phone
            if (hasMissingInfo) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE65100),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery information required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Please add your delivery address and phone number before placing an order.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF7E3900),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openAddressDialog(context),
                            child: const Text('Add Details Now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Delivery Details Card
            Card(
              elevation: 0,
              color: const Color(0xFFFAF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEFEAE3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: Color(0xFFFF7A00),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF252525),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _openAddressDialog(context),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFFFF7A00),
                          ),
                          label: Text(
                            hasMissingInfo ? 'Add' : 'Change',
                            style: const TextStyle(
                              color: Color(0xFFFF7A00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Deliver to
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deliver to',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF252525),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Delivery Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                _address.isNotEmpty
                                    ? _address
                                    : 'No delivery address provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _address.isNotEmpty
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _address.isNotEmpty
                                      ? const Color(0xFF252525)
                                      : Colors.red.shade400,
                                  fontStyle: _address.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                _phone.isNotEmpty
                                    ? _phone
                                    : 'No phone number provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _phone.isNotEmpty
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _phone.isNotEmpty
                                      ? const Color(0xFF252525)
                                      : Colors.red.shade400,
                                  fontStyle: _phone.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_saveAsDefault) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Will be saved as your default profile address',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order summary
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEFEAE3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...value.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.meal.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Rs ${(item.meal.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${value.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Final Order Confirmation Card (Requirement 9)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFEAE3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Confirmation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deliver to: $customerName',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  Text(
                    'Address: ${_address.isNotEmpty ? _address : "(Please add address)"}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  Text(
                    'Phone: ${_phone.isNotEmpty ? _phone : "(Please add phone)"}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: (_loading || hasMissingInfo) ? null : _placeOrder,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      hasMissingInfo
                          ? 'Add Address & Phone to Order'
                          : 'Place Order',
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
