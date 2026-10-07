import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/cart_provider.dart';
import '../providers/meal_provider.dart';

class MealDetailsScreen extends ConsumerWidget {
  const MealDetailsScreen({super.key, required this.mealId});
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealAsync = ref.watch(singleMealFamilyProvider(mealId));

    return Scaffold(
      appBar: AppBar(title: const Text('Meal details')),
      body: mealAsync.when(
        data: (meal) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.45,
                child: AppCachedImage(
                  imageUrl: meal.imageUrl,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.restaurant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(meal.name, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Rs ${meal.price.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: const Color(0xFFFF7A00)),
            ),
            const SizedBox(height: 12),
            Text(meal.description ?? 'Made fresh by a local HomeBite cook.'),
            const SizedBox(height: 18),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(meal.cookName ?? 'Home cook'),
              subtitle: Text('${meal.rating ?? 4.8} rating'),
              onTap: meal.cookId == null
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        AppRoutes.cookProfile,
                        arguments: meal.cookId,
                      ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await ref.read(cartProvider.notifier).add(meal);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                }
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AspectRatio(
              aspectRatio: 1.45,
              child: ShimmerBox(width: double.infinity, borderRadius: 24),
            ),
            SizedBox(height: 20),
            ShimmerBox(width: 220, height: 28, borderRadius: 8),
            SizedBox(height: 10),
            ShimmerBox(width: 110, height: 22, borderRadius: 6),
            SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 16, borderRadius: 6),
            SizedBox(height: 8),
            ShimmerBox(width: 250, height: 16, borderRadius: 6),
            SizedBox(height: 24),
            Row(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 22),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 130, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 12, borderRadius: 6),
                  ],
                ),
              ],
            ),
            SizedBox(height: 28),
            ShimmerBox(width: double.infinity, height: 48, borderRadius: 12),
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
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(singleMealFamilyProvider(mealId)),
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
