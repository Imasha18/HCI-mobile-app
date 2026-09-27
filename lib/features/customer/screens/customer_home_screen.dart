import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _discover(context),
          const Center(child: Text('Your orders will appear here')),
          const Center(child: Text('Profile')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _discover(BuildContext context) {
    final meals = [
      ('Sunday roast', 'Mara’s Kitchen', '\$18', Icons.ramen_dining),
      ('Coconut curry', 'Asha’s Table', '\$15', Icons.lunch_dining),
      ('Lemon olive cake', 'Nora Bakes', '\$9', Icons.cake_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        Text(
          'Good evening.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Text('What are you craving today?'),
        const SizedBox(height: 22),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search dishes, cooks, cuisines',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Made nearby', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...meals.map(
          (meal) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(meal.$4),
              ),
              title: Text(
                meal.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${meal.$2}  ·  4.9 ★'),
              trailing: Text(
                meal.$3,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ),
        ),
      ],
    );
  }
}
