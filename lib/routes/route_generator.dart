import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/customer/screens/customer_login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
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
import '../features/cook/screens/cook_login_screen.dart';
import '../features/cook/screens/cook_dashboard_screen.dart';
import '../features/cook/screens/manage_menu_screen.dart';
import '../features/cook/screens/add_meal_screen.dart';
import '../features/cook/screens/edit_meal_screen.dart';
import '../features/cook/screens/cook_orders_screen.dart';
import '../features/cook/screens/order_details_screen.dart';
import '../features/cook/screens/update_order_status_screen.dart';
import '../features/cook/screens/preparing_order_screen.dart';
import '../features/cook/screens/cook_earnings_screen.dart';
import '../features/cook/screens/cook_profile_screen.dart' as cook;
import '../features/cook/screens/cook_notifications_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.welcome => const WelcomeScreen(),
      AppRoutes.roleSelection => const RoleSelectionScreen(),
      AppRoutes.login => const CustomerLoginScreen(),
      AppRoutes.customerLogin => const CustomerLoginScreen(),
      AppRoutes.cookLogin => const CookLoginScreen(),
      AppRoutes.cookDashboard => const CookDashboardScreen(),
      AppRoutes.manageMenu => const ManageMenuScreen(),
      AppRoutes.addMeal => const AddMealScreen(),
      AppRoutes.editMeal => EditMealScreen(
          meal: settings.arguments as Map<String, dynamic>,
        ),
      AppRoutes.cookOrders => const CookOrdersScreen(),
      AppRoutes.cookOrderDetails => OrderDetailsScreen(
          orderId: settings.arguments as String,
        ),
      AppRoutes.updateOrderStatus => UpdateOrderStatusScreen(
          order: settings.arguments as Map<String, dynamic>,
        ),
      AppRoutes.preparingOrder => PreparingOrderScreen(
          order: settings.arguments as Map<String, dynamic>,
        ),
      AppRoutes.cookEarnings => const CookEarningsScreen(),
      AppRoutes.cookProfileSettings => const cook.CookProfileScreen(),
      AppRoutes.cookNotifications => const CookNotificationsScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.verifyEmail => VerifyEmailScreen(
        email: settings.arguments as String,
      ),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.resetPassword => ResetPasswordScreen(
        email: (settings.arguments as Map<String, dynamic>)['email'] as String,
      ),
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
