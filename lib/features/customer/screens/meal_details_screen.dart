import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/cart_provider.dart';
import '../providers/meal_provider.dart';

class MealDetailsScreen extends ConsumerWidget {
  const MealDetailsScreen({super.key, required this.mealId});
  final String mealId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Meal details')),
    body: FutureBuilder(
      future: ref.watch(mealProvider.notifier).fetchMeal(mealId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final meal = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.45,
                child: meal.imageUrl == null
                    ? Container(
                        color: const Color(0xFFFFE8D2),
                        child: const Icon(Icons.restaurant, size: 64),
                      )
                    : Image.network(meal.imageUrl!, fit: BoxFit.cover),
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
        );
      },
    ),
  );
}
