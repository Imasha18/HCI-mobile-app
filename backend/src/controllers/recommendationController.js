const User = require('../models/User');
const recommendationService = require('../services/recommendationService');
const { sendSuccess } = require('../utils/apiResponse');

async function getRecommendations(req, res) {
  try {
    const userId = req.user ? req.user.id : null;
    const limit = Math.min(20, Math.max(1, parseInt(req.query.limit, 10) || 10));

    const recommendations = await recommendationService.getPersonalizedRecommendations(userId, limit);

    return sendSuccess(res, { recommendations }, 'Personalized recommendations retrieved successfully');
  } catch (error) {
    console.error('Error fetching recommendations:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve recommendations',
    });
  }
}

async function trackInteraction(req, res) {
  try {
    const userId = req.user.id;
    const { mealId, eventType, metadata } = req.body;

    if (!mealId || !eventType) {
      return res.status(400).json({
        success: false,
        message: 'mealId and eventType are required',
      });
    }

    const validEvents = [
      'recommendation_shown',
      'meal_clicked',
      'added_to_cart',
      'ordered',
      'rated',
      'skipped',
    ];
    if (!validEvents.includes(eventType)) {
      return res.status(400).json({
        success: false,
        message: `Invalid eventType. Allowed: ${validEvents.join(', ')}`,
      });
    }

    await recommendationService.trackRecommendationInteraction(userId, mealId, eventType, metadata);

    return sendSuccess(res, { tracked: true }, 'Interaction recorded successfully');
  } catch (error) {
    console.error('Error tracking interaction:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to record interaction',
    });
  }
}

async function getCustomerPreferences(req, res) {
  try {
    const user = await User.findById(req.user.id).select('preferences');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const defaultPreferences = {
      dietaryPreference: 'no_preference',
      favouriteCuisines: [],
      budgetPreference: 'no_preference',
      spicePreference: 'no_preference',
      maxBudget: null,
      onboardingCompleted: false,
    };

    const preferences = user.preferences
      ? { ...defaultPreferences, ...user.preferences.toObject?.() || user.preferences }
      : defaultPreferences;

    return sendSuccess(res, { preferences });
  } catch (error) {
    console.error('Error fetching preferences:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve preferences',
    });
  }
}

async function updateCustomerPreferences(req, res) {
  try {
    const {
      dietaryPreference,
      favouriteCuisines,
      budgetPreference,
      spicePreference,
      maxBudget,
      onboardingCompleted,
    } = req.body;

    const updates = {};
    if (dietaryPreference !== undefined) updates['preferences.dietaryPreference'] = dietaryPreference;
    if (Array.isArray(favouriteCuisines)) updates['preferences.favouriteCuisines'] = favouriteCuisines;
    if (budgetPreference !== undefined) updates['preferences.budgetPreference'] = budgetPreference;
    if (spicePreference !== undefined) updates['preferences.spicePreference'] = spicePreference;
    if (maxBudget !== undefined) updates['preferences.maxBudget'] = maxBudget;
    if (onboardingCompleted !== undefined) updates['preferences.onboardingCompleted'] = onboardingCompleted;

    if (budgetPreference && maxBudget === undefined) {
      if (budgetPreference === 'under_500') updates['preferences.maxBudget'] = 500;
      else if (budgetPreference === '500_800') updates['preferences.maxBudget'] = 800;
      else if (budgetPreference === '800_1200') updates['preferences.maxBudget'] = 1200;
      else if (budgetPreference === '1200_plus') updates['preferences.maxBudget'] = 2500;
      else if (budgetPreference === 'no_preference') updates['preferences.maxBudget'] = null;
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updates },
      { new: true }
    ).select('preferences');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return sendSuccess(res, { preferences: user.preferences }, 'Preferences updated successfully');
  } catch (error) {
    console.error('Error updating preferences:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update preferences',
    });
  }
}

module.exports = {
  getRecommendations,
  trackInteraction,
  getCustomerPreferences,
  updateCustomerPreferences,
};
