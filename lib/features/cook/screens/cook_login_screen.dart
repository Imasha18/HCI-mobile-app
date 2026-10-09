import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../config/api_config.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(cookProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(cookProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.cookDashboard);
    } else {
      final error = ref.read(cookProvider).error;
      if (error != null && error.toLowerCase().contains('verify')) {
        final email = _emailController.text.trim().toLowerCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: CookTheme.statusRed,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Verify Now',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.verifyEmail,
                  arguments: {'email': email, 'role': 'cook'},
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(serverClientId: ApiConfig.googleClientId);
      final account = await googleSignIn.signIn();
      final idToken = (await account?.authentication)?.idToken;
      if (idToken == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final result = await ref.read(cookProvider.notifier).googleAuth(idToken: idToken);
      if (!mounted) return;

      if (result == null) {
        final err = ref.read(cookProvider).error ?? 'Google authentication failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: CookTheme.statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isGoogleLoading = false);
        return;
      }

      if (result['requiresProfileCompletion'] == true) {
        setState(() => _isGoogleLoading = false);
        final data = result['data'] as Map<String, dynamic>? ?? {};
        _showProfileCompletionSheet(idToken, data);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.cookDashboard, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in error: $e'),
            backgroundColor: CookTheme.statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showProfileCompletionSheet(String idToken, Map<String, dynamic> data) {
    final sheetFormKey = GlobalKey<FormState>();
    final sheetNameCtrl = TextEditingController(text: data['name']?.toString() ?? '');
    final sheetKitchenCtrl = TextEditingController(
      text: data['name'] != null ? '${data['name']}\'s Kitchen' : '',
    );
    final sheetPhoneCtrl = TextEditingController();
    final sheetAddressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: sheetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete Kitchen Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CookTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A few details are needed to set up your home cook account.',
                    style: TextStyle(fontSize: 13, color: CookTheme.textMuted),
                  ),
                  const SizedBox(height: 20),

                  _buildFieldLabel('Full Name / Chef Name'),
                  TextFormField(
                    controller: sheetNameCtrl,
                    decoration: _inputDecoration('e.g. Sunethra Silva', Icons.person_outline),
                    validator: (val) => val == null || val.trim().length < 2 ? 'Enter your full name.' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Kitchen Name'),
                  TextFormField(
                    controller: sheetKitchenCtrl,
                    decoration: _inputDecoration('e.g. Amma\'s Spice Kitchen', Icons.storefront_outlined),
                    validator: (val) => val == null || val.trim().length < 2 ? 'Enter your kitchen name.' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Phone Number'),
                  TextFormField(
                    controller: sheetPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('0771234567 or +94771234567', Icons.phone_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter a valid Sri Lankan phone number.';
                      final clean = val.replaceAll(RegExp(r'[\s-]'), '');
                      final phoneRegex = RegExp(r'^(?:\+94|0094|94)?(?:0)?(?:7[01245678]|11|2[1-8]|3[1-8]|4[1-7]|5[1-7]|6[3-7]|8[1-4]|9[12])[0-9]{7}$');
                      if (!phoneRegex.hasMatch(clean)) return 'Enter a valid Sri Lankan phone number.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Kitchen Address'),
                  TextFormField(
                    controller: sheetAddressCtrl,
                    decoration: _inputDecoration('e.g. 45/2 Galle Road, Colombo 03', Icons.location_on_outlined),
                    validator: (val) => val == null || val.trim().length < 5 ? 'Enter your kitchen address.' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!sheetFormKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        setState(() => _isGoogleLoading = true);

                        final completed = await ref.read(cookProvider.notifier).googleAuth(
                              idToken: idToken,
                              name: sheetNameCtrl.text.trim(),
                              kitchenName: sheetKitchenCtrl.text.trim(),
                              phone: sheetPhoneCtrl.text.trim(),
                              address: sheetAddressCtrl.text.trim(),
                            );

                        if (!mounted) return;
                        setState(() => _isGoogleLoading = false);

                        if (completed != null && completed['requiresProfileCompletion'] != true) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.cookDashboard,
                            (_) => false,
                          );
                        } else {
                          final err = ref.read(cookProvider).error ?? 'Unable to complete profile.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: CookTheme.statusRed),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CookTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Finish & Open Kitchen',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cookProvider);
    final isLoading = state.isLoading || _isGoogleLoading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                            padding: const EdgeInsets.all(10),
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
                    _buildFieldLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('e.g. chef@homebite.com', Icons.email_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter your cook email';
                        if (!val.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password input
                    _buildFieldLabel('Password'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                          val == null || val.isEmpty ? 'Enter your password' : null,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                        onPressed: isLoading ? null : _handleLogin,
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

                    const SizedBox(height: 18),

                    // Divider OR
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: CookTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Continue with Google button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: CookTheme.primaryDark),
                              )
                            : const Icon(Icons.g_mobiledata_rounded, size: 30, color: CookTheme.primaryDark),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CookTheme.textDark,
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
                              Navigator.pushNamed(context, AppRoutes.cookRegister);
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

                    // Return to role selection / customer login link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.roleSelection),
                        icon: const Icon(Icons.people_outline_rounded, size: 16, color: CookTheme.textMuted),
                        label: const Text(
                          'How will you join us? Select Role',
                          style: TextStyle(color: CookTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CookTheme.textDark),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: CookTheme.primaryOrange),
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
    );
  }
}
