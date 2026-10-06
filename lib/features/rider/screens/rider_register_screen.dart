import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../providers/rider_provider.dart';
import '../theme/rider_theme.dart';

class RiderRegisterScreen extends ConsumerStatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  ConsumerState<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends ConsumerState<RiderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  String _vehicleType = 'Motorbike';
  bool _obscurePassword = true;

  final List<String> _vehicleOptions = [
    'Motorbike',
    'Scooter',
    'Bicycle',
    'Electric Bike',
    'Car',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleModelController.dispose();
    _plateNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(riderProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          vehicleType: _vehicleType,
          vehicleModel: _vehicleModelController.text.trim(),
          vehiclePlateNumber: _plateNumberController.text.trim(),
        );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email address.'),
          backgroundColor: RiderTheme.primaryGreen,
        ),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: {
          'email': _emailController.text.trim().toLowerCase(),
          'role': 'rider',
        },
      );
    } else {
      final error = result['error'] ?? ref.read(riderProvider).error ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: RiderTheme.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderProvider);

    return Scaffold(
      backgroundColor: RiderTheme.background,
      appBar: AppBar(
        backgroundColor: RiderTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RiderTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join as Delivery Rider',
          style: TextStyle(color: RiderTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
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
                      boxShadow: RiderTheme.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.two_wheeler_rounded,
                        size: 38,
                        color: RiderTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Become a Delivery Partner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RiderTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Earn competitive income delivering fresh home-cooked meals.',
                    style: TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields
                _buildFieldLabel('Full Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('e.g. Kasun Bandara', Icons.person_outline),
                  validator: (val) => val == null || val.trim().length < 2 ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('e.g. kasun@homebite.com', Icons.email_outlined),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+94 77 123 4567', Icons.phone_outlined),
                  validator: (val) => val == null || val.trim().length < 9 ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Operating City / Address'),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('e.g. Colombo, Sri Lanka', Icons.location_on_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter your delivery zone' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Vehicle Type'),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  decoration: _inputDecoration('Select vehicle type', Icons.two_wheeler_outlined),
                  items: _vehicleOptions.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _vehicleType = val);
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Vehicle Model'),
                          TextFormField(
                            controller: _vehicleModelController,
                            decoration: _inputDecoration('e.g. Honda Dio', Icons.directions_bike_outlined),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter vehicle model' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Plate Number'),
                          TextFormField(
                            controller: _plateNumberController,
                            decoration: _inputDecoration('e.g. WP BZ-4892', Icons.confirmation_number_outlined),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter plate number' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Security Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: RiderTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: RiderTheme.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: RiderTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: RiderTheme.primaryGreen, width: 2)),
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
                      backgroundColor: RiderTheme.primaryGreen,
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
                            'Create Rider Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have a rider account? ',
                        style: TextStyle(color: RiderTheme.textMuted, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: RiderTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: RiderTheme.textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: RiderTheme.primaryGreen),
      filled: true,
      fillColor: RiderTheme.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: RiderTheme.primaryGreen, width: 2)),
    );
  }
}
