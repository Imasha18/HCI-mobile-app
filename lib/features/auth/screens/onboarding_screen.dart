import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 176,
                  height: 176,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.restaurant_rounded,
                      size: 88,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Good food, made\nright at home',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Color(0xFF252525),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discover homemade meals from local cooks, '
                'or join our community and share your own.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 36),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageIndicator(isSelected: true),
                  SizedBox(width: 8),
                  _PageIndicator(isSelected: false),
                  SizedBox(width: 8),
                  _PageIndicator(isSelected: false),
                ],
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.roleSelection,
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFF7A00)
            : const Color(0xFFFFCC80),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}