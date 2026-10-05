import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_preferences_model.dart';
import '../providers/recommendation_provider.dart';

class FoodPreferencesScreen extends ConsumerStatefulWidget {
  const FoodPreferencesScreen({super.key});

  @override
  ConsumerState<FoodPreferencesScreen> createState() =>
      _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends ConsumerState<FoodPreferencesScreen> {
  late String _dietaryPreference;
  late List<String> _favouriteCuisines;
  late String _budgetPreference;
  late String _spicePreference;

  final List<Map<String, String>> _dietaryOptions = const [
    {'value': 'vegetarian', 'label': 'Vegetarian', 'icon': '🥗'},
    {'value': 'vegan', 'label': 'Vegan', 'icon': '🌱'},
    {'value': 'non_vegetarian', 'label': 'Non-Vegetarian', 'icon': '🍗'},
    {'value': 'pescatarian', 'label': 'Pescatarian', 'icon': '🐟'},
    {'value': 'no_preference', 'label': 'No Preference', 'icon': '🍽️'},
  ];

  final List<Map<String, String>> _cuisineOptions = const [
    {'value': 'sri_lankan', 'label': 'Sri Lankan', 'icon': '🍛'},
    {'value': 'indian', 'label': 'Indian', 'icon': '🫓'},
    {'value': 'chinese', 'label': 'Chinese', 'icon': '🥢'},
    {'value': 'western', 'label': 'Western', 'icon': '🍔'},
    {'value': 'italian', 'label': 'Italian', 'icon': '🍝'},
    {'value': 'thai', 'label': 'Thai', 'icon': '🍲'},
    {'value': 'other', 'label': 'Other Cuisines', 'icon': '🍲'},
  ];

  final List<Map<String, String>> _budgetOptions = const [
    {'value': 'under_500', 'label': 'Under Rs. 500'},
    {'value': '500_800', 'label': 'Rs. 500–800'},
    {'value': '800_1200', 'label': 'Rs. 800–1200'},
    {'value': '1200_plus', 'label': 'Rs. 1200+'},
    {'value': 'no_preference', 'label': 'No Preference'},
  ];

  final List<Map<String, String>> _spiceOptions = const [
    {'value': 'mild', 'label': 'Mild 🫑'},
    {'value': 'medium', 'label': 'Medium 🌶️'},
    {'value': 'spicy', 'label': 'Spicy 🔥'},
    {'value': 'no_preference', 'label': 'No Preference'},
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(recommendationProvider).preferences;
    _dietaryPreference = current.dietaryPreference;
    _favouriteCuisines = List.from(current.favouriteCuisines);
    _budgetPreference = current.budgetPreference;
    _spicePreference = current.spicePreference;
  }

  void _save() async {
    final newPrefs = CustomerPreferences(
      dietaryPreference: _dietaryPreference,
      favouriteCuisines: _favouriteCuisines,
      budgetPreference: _budgetPreference,
      spicePreference: _spicePreference,
      onboardingCompleted: true,
    );

    final success =
        await ref.read(recommendationProvider.notifier).savePreferences(newPrefs);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved! Recommendations updated.'),
          backgroundColor: Color(0xFFFF7A00),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(recommendationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save preferences.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Food Preferences'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: state.isSavingPreferences ? null : _save,
              child: state.isSavingPreferences
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalized For You',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'We tailor meal suggestions based on your diet, budget, spices and favorite flavors.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: 'Dietary Preference',
            subtitle: 'Strict dietary filters will protect your choices',
            icon: Icons.eco_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietaryOptions.map((opt) {
                final isSelected = _dietaryPreference == opt['value'];
                return ChoiceChip(
                  label: Text('${opt['icon']} ${opt['label']}'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFF3E0),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFE2DED8),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFF2E2E2E),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _dietaryPreference = opt['value']!);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: 'Favourite Cuisines',
            subtitle: 'Select one or more of your preferred cuisines',
            icon: Icons.restaurant_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cuisineOptions.map((opt) {
                final isSelected = _favouriteCuisines.contains(opt['value']);
                return FilterChip(
                  label: Text('${opt['icon']} ${opt['label']}'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFF3E0),
                  backgroundColor: Colors.white,
                  checkmarkColor: const Color(0xFFFF7A00),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFE2DED8),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFF2E2E2E),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _favouriteCuisines.add(opt['value']!);
                      } else {
                        _favouriteCuisines.remove(opt['value']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: 'Budget Preference',
            subtitle: 'Preferred price range per meal',
            icon: Icons.payments_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _budgetOptions.map((opt) {
                final isSelected = _budgetPreference == opt['value'];
                return ChoiceChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFF3E0),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFE2DED8),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFF2E2E2E),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _budgetPreference = opt['value']!);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: 'Spice Preference',
            subtitle: 'How spicy do you like your food?',
            icon: Icons.local_fire_department_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _spiceOptions.map((opt) {
                final isSelected = _spicePreference == opt['value'];
                return ChoiceChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFF3E0),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFE2DED8),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFF2E2E2E),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _spicePreference = opt['value']!);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFFF7A00)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
