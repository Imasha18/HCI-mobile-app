import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../services/api_client.dart';

class CookProfileScreen extends StatelessWidget {
  const CookProfileScreen({super.key, required this.cookId});
  final String cookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen & Supplier Profile')),
      body: FutureBuilder<Response<dynamic>>(
        future: ApiClient().dio.get('/cooks/$cookId'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Unable to load supplier details'),
            );
          }

          final data = snapshot.data!.data['data'] as Map<String, dynamic>;
          final cook = data['cook'] as Map<String, dynamic>;
          final meals = (data['meals'] as List<dynamic>?) ?? [];

          final kitchenName = (cook['kitchenName'] as String?)?.isNotEmpty ==
                  true
              ? cook['kitchenName'] as String
              : '${cook['name'] ?? 'Home'}\'s Kitchen';
          final cookName = cook['name'] as String? ?? 'Home Cook';
          final address = cook['address'] as String? ?? 'Colombo, Sri Lanka';
          final rating = (cook['rating'] ?? 4.8).toString();
          final profileImage = cook['profileImage'] as String?;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFFFF3E0),
                  backgroundImage:
                      profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 46,
                          color: Color(0xFFFF9800),
                        )
                      : null,
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
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl != null &&
                                (imageUrl as String).isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFFFFF3E0),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFFFF9800),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: const Color(0xFFFFF3E0),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
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
          );
        },
      ),
    );
  }
}
