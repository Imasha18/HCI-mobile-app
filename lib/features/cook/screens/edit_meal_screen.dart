import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/meal_management_provider.dart';
import '../theme/cook_theme.dart';

class EditMealScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> meal;

  const EditMealScreen({super.key, required this.meal});

  @override
  ConsumerState<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends ConsumerState<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _cookingTimeController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _dietaryController;
  late final TextEditingController _imageUrlController;

  late String _selectedCategory;
  late bool _availability;

  final List<String> _categories = ['Rice', 'Curry', 'Kottu', 'Healthy'];

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    _nameController = TextEditingController(text: m['name'] as String? ?? '');
    _descriptionController = TextEditingController(text: m['description'] as String? ?? '');
    _priceController = TextEditingController(text: (m['price'] ?? '').toString());
    _cookingTimeController = TextEditingController(
        text: (m['prepTimeMinutes'] ?? m['cookingTime'] ?? '25').toString());

    final ingredientsList = (m['ingredients'] as List<dynamic>?) ?? [];
    _ingredientsController = TextEditingController(text: ingredientsList.join(', '));

    final dietaryList = (m['dietaryInformation'] as List<dynamic>?) ?? [];
    _dietaryController = TextEditingController(text: dietaryList.join(', '));

    _imageUrlController = TextEditingController(
        text: (m['imageUrl'] as String?) ?? (m['image'] as String?) ?? '');

    _selectedCategory = (m['category'] as String?) ?? 'Rice';
    _availability = (m['available'] as bool?) ?? true;
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final cookingTime = int.tryParse(_cookingTimeController.text.trim()) ?? 25;
    final mealId = widget.meal['_id'] as String;

    final ingredients = _ingredientsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final dietary = _dietaryController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final success = await ref.read(mealManagementProvider.notifier).editMeal(
          id: mealId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          cookingTime: cookingTime,
          ingredients: ingredients,
          dietaryInfo: dietary,
          available: _availability,
          imageUrl: _imageUrlController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal updated successfully!'),
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
          'Edit Meal',
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
              // Image Preview & URL Card
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
                      'Dish Image',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (_imageUrlController.text.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _imageUrlController.text,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              color: CookTheme.secondaryOrange,
                              child: const Icon(Icons.fastfood, color: CookTheme.primaryOrange, size: 40),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Image URL',
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

              // Form fields Card
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
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Meal Name *',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter meal name' : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Category',
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

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Price (\$) *',
                              filled: true,
                              fillColor: CookTheme.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter price' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _cookingTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cooking Time (min)',
                              filled: true,
                              fillColor: CookTheme.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _ingredientsController,
                      decoration: InputDecoration(
                        labelText: 'Ingredients (comma separated)',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _dietaryController,
                      decoration: InputDecoration(
                        labelText: 'Dietary Info (comma separated)',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        _availability ? 'Visible to customers' : 'Hidden from customers',
                        style: const TextStyle(fontSize: 12, color: CookTheme.textMuted),
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

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CookTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
