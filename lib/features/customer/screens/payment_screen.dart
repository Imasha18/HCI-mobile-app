import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId, required this.amount});
  final String orderId;
  final double amount;
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_loading) return;
    if (_number.text.trim().length < 12 ||
        _expiry.text.trim().isEmpty ||
        _cvv.text.trim().length < 3) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(paymentProvider).pay(widget.orderId);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.confirmation,
          arguments: widget.orderId,
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Card payment', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Card number',
            prefixIcon: Icon(Icons.credit_card),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                decoration: const InputDecoration(labelText: 'Expiry'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvv,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'CVV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Amount: Rs ${widget.amount.toStringAsFixed(2)}'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _pay,
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Pay now'),
        ),
      ],
    ),
  );
}
