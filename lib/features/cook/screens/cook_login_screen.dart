import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/cook_provider.dart';
import '../theme/cook_theme.dart';

class CookLoginScreen extends ConsumerStatefulWidget {
  const CookLoginScreen({super.key});

  @override
  ConsumerState<CookLoginScreen> createState() => _CookLoginScreenState();
}

class _CookLoginScreenState extends ConsumerState<CookLoginScreen> {
  final _emailController = TextEditingController(text: 'cook@homebite.com');
  final _passwordController = TextEditingController(text: 'cook123');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(cookProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.cookDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);

    return Scaffold(
      backgroundColor: CookTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Logo & Cook Portal Badge
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: CookTheme.softShadow,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            AppAssets.logo,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 48,
                              color: CookTheme.primaryOrange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CookTheme.secondaryOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'HOME COOK PORTAL',
                            style: TextStyle(
                              color: CookTheme.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Header title
                  const Text(
                    'Cook Login',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: CookTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your Sri Lankan kitchen, track live orders, and review daily earnings in Rs. (LKR) in real time.',
                    style: TextStyle(
                      fontSize: 15,
                      color: CookTheme.textMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error notification if present
                  if (state.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: CookTheme.statusRedBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CookTheme.statusRed.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: CookTheme.statusRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: const TextStyle(
                                color: CookTheme.statusRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Email input
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: CookTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'e.g. chef@homebite.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: CookTheme.primaryOrange),
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: CookTheme.primaryOrange, width: 2),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter your cook email' : null,
                  ),

                  const SizedBox(height: 20),

                  // Password input
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: CookTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline, color: CookTheme.primaryOrange),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: CookTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: CookTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: CookTheme.primaryOrange, width: 2),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.length < 5 ? 'Password must be at least 5 characters' : null,
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset instructions sent to cook email.'),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: CookTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CookTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login to Kitchen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Create Account link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Want to become a Home Cook? ',
                          style: TextStyle(color: CookTheme.textMuted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New cook registrations are automatically approved with demo account.'),
                              ),
                            );
                          },
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                              color: CookTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Return to customer login link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16, color: CookTheme.textMuted),
                      label: const Text(
                        'Switch to Customer App',
                        style: TextStyle(color: CookTheme.textMuted, fontSize: 13),
                      ),
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
}
