import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const CustomTextField(label: 'Full name'),
          const SizedBox(height: 14),
          const CustomTextField(label: 'Email address'),
          const SizedBox(height: 14),
          const CustomTextField(label: 'Password', obscureText: true),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Continue',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
