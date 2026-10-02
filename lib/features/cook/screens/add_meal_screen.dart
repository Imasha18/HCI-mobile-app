import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/meal_management_provider.dart';
import '../theme/cook_theme.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cookingTimeController = TextEditingController(text: '25');
  final _ingredientsController = TextEditingController();
  final _dietaryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Rice';
  bool _availability = true;
  File? _selectedImageFile;

  final List<String> _categories = ['Rice', 'Curry', 'Kottu', 'Healthy'];
  final List<String> _presetImages = [
    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
    'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&q=80',
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80',
    'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cookingTimeController.dispose();
    _ingredientsController.dispose();
    _dietaryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitMeal() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final cookingTime = int.tryParse(_cookingTimeController.text.trim()) ?? 25;

    final ingredients = _ingredientsController.text
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.isNotEmpty)
        .toList();

    final dietary = _dietaryController.text
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.isNotEmpty)
        .toList();

    final success = await ref.read(mealManagementProvider.notifier).addMeal(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          cookingTime: cookingTime,
          ingredients: ingredients,
          dietaryInfo: dietary,
          available: _availability,
          imageFile: _selectedImageFile,
          imageUrl: _imageUrlController.text.trim().isNotEmpty
              ? _imageUrlController.text.trim()
              : _presetImages[0],
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal added to menu successfully!'),
          backgroundColor: CookTheme.statusGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealManagementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Add New Meal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CookTheme.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Image Selection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meal Image',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose a preset dish photo or enter an image link:',
                      style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
                    ),
                    const SizedBox(height: 14),

                    // Preset thumbnails
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetImages.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final isSelected = _imageUrlController.text == _presetImages[i] ||
                              (_imageUrlController.text.isEmpty && i == 0);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageUrlController.text = _presetImages[i];
                              });
                            },
                            child: Container(
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? CookTheme.primaryOrange : Colors.transparent,
                                  width: 2.5,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(_presetImages[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Or paste image URL',
                        prefixIcon: const Icon(Icons.link, color: CookTheme.primaryOrange),
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Basic Information Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meal Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 16),

                    // Meal Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Meal Name *',
                        hintText: 'e.g. Grandma’s Special Rice & Curry',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter meal name' : null,
                    ),

                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe ingredients, preparation style, and flavors...',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Selector
                    const Text(
                      'Category *',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: CookTheme.primaryOrange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : CookTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Price & Cooking Time Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Price (Rs.) *',
                              prefixText: 'Rs. ',
                              hintText: '850',
                              filled: true,
                              fillColor: CookTheme.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter price';
                              if (double.tryParse(val) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _cookingTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Prep Time (min)',
                              hintText: '25',
                              filled: true,
                              fillColor: CookTheme.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Additional Info Card (Ingredients, Dietary, Availability)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: CookTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingredients & Diet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _ingredientsController,
                      decoration: InputDecoration(
                        labelText: 'Ingredients (comma separated)',
                        hintText: 'Samba rice, Curry leaves, Coconut milk, Pandan, Cardamom',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _dietaryController,
                      decoration: InputDecoration(
                        labelText: 'Dietary Information (comma separated)',
                        hintText: 'Halal, Vegetarian, Vegan, Spicy, Gluten-Free',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Available Immediately',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Customers can start ordering right away',
                        style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
                      ),
                      value: _availability,
                      activeThumbColor: CookTheme.primaryOrange,
                      activeTrackColor: CookTheme.secondaryOrange,
                      onChanged: (val) => setState(() => _availability = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submitMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CookTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Meal to Menu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
extension _IterableFilter<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
