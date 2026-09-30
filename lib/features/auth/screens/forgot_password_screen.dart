import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../customer/providers/customer_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            'Reset your password',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('We will send a reset code to your Gmail address.'),
          const SizedBox(height: 28),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 20),
          if (state.error != null)
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    final sent = await ref
                        .read(customerProvider.notifier)
                        .requestPasswordReset(_email.text);
                    if (sent && context.mounted) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.resetPassword,
                        arguments: {'email': _email.text.trim()},
                      );
                    }
                  },
            child: state.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send reset code'),
          ),
        ],
      ),
    );
  }
}
