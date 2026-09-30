import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../providers/meal_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String? _category;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() => ref
      .read(mealProvider.notifier)
      .fetchMeals(query: _controller.text, category: _category);
  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Search meals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Meals, cuisines, ingredients',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.tune),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children:
                  ['Breakfast', 'Lunch', 'Dinner', 'Healthy', 'Vegetarian']
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) {
                              setState(() => _category = category);
                              _search();
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: meals.when(
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final meal = items[index];
                  return ListTile(
                    title: Text(meal.name),
                    subtitle: Text(
                      '${meal.cookName ?? 'Local cook'} · ${meal.rating ?? '-'} ★',
                    ),
                    trailing: Text('Rs ${meal.price.toStringAsFixed(2)}'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.mealDetails,
                      arguments: meal.id,
                    ),
                  );
                },
              ),
              error: (error, _) =>
                  Center(child: Text('Unable to load meals: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
