import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../features/customer/screens/customer_login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/screens/customer_home_screen.dart';
import '../features/customer/screens/search_screen.dart';
import '../features/customer/screens/meal_details_screen.dart';
import '../features/customer/screens/cook_profile_screen.dart';
import '../features/customer/screens/cart_screen.dart';
import '../features/customer/screens/checkout_screen.dart';
import '../features/customer/screens/payment_screen.dart';
import '../features/customer/screens/order_confirmation_screen.dart';
import '../features/customer/screens/tracking_screen.dart';
import '../features/customer/screens/orders_screen.dart';
import '../features/customer/screens/review_screen.dart';
import '../features/customer/screens/customer_profile_screen.dart';
import '../features/customer/screens/notification_screen.dart';

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
      AppRoutes.checkout => const CheckoutScreen(),
      AppRoutes.payment => PaymentScreen(
        orderId:
            (settings.arguments as Map<String, dynamic>)['orderId'] as String,
        amount: ((settings.arguments as Map<String, dynamic>)['amount'] as num)
            .toDouble(),
      ),
      AppRoutes.confirmation => OrderConfirmationScreen(
        orderId: settings.arguments as String,
      ),
      AppRoutes.tracking => TrackingScreen(
        orderId: settings.arguments as String,
      ),
      AppRoutes.orders => const OrdersScreen(),
      AppRoutes.review => ReviewScreen(mealId: settings.arguments as String),
      AppRoutes.profile => const CustomerProfileScreen(),
      AppRoutes.notifications => const NotificationScreen(),
      _ => const Scaffold(body: Center(child: Text('Page not found'))),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
