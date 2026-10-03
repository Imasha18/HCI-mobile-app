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
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final meal = items[index];
                  final imageUrl = meal.imageUrl;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const CircleAvatar(
                                backgroundColor: Color(0xFFFFF3E0),
                                child: Icon(
                                  Icons.restaurant,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            )
                          : const CircleAvatar(
                              backgroundColor: Color(0xFFFFF3E0),
                              child: Icon(
                                Icons.restaurant,
                                color: Color(0xFFFF9800),
                              ),
                            ),
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
