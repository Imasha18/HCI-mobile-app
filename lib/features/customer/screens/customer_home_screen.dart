import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../models/meal_model.dart';
import '../../../models/meal_recommendation_model.dart';
import '../providers/cooks_provider.dart';
import '../providers/customer_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  String _getDeliveryTown(Map<String, dynamic>? user) {
    if (user == null) return 'Colombo 03';
    final town = (user['town'] as String?)?.trim();
    if (town != null && town.isNotEmpty) return town;
    final city = (user['city'] as String?)?.trim();
    if (city != null && city.isNotEmpty) return city;
    final address = (user['address'] as String?)?.trim();
    if (address != null && address.isNotEmpty) {
      var cleaned = address.replaceAll(RegExp(r',\s*Sri Lanka$', caseSensitive: false), '').trim();
      final colomboMatch = RegExp(r'colombo[\s-]*(?:0?[1-9]|1[0-5])\b', caseSensitive: false).firstMatch(cleaned);
      if (colomboMatch != null) {
        final digits = colomboMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isNotEmpty ? 'Colombo ${digits.padLeft(2, '0')}' : 'Colombo';
      }
      final parts = cleaned.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      for (int i = parts.length - 1; i >= 0; i--) {
        var part = parts[i];
        if (RegExp(r'^sri lanka$', caseSensitive: false).hasMatch(part)) continue;
        if (RegExp(r'^(lk-?)?\d{4,6}$', caseSensitive: false).hasMatch(part)) continue;
        part = part.replaceAll(RegExp(r'[-,\s]*\b\d{4,6}\b.*$'), '').trim();
        if (part.isNotEmpty) {
          return part.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
        }
      }
      if (parts.isNotEmpty) return parts.last;
    }
    return 'Colombo 03';
  }

  String _greetingTitle(Map<String, dynamic>? user) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final name = (user?['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      final firstName = name.split(' ').first;
      return '$timeGreeting, $firstName!';
    }
    return '$timeGreeting!';
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      return Icons.lunch_dining_rounded;
    } else {
      return Icons.dinner_dining_rounded;
    }
  }

  Future<void> _refreshAllData({bool forceRefresh = false}) async {
    await Future.wait([
      ref.read(customerProvider.notifier).loadProfile(forceRefresh: forceRefresh),
      ref.read(mealProvider.notifier).fetchMeals(
            category: _selectedCategory == 'All' ? null : _selectedCategory,
            forceRefresh: forceRefresh,
          ),
      ref.read(cooksProvider.notifier).fetchCooks(forceRefresh: forceRefresh),
      ref.read(recommendationProvider.notifier).loadRecommendations(forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customerState = ref.watch(customerProvider);
    final deliveryTown = _getDeliveryTown(customerState.user);
    final meals = ref.watch(mealProvider);
    final cooksAsync = ref.watch(cooksProvider);
    final recState = ref.watch(recommendationProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DELIVER TO',
                style: TextStyle(fontSize: 11, letterSpacing: 1.2),
              ),
              Text(
                '$deliveryTown  ·  Change',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        onRefresh: () => _refreshAllData(forceRefresh: true),
        child: ListView(
          key: const PageStorageKey<String>('customer_home_scroll'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24FF7A00),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingTitle(customerState.user),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'What are you craving today?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _greetingIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              readOnly: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.search),
              decoration: const InputDecoration(
                hintText: 'Search meals, cuisines, ingredients...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                children: categories.map(
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
                ).toList(),
              ),
              loading: () => Wrap(
                spacing: 8,
                children: ['All', 'Rice', 'Curry', 'Kottu', 'Healthy']
                    .map((cat) => ChoiceChip(label: Text(cat), selected: _selectedCategory == cat))
                    .toList(),
              ),
              error: (_, _) => Wrap(
                spacing: 8,
                children: ['All', 'Rice', 'Curry', 'Kottu', 'Healthy']
                    .map((cat) => ChoiceChip(label: Text(cat), selected: _selectedCategory == cat))
                    .toList(),
              ),
            ),
            if (recState.shouldShowOnboardingBanner) ...[
              const SizedBox(height: 18),
              _buildOnboardingBanner(context),
            ],
            const SizedBox(height: 24),
            _buildRecommendationsSection(context, recState, meals.valueOrNull ?? []),
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
              error: (error, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 36, color: Color(0xFFFF9800)),
                    const SizedBox(height: 8),
                    const Text(
                      'Unable to load meals right now.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => ref.read(mealProvider.notifier).fetchMeals(
                            category: _selectedCategory == 'All' ? null : _selectedCategory,
                            forceRefresh: true,
                          ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Tap to retry'),
                    ),
                  ],
                ),
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
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: Color(0xFFFF9800)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Unable to load kitchens.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(cooksProvider.notifier).fetchCooks(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
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
                  minimumSize: const Size(0, 36),
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

  Widget _buildRecommendationsSection(
    BuildContext context,
    RecommendationState recState,
    List<MealModel> availableMeals,
  ) {
    if (recState.isLoading && recState.recommendations.isEmpty) {
      return _buildRecommendationsSkeleton();
    }

    final List<MealRecommendation> displayRecs;
    if (recState.recommendations.isNotEmpty) {
      displayRecs = recState.recommendations;
    } else if (availableMeals.isNotEmpty) {
      final sortedMeals = List<MealModel>.from(availableMeals)
        ..sort((a, b) => (b.rating ?? 4.5).compareTo(a.rating ?? 4.5));
      displayRecs = sortedMeals.take(6).map((m) {
        final r = m.rating ?? 4.8;
        return MealRecommendation(
          meal: m,
          reasons: [
            if (r >= 4.7) 'Top rated (${r.toStringAsFixed(1)} ★)' else 'Popular Favourite',
            'Fresh Homemade',
          ],
          score: r * 2,
        );
      }).toList();
    } else {
      displayRecs = const [];
    }

    if (displayRecs.isEmpty) {
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
            itemCount: displayRecs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = displayRecs[index];
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
                              (meal.rating ?? 4.8).toStringAsFixed(1),
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
