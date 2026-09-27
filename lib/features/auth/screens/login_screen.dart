import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TABLE &\nHEARTH',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 36, height: .95),
              ),
              const SizedBox(height: 14),
              Text(
                'Homemade food, made closer.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 58),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Sign in to discover tonight’s best local plates.'),
              const SizedBox(height: 28),
              const CustomTextField(label: 'Email address'),
              const SizedBox(height: 14),
              const CustomTextField(label: 'Password', obscureText: true),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Sign in',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('New here? Create an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
