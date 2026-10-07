import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../providers/meal_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  String? _category;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _search();
    });
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
              onChanged: _onQueryChanged,
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
              children: ['All', 'Rice', 'Curry', 'Kottu', 'Healthy']
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: category == 'All'
                            ? _category == null
                            : _category == category,
                        selectedColor: const Color(0xFFFFF3E0),
                        onSelected: (_) {
                          setState(
                            () => _category = category == 'All' ? null : category,
                          );
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
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No meals found matching your search.'),
                    ),
                  );
                }
                return ListView.builder(
                  key: const PageStorageKey<String>('search_results_scroll'),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final meal = items[index];
                    final imageUrl = meal.imageUrl;
                    return ListTile(
                      leading: AppCachedImage(
                        imageUrl: imageUrl,
                        width: 44,
                        height: 44,
                        borderRadius: 8,
                        fallbackIcon: Icons.restaurant,
                      ),
                      title: Text(
                        meal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${meal.cookName ?? 'Home Cook Kitchen'} · ${meal.rating ?? '4.8'} ★',
                      ),
                      trailing: Text(
                        'Rs. ${meal.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.mealDetails,
                        arguments: meal.id,
                      ),
                    );
                  },
                );
              },
              error: (error, _) =>
                  Center(child: Text('Unable to load meals: $error')),
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) => const MealTileSkeleton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
