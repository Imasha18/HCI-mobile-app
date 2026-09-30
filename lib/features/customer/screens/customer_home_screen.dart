import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../models/meal_model.dart';
import '../../../services/api_client.dart';
import '../providers/meal_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
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
            Text('Colombo 03  ·  Change', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
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
            children: ['All', 'Rice', 'Curry', 'Kottu', 'Healthy']
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    selectedColor: const Color(0xFFFFF3E0),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? const Color(0xFFFF9800)
                          : Colors.black87,
                      fontWeight: _selectedCategory == category
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                        ref.read(mealProvider.notifier).fetchMeals(
                              category: category == 'All' ? null : category,
                            );
                      }
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Near You',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '$_selectedCategory Dishes',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Home Cook Kitchens',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Verified Suppliers',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Response<dynamic>>(
            future: ApiClient().dio.get('/cooks'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final cooks =
                  (snapshot.data?.data?['data'] as List<dynamic>?) ?? [];
              if (cooks.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.storefront, color: Color(0xFFFF9800)),
                    ),
                    title: Text('Local Home Cook Kitchens'),
                    subtitle: Text('Fresh homemade meals from local home cooks'),
                  ),
                );
              }

              return Column(
                children: cooks.take(4).map((cook) {
                  final cookMap = cook as Map<String, dynamic>;
                  final cookId =
                      (cookMap['id'] ?? cookMap['_id'] ?? '').toString();
                  final kitchenName = (cookMap['kitchenName'] as String?)
                              ?.isNotEmpty ==
                          true
                      ? cookMap['kitchenName'] as String
                      : '${cookMap['name'] ?? 'Home'}\'s Kitchen';
                  final cookName = cookMap['name'] as String? ?? 'Home Cook';
                  final rating = (cookMap['rating'] ?? 4.8).toString();
                  final address =
                      cookMap['address'] as String? ?? 'Colombo, Sri Lanka';
                  final mealCount = cookMap['mealCount'] ?? 0;
                  final profileImage = cookMap['profileImage'] as String?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFF3E0),
                        backgroundImage: profileImage != null &&
                                profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage == null || profileImage.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFFFF9800))
                            : null,
                      ),
                      title: Text(
                        kitchenName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$cookName  ·  $address\n$mealCount home-cooked dishes available',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (cookId.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.cookProfile,
                            arguments: cookId,
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.cart);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.profile);
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
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 40, color: Color(0xFFFF9800)),
              SizedBox(height: 8),
              Text(
                'No meals added yet in this category.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Meals created by Home Cooks will appear here immediately.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.take(6).map(
        (meal) {
          final imageUrl = meal.imageUrl;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFFFFF3E0),
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        color: const Color(0xFFFFF3E0),
                        child: const Icon(
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
                '${meal.cookName ?? 'Home Cook Kitchen'}  ·  ${meal.rating != null ? '${meal.rating} ★' : '4.9 ★'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                'Rs. ${meal.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                  fontSize: 15,
                ),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.mealDetails,
                arguments: meal.id,
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}
