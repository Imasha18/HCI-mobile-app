import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../models/meal_model.dart';
import '../../../models/meal_recommendation_model.dart';
import '../providers/cooks_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/recommendation_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final meals = ref.watch(mealProvider);
    final cooksAsync = ref.watch(cooksProvider);
    final recState = ref.watch(recommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DELIVER TO',
              style: TextStyle(fontSize: 11, letterSpacing: 1.2),
            ),
            Text('Colombo 03  ·  Change', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF9800),
        onRefresh: () async {
          await Future.wait([
            ref.read(mealProvider.notifier).fetchMeals(
                  category: _selectedCategory == 'All' ? null : _selectedCategory,
                  forceRefresh: true,
                ),
            ref.read(cooksProvider.notifier).fetchCooks(forceRefresh: true),
            ref.read(recommendationProvider.notifier).loadRecommendations(forceRefresh: true),
          ]);
        },
        child: ListView(
          key: const PageStorageKey<String>('customer_home_scroll'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Text(
              'Good evening.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('What are you craving today?'),
            const SizedBox(height: 22),
            TextField(
              readOnly: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.search),
              decoration: const InputDecoration(
                hintText: 'Search meals, cuisines, ingredients...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: ['All', 'Rice', 'Curry', 'Kottu', 'Healthy']
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      selectedColor: const Color(0xFFFFF3E0),
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? const Color(0xFFFF9800)
                            : Colors.black87,
                        fontWeight: _selectedCategory == category
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                          ref.read(mealProvider.notifier).fetchMeals(
                                category: category == 'All' ? null : category,
                              );
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            if (recState.shouldShowOnboardingBanner) ...[
              const SizedBox(height: 18),
              _buildOnboardingBanner(context),
            ],
            const SizedBox(height: 24),
            _buildRecommendationsSection(context, recState),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Near You',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '$_selectedCategory Dishes',
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            meals.when(
              data: (items) => _mealList(context, items),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error.toString().replaceFirst('Exception: ', '')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.read(mealProvider.notifier).fetchMeals(
                          category:
                              _selectedCategory == 'All' ? null : _selectedCategory,
                          forceRefresh: true,
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              loading: () => Column(
                children: List.generate(4, (_) => const MealTileSkeleton()),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Home Cook Kitchens',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Verified Suppliers',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            cooksAsync.when(
              data: (cooks) {
                if (cooks.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.storefront, color: Color(0xFFFF9800)),
                      ),
                      title: Text('Local Home Cook Kitchens'),
                      subtitle:
                          Text('Fresh homemade meals from local home cooks'),
                    ),
                  );
                }

                return Column(
                  children: cooks.take(4).map((cookMap) {
                    final cookId =
                        (cookMap['id'] ?? cookMap['_id'] ?? '').toString();
                    final kitchenName = (cookMap['kitchenName'] as String?)
                                ?.isNotEmpty ==
                            true
                        ? cookMap['kitchenName'] as String
                        : '${cookMap['name'] ?? 'Home'}\'s Kitchen';
                    final cookName =
                        cookMap['name'] as String? ?? 'Home Cook';
                    final rating = (cookMap['rating'] ?? 4.8).toString();
                    final address =
                        cookMap['address'] as String? ?? 'Colombo, Sri Lanka';
                    final mealCount = cookMap['mealCount'] ?? 0;
                    final profileImage = cookMap['profileImage'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: AppCachedImage(
                          imageUrl: profileImage,
                          width: 44,
                          height: 44,
                          borderRadius: 22,
                          fallbackIcon: Icons.person,
                        ),
                        title: Text(
                          kitchenName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$cookName  ·  $address\n$mealCount home-cooked dishes available',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (cookId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.cookProfile,
                              arguments: cookId,
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Column(
                children: List.generate(3, (_) => const UserCardSkeleton()),
              ),
              error: (err, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.cart);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.profile);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _mealList(BuildContext context, List<MealModel> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 40, color: Color(0xFFFF9800)),
              SizedBox(height: 8),
              Text(
                'No meals added yet in this category.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Meals created by Home Cooks will appear here immediately.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.take(6).map(
        (meal) {
          final imageUrl = meal.imageUrl;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: AppCachedImage(
                imageUrl: imageUrl,
                width: 54,
                height: 54,
                borderRadius: 10,
                fallbackIcon: Icons.restaurant,
              ),
              title: Text(
                meal.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${meal.cookName ?? 'Home Cook Kitchen'}  ·  ${meal.rating != null ? '${meal.rating} ★' : '4.9 ★'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                'Rs. ${meal.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                  fontSize: 15,
                ),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.mealDetails,
                arguments: meal.id,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildOnboardingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0x26FF7A00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFF7A00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Personalize your meals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(recommendationProvider.notifier).dismissOnboardingBanner();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us your dietary needs, favorite cuisines, spice and budget so we can recommend the best homemade food.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A), height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.foodPreferences),
                child: const Text('Set preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ref.read(recommendationProvider.notifier).dismissOnboardingBanner();
                },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, RecommendationState recState) {
    if (recState.isLoading && recState.recommendations.isEmpty) {
      return _buildRecommendationsSkeleton();
    }

    if (recState.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 20),
                SizedBox(width: 8),
                Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.foodPreferences),
              icon: const Icon(Icons.tune, size: 14, color: Color(0xFFFF7A00)),
              label: const Text(
                'Preferences',
                style: TextStyle(
                  color: Color(0xFFFF7A00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 254,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recState.recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = recState.recommendations[index];
              return _buildRecommendationCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(BuildContext context, MealRecommendation item) {
    final meal = item.meal;
    final primaryReason = item.reasons.isNotEmpty ? item.reasons.join(' · ') : 'Recommended';

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEAE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(recommendationProvider.notifier).trackInteraction(meal.id, 'meal_clicked');
            Navigator.pushNamed(
              context,
              AppRoutes.mealDetails,
              arguments: {
                'mealId': meal.id,
                'reasons': item.reasons,
              },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: AppCachedImage(
                    imageUrl: meal.imageUrl,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.restaurant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.cookName ?? 'Home Cook Kitchen',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${meal.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A00),
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                            const SizedBox(width: 3),
                            Text(
                              meal.rating != null ? meal.rating!.toStringAsFixed(1) : '4.8',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        primaryReason,
                        style: const TextStyle(
                          color: Color(0xFFD35400),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBox(width: 170, height: 20, borderRadius: 6),
            ShimmerBox(width: 60, height: 16, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, _) => Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEAE3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 220, height: 130, borderRadius: 15),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 90, height: 10, borderRadius: 4),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 60, height: 12, borderRadius: 4),
                            ShimmerBox(width: 40, height: 12, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
