import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../features/customer/screens/customer_login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/screens/customer_home_screen.dart';
import '../features/customer/screens/search_screen.dart';
import '../features/customer/screens/meal_details_screen.dart';
import '../features/customer/screens/cook_profile_screen.dart';
import '../features/customer/screens/cart_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.login => const CustomerLoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.home => const CustomerHomeScreen(),
      AppRoutes.cart => const CartScreen(),
      AppRoutes.search => const SearchScreen(),
      AppRoutes.mealDetails => MealDetailsScreen(
        mealId: settings.arguments as String,
      ),
      AppRoutes.cookProfile => CookProfileScreen(
        cookId: settings.arguments as String,
      ),
      _ => const Scaffold(body: Center(child: Text('Page not found'))),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
