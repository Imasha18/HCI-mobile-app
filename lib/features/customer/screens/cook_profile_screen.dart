import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../services/api_client.dart';

class CookProfileScreen extends StatelessWidget {
  const CookProfileScreen({super.key, required this.cookId});
  final String cookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cook profile')),
      body: FutureBuilder<Response<dynamic>>(
        future: ApiClient().dio.get('/cooks/$cookId'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data['data'] as Map<String, dynamic>;
          final cook = data['cook'] as Map<String, dynamic>;
          final meals = data['meals'] as List<dynamic>;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 48,
                child: Icon(Icons.person, size: 48),
              ),
              const SizedBox(height: 14),
              Text(
                cook['name'] as String? ?? 'Home cook',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(cook['address'] as String? ?? 'Local kitchen'),
              const SizedBox(height: 24),
              Text(
                'Available meals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...meals.map(
                (meal) => ListTile(
                  title: Text(meal['name'] as String),
                  trailing: Text('Rs ${meal['price']}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
