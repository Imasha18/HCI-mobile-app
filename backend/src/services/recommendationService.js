const Meal = require('../models/Meal');
const User = require('../models/User');
const Order = require('../models/Order');
const Review = require('../models/Review');
const RecommendationInteraction = require('../models/RecommendationInteraction');

const CUISINE_NAMES = {
  sri_lankan: 'Sri Lankan',
  indian: 'Indian',
  chinese: 'Chinese',
  western: 'Western',
  italian: 'Italian',
  thai: 'Thai',
  other: 'Authentic Homemade',
};

function normalizeCuisine(cuisine) {
  if (!cuisine) return '';
  return cuisine.toString().trim().toLowerCase().replace(/[\s-]+/g, '_');
}

function displayCuisine(cuisineKey) {
  return CUISINE_NAMES[cuisineKey] || cuisineKey || 'Homemade';
}

function parseBudgetPreference(budgetPreference, maxBudget) {
  if (typeof maxBudget === 'number' && maxBudget > 0) {
    return maxBudget;
  }
  switch (budgetPreference) {
    case 'under_500':
      return 500;
    case '500_800':
      return 800;
    case '800_1200':
      return 1200;
    case '1200_plus':
      return 2500;
    default:
      return null;
  }
}

function passesDietaryRestrictions(meal, dietaryPreference) {
  if (!dietaryPreference || dietaryPreference === 'no_preference' || dietaryPreference === 'non_vegetarian') {
    return true;
  }

  const mealText = `${meal.name || ''} ${meal.description || ''} ${meal.category || ''}`.toLowerCase();
  const allTags = [
    ...(Array.isArray(meal.dietaryTags) ? meal.dietaryTags : []),
    ...(Array.isArray(meal.dietaryInformation) ? meal.dietaryInformation : []),
  ].map((t) => (t || '').toLowerCase());

  const meatKeywords = ['chicken', 'beef', 'pork', 'mutton', 'meat', 'bacon', 'ham', 'sausage'];
  const seafoodKeywords = ['fish', 'seafood', 'prawn', 'shrimp', 'crab', 'tuna', 'squid'];
  const nonVegKeywords = [...meatKeywords, ...seafoodKeywords];

  const hasVegTag = allTags.some((t) => t.includes('veg') && !t.includes('non-veg'));
  const hasVeganTag = allTags.some((t) => t.includes('vegan'));
  const hasNonVegTag = allTags.some((t) => t.includes('non-veg') || t.includes('meat') || t.includes('chicken'));

  if (dietaryPreference === 'vegetarian') {
    if (hasNonVegTag) return false;
    for (const kw of nonVegKeywords) {
      if (mealText.includes(kw)) return false;
    }
    return true;
  }

  if (dietaryPreference === 'vegan') {
    if (hasNonVegTag) return false;
    for (const kw of [...nonVegKeywords, 'egg', 'cheese', 'milk', 'curd', 'butter', 'paneer']) {
      if (mealText.includes(kw)) return false;
    }
    if (hasVeganTag) return true;
    return hasVegTag;
  }

  if (dietaryPreference === 'pescatarian') {
    if (allTags.some((t) => t.includes('chicken') || t.includes('beef') || t.includes('pork'))) {
      return false;
    }
    for (const kw of meatKeywords) {
      if (mealText.includes(kw)) return false;
    }
    return true;
  }

  return true;
}

function scorePreferences(meal, preferences = {}) {
  let score = 0;
  const reasons = [];

  const dietary = preferences.dietaryPreference;
  const favouriteCuisines = Array.isArray(preferences.favouriteCuisines)
    ? preferences.favouriteCuisines.map(normalizeCuisine)
    : [];
  const maxBudget = parseBudgetPreference(preferences.budgetPreference, preferences.maxBudget);
  const spice = preferences.spicePreference;

  if (dietary && dietary !== 'no_preference') {
    const mealTags = [
      ...(Array.isArray(meal.dietaryTags) ? meal.dietaryTags : []),
      ...(Array.isArray(meal.dietaryInformation) ? meal.dietaryInformation : []),
    ].map((t) => t.toLowerCase());

    if (dietary === 'vegetarian' && (mealTags.some((t) => t.includes('veg')) || meal.category?.toLowerCase() === 'vegetarian')) {
      score += 35;
      reasons.push('Vegetarian');
    } else if (dietary === 'vegan' && mealTags.some((t) => t.includes('vegan'))) {
      score += 35;
      reasons.push('Vegan');
    } else if (dietary === 'pescatarian') {
      score += 25;
      reasons.push('Pescatarian-friendly');
    }
  }

  if (favouriteCuisines.length > 0) {
    const mealCuisineNorm = normalizeCuisine(meal.cuisine);
    const mealCategoryNorm = normalizeCuisine(meal.category);

    const matchesCuisine = favouriteCuisines.some((c) => c === mealCuisineNorm || mealCategoryNorm.includes(c));
    if (matchesCuisine) {
      score += 25;
      reasons.push(displayCuisine(mealCuisineNorm || meal.cuisine));
    }
  }

  if (maxBudget) {
    if (meal.price <= maxBudget) {
      score += 20;
      reasons.push('Within your budget');
    } else if (meal.price <= maxBudget * 1.15) {
      score += 5;
    } else {
      score -= 15;
    }
  }

  if (spice && spice !== 'no_preference') {
    const mealSpice = (meal.spiceLevel || 'medium').toLowerCase();
    const prefSpice = spice.toLowerCase();

    if (mealSpice === prefSpice) {
      score += 10;
      const spiceLabel = prefSpice === 'mild' ? 'Mild spice' : prefSpice === 'spicy' ? 'Spicy' : 'Medium spice';
      reasons.push(spiceLabel);
    } else if (prefSpice === 'mild' && mealSpice === 'spicy') {
      score -= 20;
    } else if (prefSpice === 'spicy' && mealSpice === 'mild') {
      score -= 5;
    }
  }

  return { score, reasons };
}

function scoreOrderHistory(meal, pastOrders = []) {
  let score = 0;
  const reasons = [];
  if (!pastOrders.length) return { score, reasons };

  const mealIdStr = meal._id.toString();
  const mealCuisineNorm = normalizeCuisine(meal.cuisine);
  const mealCategory = (meal.category || '').toLowerCase();

  let timesMealOrdered = 0;
  let orderedSameCuisine = false;
  let orderedSameCategory = false;

  for (const order of pastOrders) {
    if (!Array.isArray(order.items)) continue;
    for (const item of order.items) {
      const itemMealId = item.meal?._id ? item.meal._id.toString() : item.meal?.toString();
      if (itemMealId === mealIdStr) {
        timesMealOrdered += 1;
      }
      if (item.meal && typeof item.meal === 'object') {
        if (normalizeCuisine(item.meal.cuisine) === mealCuisineNorm) {
          orderedSameCuisine = true;
        }
        if (item.meal.category && item.meal.category.toLowerCase() === mealCategory) {
          orderedSameCategory = true;
        }
      }
    }
  }

  if (timesMealOrdered > 0) {
    score += Math.min(10, timesMealOrdered * 5);
    reasons.push('Ordered previously');
  } else if (orderedSameCuisine || orderedSameCategory) {
    score += 10;
    reasons.push('Similar to your past orders');
  }

  return { score, reasons };
}

function scoreRatings(meal, userReviews = []) {
  let score = 0;
  const reasons = [];
  if (!userReviews.length) return { score, reasons };

  const mealIdStr = meal._id.toString();
  const mealReview = userReviews.find((r) => {
    const rMealId = r.meal?._id ? r.meal._id.toString() : r.meal?.toString();
    return rMealId === mealIdStr;
  });

  if (mealReview) {
    if (mealReview.rating >= 4) {
      score += 15;
      reasons.push(`You rated this ${mealReview.rating}★`);
    } else if (mealReview.rating <= 2) {
      score -= 35;
    }
  }

  return { score, reasons };
}

function scorePopularity(meal) {
  let score = 0;
  const reasons = [];

  const rating = typeof meal.rating === 'number' ? meal.rating : 4.5;
  score += Math.round((rating / 5) * 10);

  if (rating >= 4.7) {
    reasons.push(`Top rated (${rating.toFixed(1)} ★)`);
  }

  const orderCount = meal.orderCount || 0;
  if (orderCount >= 10) {
    score += 5;
    reasons.push('Popular favourite');
  }

  return { score, reasons };
}

function enforceDiversity(rankedItems, maxPerCook = 2, totalLimit = 10) {
  const cookCounts = new Map();
  const diverse = [];
  const overflow = [];

  for (const item of rankedItems) {
    const cookId = item.meal.cook?._id
      ? item.meal.cook._id.toString()
      : (item.meal.cook || 'unknown').toString();

    const currentCount = cookCounts.get(cookId) || 0;
    if (currentCount < maxPerCook) {
      cookCounts.set(cookId, currentCount + 1);
      diverse.push(item);
    } else {
      overflow.push(item);
    }

    if (diverse.length >= totalLimit) break;
  }

  if (diverse.length < totalLimit && overflow.length > 0) {
    for (const item of overflow) {
      diverse.push(item);
      if (diverse.length >= totalLimit) break;
    }
  }

  return diverse;
}

async function getPersonalizedRecommendations(userId, limit = 10) {
  let user = null;
  let pastOrders = [];
  let userReviews = [];

  if (userId) {
    user = await User.findById(userId).lean();
    if (user) {
      [pastOrders, userReviews] = await Promise.all([
        Order.find({ customer: userId })
          .populate('items.meal', 'name cuisine category price')
          .sort({ createdAt: -1 })
          .limit(20)
          .lean(),
        Review.find({ customer: userId })
          .populate('meal', 'name cuisine category spiceLevel')
          .lean(),
      ]);
    }
  }

  const preferences = user?.preferences || {};

  const availableMeals = await Meal.find({ available: true })
    .populate('cook', 'name kitchenName profileImage rating address phone isBlocked isOnline')
    .lean();

  const validMeals = availableMeals.filter((m) => {
    if (!m.cook) return false;
    if (m.cook.isBlocked === true) return false;
    if (typeof m.price !== 'number' || m.price <= 0) return false;
    return true;
  });

  const dietaryRestrictedMeals = validMeals.filter((meal) =>
    passesDietaryRestrictions(meal, preferences.dietaryPreference)
  );

  const candidateMeals = dietaryRestrictedMeals.length > 0 ? dietaryRestrictedMeals : validMeals;

  const scoredItems = candidateMeals.map((meal) => {
    const prefResult = scorePreferences(meal, preferences);
    const orderResult = scoreOrderHistory(meal, pastOrders);
    const reviewResult = scoreRatings(meal, userReviews);
    const popResult = scorePopularity(meal);

    const totalScore =
      prefResult.score +
      orderResult.score +
      reviewResult.score +
      popResult.score;

    const uniqueReasons = Array.from(
      new Set([
        ...prefResult.reasons,
        ...orderResult.reasons,
        ...reviewResult.reasons,
        ...popResult.reasons,
      ])
    );

    if (uniqueReasons.length === 0) {
      uniqueReasons.push('Verified Home Cook');
      if (meal.cuisine) uniqueReasons.push(meal.cuisine);
      uniqueReasons.push('Freshly prepared');
    }

    return {
      meal: {
        _id: meal._id,
        id: meal._id,
        name: meal.name,
        description: meal.description,
        price: meal.price,
        category: meal.category,
        imageUrl: meal.imageUrl,
        image: meal.imageUrl,
        rating: meal.rating,
        ratingCount: meal.ratingCount || 0,
        prepTimeMinutes: meal.prepTimeMinutes,
        cuisine: meal.cuisine || 'Sri Lankan',
        spiceLevel: meal.spiceLevel || 'medium',
        dietaryInformation: meal.dietaryInformation || [],
        dietaryTags: meal.dietaryTags || [],
        cook: meal.cook,
        cookId: meal.cook?._id || meal.cook,
        cookName: meal.cook?.kitchenName || meal.cook?.name || 'Home Cook',
      },
      score: totalScore,
      reasons: uniqueReasons.slice(0, 4),
    };
  });

  scoredItems.sort((a, b) => b.score - a.score);

  const diverseRecommendations = enforceDiversity(scoredItems, 2, limit);

  return diverseRecommendations;
}

async function trackRecommendationInteraction(userId, mealId, eventType, metadata = {}) {
  if (!userId || !mealId || !eventType) {
    throw new Error('userId, mealId, and eventType are required');
  }

  const interaction = await RecommendationInteraction.create({
    user: userId,
    meal: mealId,
    eventType,
    metadata,
  });

  return interaction;
}

module.exports = {
  getPersonalizedRecommendations,
  trackRecommendationInteraction,
  passesDietaryRestrictions,
  scorePreferences,
  scoreOrderHistory,
  scoreRatings,
  scorePopularity,
};
