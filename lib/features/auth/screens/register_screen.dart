import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../customer/providers/customer_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(customerProvider.notifier)
        .register(_name.text, _email.text, _password.text);
    if (success && mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: _email.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) => value == null || value.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            const SizedBox(height: 18),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: state.isLoading ? null : _register,
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
