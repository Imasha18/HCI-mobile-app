import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _phone = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _postalCode.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid phone number.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    final sriLankanRegex = RegExp(r'^(?:(?:\+94|0094|94|0)?[1-9]\d{8})$');
    if (!sriLankanRegex.hasMatch(cleaned)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) return;

    // Combine structured address fields cleanly without extra commas
    final fullAddress = [
      _addressLine1.text,
      _addressLine2.text,
      _city.text,
      _postalCode.text,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    final success = await ref.read(customerProvider.notifier).register(
          _name.text,
          _email.text,
          _password.text,
          phone: _phone.text.trim(),
          address: fullAddress,
        );

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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // 1. Full Name
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter your full name.'
                    : null,
              ),
              const SizedBox(height: 16),

              // 2. Email Address
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Phone Number
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+94 7X XXX XXXX',
                  helperText: 'We’ll use this for delivery updates.',
                  helperMaxLines: 1,
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 24),

              // Delivery Address Section Header
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF252525),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This address will be saved as your default delivery address.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Address Line 1
              TextFormField(
                controller: _addressLine1,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1',
                  hintText: 'No. 25, Main Street',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Enter your street address.'
                    : null,
              ),
              const SizedBox(height: 16),

              // 5. Address Line 2 (Optional)
              TextFormField(
                controller: _addressLine2,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2 (Optional)',
                  hintText: 'Apartment, building, landmark',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 6 & 7: City / Town and Postal Code in clean, responsive layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City / Town
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'City / Town',
                        hintText: 'Nugegoda',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                              ? 'Enter your city or town.'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Postal Code (Optional)
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _postalCode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Postal Code (Optional)',
                        hintText: '10250',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 8. Password
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Password must be at least 6 characters.'
                    : null,
              ),
              const SizedBox(height: 16),

              // 9. Confirm Password
              TextFormField(
                controller: _confirmPassword,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _password.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
