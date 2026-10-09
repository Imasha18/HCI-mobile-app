import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cook_provider.dart';
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
  final _scrollController = ScrollController();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _cookingTimeController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _dietaryController;
  late final TextEditingController _imageUrlController;

  late String _selectedCategory;
  late String _selectedSpiceLevel;
  late bool _availability;

  final List<String> _categories = ['Rice', 'Curry', 'Kottu', 'Healthy', 'Short Eats', 'Dessert'];
  final List<String> _spiceLevels = ['mild', 'medium', 'spicy'];
  final List<String> _presetImages = [
    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
    'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&q=80',
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80',
    'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    _nameController = TextEditingController(text: m['name'] as String? ?? '');
    _descriptionController = TextEditingController(text: m['description'] as String? ?? '');
    _priceController = TextEditingController(text: (m['price'] ?? '').toString());
    _cookingTimeController = TextEditingController(
        text: (m['prepTimeMinutes'] ?? m['cookingTime'] ?? '25').toString());
    _cuisineController = TextEditingController(text: (m['cuisine'] as String?) ?? 'Sri Lankan');

    final ingredientsList = (m['ingredients'] as List<dynamic>?) ?? [];
    _ingredientsController = TextEditingController(text: ingredientsList.join(', '));

    final dietaryList = (m['dietaryInformation'] as List<dynamic>?) ??
        (m['dietaryTags'] as List<dynamic>?) ??
        [];
    _dietaryController = TextEditingController(text: dietaryList.join(', '));

    _imageUrlController = TextEditingController(
        text: (m['imageUrl'] as String?) ?? (m['image'] as String?) ?? '');

    _selectedCategory = (m['category'] as String?) ?? 'Rice';
    _selectedSpiceLevel = (m['spiceLevel'] as String?) ?? 'medium';
    _availability = (m['available'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cookingTimeController.dispose();
    _cuisineController.dispose();
    _ingredientsController.dispose();
    _dietaryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in required fields (Meal Name, Price).'),
          backgroundColor: CookTheme.statusRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final cookingTime = int.tryParse(_cookingTimeController.text.trim()) ?? 25;
    final mealId = (widget.meal['_id'] ?? widget.meal['id'])?.toString() ?? '';

    if (mealId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Meal ID missing. Cannot update meal.'),
          backgroundColor: CookTheme.statusRed,
        ),
      );
      return;
    }

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
          cuisine: _cuisineController.text.trim().isNotEmpty
              ? _cuisineController.text.trim()
              : 'Sri Lankan',
          spiceLevel: _selectedSpiceLevel,
          cookingTime: cookingTime,
          ingredients: ingredients,
          dietaryInfo: dietary,
          available: _availability,
          imageUrl: _imageUrlController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      await ref.read(cookProvider.notifier).fetchDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal updated successfully!'),
          backgroundColor: CookTheme.statusGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      final errorMsg = ref.read(mealManagementProvider).error ?? 'Failed to update meal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: CookTheme.statusRed,
          duration: const Duration(seconds: 4),
        ),
      );
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
        controller: _scrollController,
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
                    const Text(
                      'Select a preset dish photo or change URL:',
                      style: TextStyle(fontSize: 12, color: CookTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetImages.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final isSelected = _imageUrlController.text == _presetImages[i];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageUrlController.text = _presetImages[i];
                              });
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
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

                    // Cuisine
                    TextFormField(
                      controller: _cuisineController,
                      decoration: InputDecoration(
                        labelText: 'Cuisine',
                        hintText: 'e.g. Sri Lankan, Indian, Fusion',
                        filled: true,
                        fillColor: CookTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Spice Level
                    const Text(
                      'Spice Level',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: CookTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _spiceLevels.map((lvl) {
                        final isSelected = _selectedSpiceLevel == lvl;
                        return ChoiceChip(
                          label: Text(lvl.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedSpiceLevel = lvl),
                          selectedColor: CookTheme.primaryOrange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : CookTheme.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                              labelText: 'Price (Rs.) *',
                              prefixText: 'Rs. ',
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
