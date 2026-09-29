import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../models/meal_model.dart';
import '../providers/meal_provider.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DELIVER TO',
              style: TextStyle(fontSize: 11, letterSpacing: 1.2),
            ),
            Text('Brooklyn Heights  ·  Change', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Text(
            'Good evening.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text('What are you craving today?'),
          const SizedBox(height: 22),
          TextField(
            readOnly: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            decoration: const InputDecoration(
              hintText: 'Search meals, cuisines, ingredients...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: ['Breakfast', 'Lunch', 'Dinner', 'Healthy', 'Vegetarian']
                .map(
                  (category) => ActionChip(
                    label: Text(category),
                    onPressed: () => ref
                        .read(mealProvider.notifier)
                        .fetchMeals(category: category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Popular Near You',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          meals.when(
            data: (items) => _mealList(context, items),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(mealProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Text(
            'Top Rated Cooks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Local cooks near you'),
            subtitle: Text('Discover meals made at home'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.cart);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _mealList(BuildContext context, List<MealModel> items) {
    if (items.isEmpty) return const Text('No meals available yet.');
    return Column(
      children: items
          .take(6)
          .map(
            (meal) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                title: Text(meal.name),
                subtitle: Text(
                  '${meal.cookName ?? 'Local cook'}  ·  ${meal.rating ?? '-'} ★',
                ),
                trailing: Text('\$${meal.price.toStringAsFixed(2)}'),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.mealDetails,
                  arguments: meal.id,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
