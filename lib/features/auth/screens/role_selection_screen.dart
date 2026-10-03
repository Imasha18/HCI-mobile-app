import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../config/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with HomeBite Logo and Name
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFFFF7A00),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'HomeBite',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFFFF7A00),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Title & Subtitle matching prototype
              const Text(
                'How will you\njoin us?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick your role to continue',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 28),

              // Role Card 1: Foodies (Customer)
              _RoleCard(
                title: 'I want to eat',
                badgeText: 'For foodies',
                description: 'Order authentic homemade meals from local cooks near you',
                icon: Icons.restaurant_rounded,
                cardBgColor: const Color(0xFFFFF9F0),
                borderColor: const Color(0xFFFFE8D1),
                badgeBgColor: const Color(0xFFFFE0B2),
                badgeTextColor: const Color(0xFFE65100),
                iconBgColor: const Color(0xFFFFE0B2),
                iconColor: const Color(0xFFFF7A00),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),

              const SizedBox(height: 16),

              // Role Card 2: Home Cooks
              _RoleCard(
                title: 'I want to cook',
                badgeText: 'For home cooks',
                description: 'Turn your kitchen into a business and earn from home',
                icon: Icons.soup_kitchen_rounded,
                cardBgColor: const Color(0xFFFFFDE7),
                borderColor: const Color(0xFFFFF9C4),
                badgeBgColor: const Color(0xFFFFF59D),
                badgeTextColor: const Color(0xFFF57F17),
                iconBgColor: const Color(0xFFFFF59D),
                iconColor: const Color(0xFFF57F17),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.cookLogin);
                },
              ),

              const SizedBox(height: 16),

              // Role Card 3: Delivery Riders
              _RoleCard(
                title: 'I want to deliver',
                badgeText: 'For riders',
                description: 'Earn flexibly by delivering meals on your own schedule',
                icon: Icons.two_wheeler_rounded,
                cardBgColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                badgeBgColor: const Color(0xFFA5D6A7),
                badgeTextColor: const Color(0xFF1B5E20),
                iconBgColor: const Color(0xFFA5D6A7),
                iconColor: const Color(0xFF2E7D32),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rider delivery portal available for registered delivery partners.'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // Social proof banner matching prototype bottom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar stack
                    SizedBox(
                      width: 58,
                      height: 28,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.orange.shade200,
                              child: const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            left: 15,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.teal.shade200,
                              child: const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            left: 30,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.amber.shade200,
                              child: const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '8,400+ people are already on HomeBite',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String badgeText;
  final String description;
  final IconData icon;
  final Color cardBgColor;
  final Color borderColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.badgeText,
    required this.description,
    required this.icon,
    required this.cardBgColor,
    required this.borderColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF616161),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arrow button in circle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
