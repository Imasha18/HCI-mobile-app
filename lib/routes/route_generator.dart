import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/screens/customer_home_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.home => const CustomerHomeScreen(),
      AppRoutes.cart => Scaffold(
        appBar: AppBar(title: const Text('Your basket')),
        body: const Center(child: Text('Your basket is empty')),
      ),
      _ => const Scaffold(body: Center(child: Text('Page not found'))),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
