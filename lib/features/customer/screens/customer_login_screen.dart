import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../../../models/user_model.dart';
import '../../../services/google_auth_service.dart';
import '../../admin/providers/admin_provider.dart';
import '../../admin/services/admin_session_manager.dart';
import '../providers/customer_provider.dart';

class CustomerLoginScreen extends ConsumerStatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  ConsumerState<CustomerLoginScreen> createState() =>
      _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends ConsumerState<CustomerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await ref
        .read(customerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (user != null && mounted) {
      await _navigateForRole(user);
    }
  }

  /// Routes using the role returned by the backend, never a client guess.
  Future<void> _navigateForRole(UserModel user) async {
    if (user.role == 'admin') {
      ref.read(adminProvider.notifier).setAdminUser(user.toJson());
      await AdminSessionManager().startSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      }
    } else if (user.role == 'cook') {
      Navigator.pushReplacementNamed(context, AppRoutes.cookDashboard);
    } else if (user.role == 'rider') {
      Navigator.pushReplacementNamed(context, AppRoutes.riderDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  Future<void> _googleLogin() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      // Called directly from the tap handler so browsers allow the popup.
      final credential = await GoogleAuthService.instance.signIn();
      if (credential == null) return; // user cancelled: no error shown

      final user =
          await ref.read(customerProvider.notifier).googleLogin(credential);
      if (user != null && mounted) {
        await _navigateForRole(user);
      }
    } on GoogleAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your next homemade favorite is waiting.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email or phone',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your email or phone'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: state.isLoading || _googleLoading ? null : _login,
                child: state.isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    state.isLoading || _googleLoading ? null : _googleLogin,
                icon: _googleLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: Text(
                  _googleLoading ? 'Signing in…' : 'Continue with Google',
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
                child: const Text('New to HomeBite? Create an account'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.roleSelection),
                  icon: const Icon(Icons.people_outline_rounded, size: 18),
                  label: const Text('How will you join us? Select Role'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.cookLogin),
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: const Text('Are you a Home Cook? Cook Portal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
