import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/cook_profile_provider.dart';

class CookProfileScreen extends ConsumerWidget {
  const CookProfileScreen({super.key, required this.cookId});
  final String cookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(cookProfileFamilyProvider(cookId));

    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen & Supplier Profile')),
      body: profileAsync.when(
        data: (data) {
          final cook = data['cook'] as Map<String, dynamic>? ?? {};
          final meals = (data['meals'] as List<dynamic>?) ?? [];

          final kitchenName = (cook['kitchenName'] as String?)?.isNotEmpty == true
              ? cook['kitchenName'] as String
              : '${cook['name'] ?? 'Home'}\'s Kitchen';
          final cookName = cook['name'] as String? ?? 'Home Cook';
          final address = cook['address'] as String? ?? 'Colombo, Sri Lanka';
          final rating = (cook['rating'] ?? 4.8).toString();
          final profileImage = cook['profileImage'] as String?;

          return RefreshIndicator(
            color: const Color(0xFFFF9800),
            onRefresh: () async {
              ref.invalidate(cookProfileFamilyProvider(cookId));
            },
            child: ListView(
              key: PageStorageKey<String>('cook_profile_$cookId'),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: AppCachedImage(
                    imageUrl: profileImage,
                    width: 92,
                    height: 92,
                    borderRadius: 46,
                    fallbackIcon: Icons.person,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    kitchenName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Home Cook: $cookName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Homemade Meals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${meals.length} items',
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (meals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('This kitchen has no active meals right now.'),
                    ),
                  )
                else
                  ...meals.map((meal) {
                    final mealMap = meal as Map<String, dynamic>;
                    final mealId =
                        (mealMap['id'] ?? mealMap['_id'] ?? '').toString();
                    final name = mealMap['name'] as String? ?? 'Meal';
                    final price = (mealMap['price'] ?? 0).toString();
                    final category = mealMap['category'] as String? ?? 'General';
                    final cookingTime = mealMap['cookingTime'] != null
                        ? '${mealMap['cookingTime']} mins'
                        : null;
                    final imageUrl =
                        mealMap['imageUrl'] ?? mealMap['image'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: AppCachedImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          borderRadius: 10,
                          fallbackIcon: Icons.restaurant,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$category${cookingTime != null ? '  ·  $cookingTime' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          'Rs. $price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          if (mealId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.mealDetails,
                              arguments: mealId,
                            );
                          }
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const Center(
              child: ShimmerBox(width: 92, height: 92, borderRadius: 46),
            ),
            const SizedBox(height: 14),
            const Center(
              child: ShimmerBox(width: 180, height: 24, borderRadius: 8),
            ),
            const SizedBox(height: 8),
            const Center(
              child: ShimmerBox(width: 120, height: 16, borderRadius: 6),
            ),
            const SizedBox(height: 10),
            const Center(
              child: ShimmerBox(width: 200, height: 16, borderRadius: 6),
            ),
            const SizedBox(height: 28),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 160, height: 20, borderRadius: 6),
                ShimmerBox(width: 50, height: 16, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(3, (_) => const MealTileSkeleton()),
          ],
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text('Unable to load supplier details'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(cookProfileFamilyProvider(cookId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
