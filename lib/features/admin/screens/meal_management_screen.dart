import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_management_provider.dart';
import '../theme/admin_theme.dart';

class MealManagementScreen extends ConsumerStatefulWidget {
  const MealManagementScreen({super.key});

  @override
  ConsumerState<MealManagementScreen> createState() => _MealManagementScreenState();
}

class _MealManagementScreenState extends ConsumerState<MealManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderManagementProvider.notifier).loadMeals());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderManagementProvider);
    final meals = state.meals.where((m) {
      final name = (m['name'] as String? ?? '').toLowerCase();
      final cat = (m['category'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || cat.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meal Moderation',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(orderManagementProvider.notifier).loadMeals(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search meals by name or category...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AdminTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
              ),
            ),
          ),
          Expanded(
            child: meals.isEmpty
                ? const Center(
                    child: Text('No meals found in system', style: TextStyle(color: AdminTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: meals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      final id = meal['_id'] as String? ?? meal['id'] as String? ?? '';
                      final isAvailable = meal['available'] as bool? ?? true;
                      final cook = meal['cook'] as Map? ?? {};
                      final price = meal['price'] ?? 0;
                      final imageUrl = meal['imageUrl'] as String? ?? meal['image'] as String? ?? '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AdminTheme.cardDecoration(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 75,
                                height: 75,
                                color: AdminTheme.surface,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, color: AdminTheme.primary, size: 30),
                                      )
                                    : const Icon(Icons.fastfood, color: AdminTheme.primary, size: 30),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal['name'] ?? 'Meal',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cook: ${cook['kitchenName'] ?? cook['name'] ?? 'Home Kitchen'}',
                                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AdminTheme.primaryLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          meal['category'] ?? 'General',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LKR $price',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAvailable ? 'Status: Active on menu' : 'Status: Disabled',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isAvailable ? AdminTheme.statusApproved : AdminTheme.statusRejected,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AdminTheme.statusRejected, size: 22),
                              tooltip: 'Remove Meal',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Meal'),
                                    content: Text('Remove "${meal['name']}" from marketplace?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.statusRejected),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(orderManagementProvider.notifier).deleteMeal(id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
