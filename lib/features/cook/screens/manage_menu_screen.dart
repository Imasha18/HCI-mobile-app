import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/meal_management_provider.dart';
import '../theme/cook_theme.dart';

class ManageMenuScreen extends ConsumerStatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  ConsumerState<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends ConsumerState<ManageMenuScreen> {
  final List<String> _categories = ['All', 'Rice', 'Curry', 'Kottu', 'Healthy'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mealManagementProvider.notifier).fetchMeals();
    });
  }

  void _confirmDelete(BuildContext context, String mealId, String mealName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to remove "$mealName" from your menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CookTheme.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CookTheme.statusRed),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await ref.read(mealManagementProvider.notifier).deleteMeal(mealId);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Meal deleted successfully' : 'Failed to delete meal'),
                  backgroundColor: success ? CookTheme.statusGreen : CookTheme.statusRed,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealManagementProvider);
    final selectedCategory = state.selectedCategory;

    final filteredMeals = state.meals.where((meal) {
      if (selectedCategory == 'All') return true;
      return (meal['category'] as String?)?.toLowerCase() == selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Manage Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CookTheme.textDark,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: CookTheme.primaryOrange, size: 28),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addMeal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: CookTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(mealManagementProvider.notifier).fetchMeals();
        },
        child: Column(
          children: [
            // Category Filter Chips
            Container(
              height: 56,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(mealManagementProvider.notifier).filterCategory(cat);
                    },
                    selectedColor: CookTheme.primaryOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : CookTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: CookTheme.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? CookTheme.primaryOrange : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            // Meals List
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) => const OrderCardSkeleton(),
                    )
                  : filteredMeals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No meals found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CookTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add delicious dishes to your kitchen menu.',
                                style: TextStyle(color: CookTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CookTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.addMeal),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Your First Meal'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          key: const PageStorageKey<String>('cook_manage_menu_scroll'),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          itemCount: filteredMeals.length,
                          itemBuilder: (context, index) {
                            final meal = filteredMeals[index] as Map<String, dynamic>;
                            final mealId = meal['_id'] as String? ?? '';
                            final name = meal['name'] as String? ?? 'Delicious Meal';
                            final price = (meal['price'] as num?)?.toDouble() ?? 0.0;
                            final category = meal['category'] as String? ?? 'General';
                            final imageUrl = meal['imageUrl'] as String? ?? meal['image'] as String? ?? '';
                            final isAvailable = meal['available'] as bool? ?? true;
                            final cookingTime = meal['prepTimeMinutes'] ?? meal['cookingTime'] ?? 20;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: CookTheme.softShadow,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Meal Image
                                        AppCachedImage(
                                          imageUrl: imageUrl,
                                          width: 84,
                                          height: 84,
                                          borderRadius: 14,
                                          fallbackIcon: Icons.fastfood_rounded,
                                        ),
                                        const SizedBox(width: 14),

                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: CookTheme.textDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${AppConstants.currency}${price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: CookTheme.primaryDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: CookTheme.secondaryOrange,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      category,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: CookTheme.primaryDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$cookingTime min',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Availability row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    isAvailable ? 'In Stock / Active' : 'Sold Out / Disabled',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isAvailable ? CookTheme.statusGreen : CookTheme.textMuted,
                                                    ),
                                                  ),
                                                  Transform.scale(
                                                    scale: 0.8,
                                                    child: Switch(
                                                      value: isAvailable,
                                                      activeThumbColor: CookTheme.primaryOrange,
                                                      activeTrackColor: CookTheme.secondaryOrange,
                                                      onChanged: (val) {
                                                        ref
                                                            .read(mealManagementProvider.notifier)
                                                            .toggleAvailability(mealId, val);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Divider & Action buttons (Edit & Delete)
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.editMeal,
                                              arguments: meal,
                                            );
                                          },
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: CookTheme.primaryDark),
                                          label: const Text(
                                            'Edit Details',
                                            style: TextStyle(
                                              color: CookTheme.primaryDark,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(height: 24, width: 1, color: const Color(0xFFF0F0F0)),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () => _confirmDelete(context, mealId, name),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: CookTheme.statusRed),
                                          label: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: CookTheme.statusRed,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CookTheme.primaryOrange,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addMeal),
        icon: const Icon(Icons.add),
        label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
