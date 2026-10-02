import 'package:flutter/material.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'routes/route_generator.dart';

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: ClampingScrollPhysics(),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generate,
    );
  }
}
