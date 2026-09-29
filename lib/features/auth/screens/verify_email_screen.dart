import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../customer/providers/customer_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            'Check your Gmail inbox',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('Enter the verification code sent to ${widget.email}.'),
          const SizedBox(height: 28),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Verification code'),
          ),
          const SizedBox(height: 20),
          if (state.error != null)
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    final verified = await ref
                        .read(customerProvider.notifier)
                        .verifyEmail(widget.email, _code.text);
                    if (verified && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (_) => false,
                      );
                    }
                  },
            child: state.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify email'),
          ),
        ],
      ),
    );
  }
}
