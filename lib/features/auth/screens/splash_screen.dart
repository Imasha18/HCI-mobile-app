import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';
import '../../../services/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }

      // Validate session with backend
      final response = await ApiClient().dio.get('/auth/me');
      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = response.data['data'] as Map<String, dynamic>;
        final role = user['role'] as String? ?? 'customer';

        switch (role) {
          case 'admin':
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
            break;
          case 'cook':
            Navigator.pushReplacementNamed(context, AppRoutes.cookDashboard);
            break;
          case 'rider':
            Navigator.pushReplacementNamed(context, AppRoutes.riderDashboard);
            break;
          case 'customer':
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
        }
      } else {
        await _storage.delete(key: 'auth_token');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } catch (_) {
      // Offline fallback: if network is down but token exists, route safely or to role selection
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                AppAssets.logo,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'HomeBite',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fresh Homemade Meals Delivered',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
