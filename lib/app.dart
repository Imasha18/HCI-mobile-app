import 'package:flutter/material.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'core/utils/navigator_key.dart';
import 'features/admin/services/admin_session_manager.dart';
import 'routes/route_generator.dart';

class DeliveryApp extends StatefulWidget {
  const DeliveryApp({super.key});

  @override
  State<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends State<DeliveryApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (AdminSessionManager().isActive) {
        AdminSessionManager().isSessionExpired().then((expired) {
          if (expired) {
            AdminSessionManager().handleTimeout();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeBite',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generate,
    );
  }
}
