import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../config/api_config.dart';
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

  final _nameFocus = FocusNode();
  final _kitchenFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final Set<String> _touched = {};
  bool _submitted = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _setupFocus(_nameFocus, 'name');
    _setupFocus(_kitchenFocus, 'kitchen');
    _setupFocus(_emailFocus, 'email');
    _setupFocus(_phoneFocus, 'phone');
    _setupFocus(_addressFocus, 'address');
    _setupFocus(_passwordFocus, 'password');
  }

  void _setupFocus(FocusNode node, String fieldKey) {
    node.addListener(() {
      if (!node.hasFocus && mounted) {
        if (!_touched.contains(fieldKey)) {
          setState(() {
            _touched.add(fieldKey);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kitchenController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();

    _nameFocus.dispose();
    _kitchenFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _isFieldActive(String key) => _submitted || _touched.contains(key);

  String? _validateName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter your full name.';
    }
    if (val.trim().length < 2) {
      return 'Enter your full name.';
    }
    return null;
  }

  String? _validateKitchenName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter your kitchen name.';
    }
    if (val.trim().length < 2) {
      return 'Enter your kitchen name.';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter a valid email address.';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(val.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter a valid Sri Lankan phone number.';
    }
    final clean = val.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^(?:\+94|0094|94)?(?:0)?(?:7[01245678]|11|2[1-8]|3[1-8]|4[1-7]|5[1-7]|6[3-7]|8[1-4]|9[12])[0-9]{7}$');
    if (!phoneRegex.hasMatch(clean)) {
      return 'Enter a valid Sri Lankan phone number.';
    }
    return null;
  }

  String? _validateAddress(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Enter your kitchen address.';
    }
    if (val.trim().length < 5) {
      return 'Enter your kitchen address.';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Password must be at least 8 characters.';
    }
    if (val.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(val)) {
      return 'Password must include at least one letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(val)) {
      return 'Password must include at least one number.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final success = await ref.read(cookProvider.notifier).register(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text.trim(),
          kitchenName: _kitchenController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email.'),
          backgroundColor: CookTheme.statusGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: {
          'email': email,
          'role': 'cook',
        },
      );
    } else {
      final error = ref.read(cookProvider).error ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: CookTheme.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                    validator: _validateName,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Kitchen Name'),
                  TextFormField(
                    controller: sheetKitchenCtrl,
                    decoration: _inputDecoration('e.g. Amma\'s Spice Kitchen', Icons.storefront_outlined),
                    validator: _validateKitchenName,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Phone Number'),
                  TextFormField(
                    controller: sheetPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('0771234567 or +94771234567', Icons.phone_outlined),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Kitchen Address'),
                  TextFormField(
                    controller: sheetAddressCtrl,
                    decoration: _inputDecoration('e.g. 45/2 Galle Road, Colombo 03', Icons.location_on_outlined),
                    validator: _validateAddress,
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      padding: const EdgeInsets.all(8),
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

                  // Full Name
                  _buildFieldLabel('Full Name / Chef Name'),
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: _isFieldActive('name')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: _inputDecoration('e.g. Sunethra Silva', Icons.person_outline),
                    validator: _validateName,
                    onFieldSubmitted: (_) => _kitchenFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Kitchen Name
                  _buildFieldLabel('Kitchen Name'),
                  TextFormField(
                    controller: _kitchenController,
                    focusNode: _kitchenFocus,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: _isFieldActive('kitchen')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: _inputDecoration('e.g. Amma\'s Spice Kitchen', Icons.storefront_outlined),
                    validator: _validateKitchenName,
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildFieldLabel('Email Address'),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: _isFieldActive('email')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: _inputDecoration('e.g. chef@gmail.com', Icons.email_outlined),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildFieldLabel('Phone Number'),
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: _isFieldActive('phone')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: _inputDecoration('0771234567 or +94771234567', Icons.phone_outlined),
                    validator: _validatePhone,
                    onFieldSubmitted: (_) => _addressFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _buildFieldLabel('Kitchen Address'),
                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: _isFieldActive('address')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: _inputDecoration('e.g. 45/2 Galle Road, Colombo 03', Icons.location_on_outlined),
                    validator: _validateAddress,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildFieldLabel('Security Password'),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: _isFieldActive('password')
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration: InputDecoration(
                      hintText: 'Minimum 8 chars, 1 letter, 1 number',
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: CookTheme.statusRed, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: CookTheme.statusRed, width: 2),
                      ),
                    ),
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _handleRegister(),
                  ),

                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
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

                  const SizedBox(height: 20),

                  // Sign in link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have a cook account? ',
                          style: TextStyle(color: CookTheme.textMuted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.cookLogin),
                          child: const Text(
                            'Sign in',
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
                  const SizedBox(height: 24),
                ],
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
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: CookTheme.textDark),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CookTheme.statusRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CookTheme.statusRed, width: 2),
      ),
    );
  }
}

