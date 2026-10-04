import 'package:flutter/material.dart';

/// Lightweight, fluid shimmer box without heavy third-party animation dependencies
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          const Color(0xFFE5E7EB),
          const Color(0xFFF3F4F6),
          (_animation.value - 0.35) / 0.5,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: widget.shape != null
              ? ShapeDecoration(color: shimmerColor, shape: widget.shape!)
              : BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
        );
      },
    );
  }
}

/// Reusable Meal Card Skeleton matching Customer & Admin meal card layouts
class MealCardSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const MealCardSkeleton({
    super.key,
    this.width = 190,
    this.height = 230,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: 14,
            ),
          ),
          SizedBox(height: 10),
          ShimmerBox(width: 120, height: 14, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBox(width: 80, height: 12, borderRadius: 6),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 60, height: 14, borderRadius: 6),
              ShimmerBox(width: 32, height: 32, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable Meal List Tile Skeleton matching CustomerHomeScreen meal list
class MealTileSkeleton extends StatelessWidget {
  const MealTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 54, height: 54, borderRadius: 10),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 12, borderRadius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 60, height: 16, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Reusable Order Card Skeleton matching Customer, Cook, Rider, and Admin views
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 110, height: 16, borderRadius: 6),
              ShimmerBox(width: 80, height: 22, borderRadius: 12),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(width: 48, height: 48, borderRadius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 70, height: 14, borderRadius: 6),
              ShimmerBox(width: 90, height: 16, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable User Card Skeleton for Admin & Kitchen profiles
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 130, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12, borderRadius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 50, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Reusable Notification Skeleton
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 36, height: 36, borderRadius: 18),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 12, borderRadius: 6),
                SizedBox(height: 4),
                ShimmerBox(width: 180, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard Statistics Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox()),
            const SizedBox(width: 12),
            Expanded(child: _statBox()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statBox()),
            const SizedBox(width: 12),
            Expanded(child: _statBox()),
          ],
        ),
      ],
    );
  }

  Widget _statBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 32, height: 32, borderRadius: 10),
          SizedBox(height: 12),
          ShimmerBox(width: 80, height: 18, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBox(width: 60, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}
