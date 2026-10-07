import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/splash_screen.dart';
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
import '../features/cook/screens/cook_register_screen.dart';
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
import '../features/rider/screens/rider_login_screen.dart';
import '../features/rider/screens/rider_register_screen.dart';
import '../features/rider/screens/rider_dashboard_screen.dart';
import '../features/rider/screens/delivery_requests_screen.dart';
import '../features/rider/screens/delivery_request_details_screen.dart';
import '../features/rider/screens/accept_delivery_screen.dart';
import '../features/rider/screens/pickup_screen.dart';
import '../features/rider/screens/navigation_screen.dart';
import '../features/rider/screens/in_transit_screen.dart';
import '../features/rider/screens/delivery_confirmation_screen.dart';
import '../features/rider/screens/rider_earnings_screen.dart';
import '../features/rider/screens/delivery_history_screen.dart';
import '../features/rider/screens/rider_profile_screen.dart';
import '../features/rider/screens/rider_notifications_screen.dart';
import '../features/admin/screens/admin_login_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/admin/screens/customer_management_screen.dart';
import '../features/admin/screens/cook_management_screen.dart';
import '../features/admin/screens/rider_management_screen.dart';
import '../features/admin/screens/verification_screen.dart';
import '../features/admin/screens/meal_management_screen.dart';
import '../features/admin/screens/order_monitoring_screen.dart';
import '../features/admin/screens/complaint_screen.dart';
import '../features/admin/screens/reports_screen.dart';
import '../features/admin/screens/statistics_screen.dart';
import '../features/admin/screens/admin_notification_screen.dart';
import '../features/admin/screens/admin_profile_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.welcome => const WelcomeScreen(),
      AppRoutes.roleSelection => const RoleSelectionScreen(),
      AppRoutes.login => const CustomerLoginScreen(),
      AppRoutes.customerLogin => const CustomerLoginScreen(),
      AppRoutes.cookLogin => const CookLoginScreen(),
      AppRoutes.cookRegister => const CookRegisterScreen(),
      AppRoutes.cookDashboard => const CookDashboardScreen(),
      AppRoutes.riderLogin => const RiderLoginScreen(),
      AppRoutes.riderRegister => const RiderRegisterScreen(),
      AppRoutes.riderDashboard => const RiderDashboardScreen(),
      AppRoutes.deliveryRequests => const DeliveryRequestsScreen(),
      AppRoutes.deliveryRequestDetails => DeliveryRequestDetailsScreen(
          deliveryId: settings.arguments as String? ?? '',
        ),
      AppRoutes.acceptDelivery => AcceptDeliveryScreen(
          delivery: settings.arguments is Map
              ? Map<String, dynamic>.from(settings.arguments as Map)
              : <String, dynamic>{},
        ),
      AppRoutes.riderPickup => PickupScreen(
          delivery: settings.arguments is Map
              ? Map<String, dynamic>.from(settings.arguments as Map)
              : <String, dynamic>{},
        ),
      AppRoutes.riderNavigation => NavigationScreen(
          delivery: settings.arguments is Map
              ? Map<String, dynamic>.from(settings.arguments as Map)
              : <String, dynamic>{},
        ),
      AppRoutes.riderInTransit => InTransitScreen(
          delivery: settings.arguments is Map
              ? Map<String, dynamic>.from(settings.arguments as Map)
              : <String, dynamic>{},
        ),
      AppRoutes.riderDeliveryConfirmation => DeliveryConfirmationScreen(
          delivery: settings.arguments is Map
              ? Map<String, dynamic>.from(settings.arguments as Map)
              : <String, dynamic>{},
        ),
      AppRoutes.riderEarnings => const RiderEarningsScreen(),
      AppRoutes.deliveryHistory => const DeliveryHistoryScreen(),
      AppRoutes.riderProfile => const RiderProfileScreen(),
      AppRoutes.riderNotifications => const RiderNotificationsScreen(),
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
      AppRoutes.adminLogin => const AdminLoginScreen(),
      AppRoutes.adminDashboard => const AdminDashboardScreen(),
      AppRoutes.adminUsers => const UserManagementScreen(),
      AppRoutes.adminCustomers => const CustomerManagementScreen(),
      AppRoutes.adminCooks => const CookManagementScreen(),
      AppRoutes.adminRiders => const RiderManagementScreen(),
      AppRoutes.adminVerification => const VerificationScreen(),
      AppRoutes.adminMeals => const MealManagementScreen(),
      AppRoutes.adminOrders => const OrderMonitoringScreen(),
      AppRoutes.adminComplaints => const ComplaintScreen(),
      AppRoutes.adminReports => const ReportsScreen(),
      AppRoutes.adminStatistics => const StatisticsScreen(),
      AppRoutes.adminNotifications => const AdminNotificationScreen(),
      AppRoutes.adminProfile => const AdminProfileScreen(),
      _ => const Scaffold(body: Center(child: Text('Page not found'))),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
