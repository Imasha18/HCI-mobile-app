import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController(text: 'Colombo 03, Sri Lanka');
  bool _loading = false;
  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_loading) return;
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.items.isEmpty || _address.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      final order = await ref
          .read(orderProvider.notifier)
          .createOrder(cart, _address.text.trim());
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.payment,
          arguments: {'orderId': order.id, 'amount': order.total},
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        data: (value) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Delivery address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
                labelText: 'Address',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...value.items.map(
              (item) => ListTile(
                title: Text(item.meal.name),
                subtitle: Text('Qty ${item.quantity}'),
                trailing: Text(
                  'Rs ${(item.meal.price * item.quantity).toStringAsFixed(2)}',
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Total'),
              trailing: Text(
                'Rs ${value.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _placeOrder,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Place Order'),
            ),
          ],
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
