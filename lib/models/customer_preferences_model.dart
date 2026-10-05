class CustomerPreferences {
  final String dietaryPreference;
  final List<String> favouriteCuisines;
  final String budgetPreference;
  final double? maxBudget;
  final String spicePreference;
  final bool onboardingCompleted;

  const CustomerPreferences({
    this.dietaryPreference = 'no_preference',
    this.favouriteCuisines = const [],
    this.budgetPreference = 'no_preference',
    this.maxBudget,
    this.spicePreference = 'no_preference',
    this.onboardingCompleted = false,
  });

  bool get hasSetPreferences =>
      onboardingCompleted ||
      dietaryPreference != 'no_preference' ||
      favouriteCuisines.isNotEmpty ||
      budgetPreference != 'no_preference' ||
      spicePreference != 'no_preference';

  String get dietaryLabel {
    switch (dietaryPreference) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'vegan':
        return 'Vegan';
      case 'non_vegetarian':
        return 'Non-Vegetarian';
      case 'pescatarian':
        return 'Pescatarian';
      default:
        return 'No Preference';
    }
  }

  String get budgetLabel {
    switch (budgetPreference) {
      case 'under_500':
        return 'Under Rs. 500';
      case '500_800':
        return 'Rs. 500–800';
      case '800_1200':
        return 'Rs. 800–1200';
      case '1200_plus':
        return 'Rs. 1200+';
      default:
        return 'No Preference';
    }
  }

  String get spiceLabel {
    switch (spicePreference) {
      case 'mild':
        return 'Mild';
      case 'medium':
        return 'Medium';
      case 'spicy':
        return 'Spicy';
      default:
        return 'No Preference';
    }
  }

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) {
    return CustomerPreferences(
      dietaryPreference: (json['dietaryPreference'] as String?) ?? 'no_preference',
      favouriteCuisines: (json['favouriteCuisines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      budgetPreference: (json['budgetPreference'] as String?) ?? 'no_preference',
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      spicePreference: (json['spicePreference'] as String?) ?? 'no_preference',
      onboardingCompleted: (json['onboardingCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'dietaryPreference': dietaryPreference,
        'favouriteCuisines': favouriteCuisines,
        'budgetPreference': budgetPreference,
        if (maxBudget != null) 'maxBudget': maxBudget,
        'spicePreference': spicePreference,
        'onboardingCompleted': onboardingCompleted,
      };

  CustomerPreferences copyWith({
    String? dietaryPreference,
    List<String>? favouriteCuisines,
    String? budgetPreference,
    double? maxBudget,
    String? spicePreference,
    bool? onboardingCompleted,
  }) {
    return CustomerPreferences(
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      favouriteCuisines: favouriteCuisines ?? this.favouriteCuisines,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      maxBudget: maxBudget ?? this.maxBudget,
      spicePreference: spicePreference ?? this.spicePreference,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
