import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/cook_provider.dart';
import '../theme/cook_theme.dart';

class CookRegisterScreen extends ConsumerStatefulWidget {
  const CookRegisterScreen({super.key});

  @override
  ConsumerState<CookRegisterScreen> createState() => _CookRegisterScreenState();
}

class _CookRegisterScreenState extends ConsumerState<CookRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _kitchenController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _kitchenController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(cookProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          kitchenName: _kitchenController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kitchen registered successfully! Welcome to HomeBite.'),
          backgroundColor: CookTheme.statusGreen,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.cookDashboard);
    } else {
      final error = ref.read(cookProvider).error ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: CookTheme.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);

    return Scaffold(
      backgroundColor: CookTheme.background,
      appBar: AppBar(
        backgroundColor: CookTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CookTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join as Home Cook',
          style: TextStyle(color: CookTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CookTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 38,
                        color: CookTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Register Your Kitchen',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CookTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Sell homemade dishes to food lovers in your neighbourhood.',
                    style: TextStyle(fontSize: 13, color: CookTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields
                _buildFieldLabel('Full Name / Chef Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('e.g. Sunethra Silva', Icons.person_outline),
                  validator: (val) => val == null || val.trim().length < 2 ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Kitchen Name'),
                TextFormField(
                  controller: _kitchenController,
                  decoration: _inputDecoration('e.g. Amma\'s Spice Kitchen', Icons.storefront_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter your kitchen name' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('e.g. sunethra@homebite.com', Icons.email_outlined),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+94 77 234 5678', Icons.phone_outlined),
                  validator: (val) => val == null || val.trim().length < 9 ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Kitchen Address'),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('e.g. 45/2 Galle Road, Colombo 03', Icons.location_on_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter kitchen address for deliveries' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Security Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: CookTheme.primaryOrange),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: CookTheme.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: CookTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CookTheme.primaryOrange, width: 2)),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CookTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Create Kitchen Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have a cook account? ', style: TextStyle(color: CookTheme.textMuted, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.cookLogin),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(color: CookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: CookTheme.textDark),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: CookTheme.primaryOrange),
      filled: true,
      fillColor: CookTheme.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CookTheme.primaryOrange, width: 2)),
    );
  }
}
