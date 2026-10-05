const {
  passesDietaryRestrictions,
  scorePreferences,
  scoreOrderHistory,
  scoreRatings,
  scorePopularity,
} = require('../services/recommendationService');

describe('AI Recommendation Engine Unit Tests', () => {
  describe('Dietary Restrictions Filter', () => {
    const vegMeal = {
      name: 'Vegetable Rice & Curry',
      description: 'Fresh local vegetables with dhal and coconut milk',
      dietaryTags: ['vegetarian'],
      dietaryInformation: ['Vegetarian'],
      category: 'Vegetarian',
    };

    const chickenMeal = {
      name: 'Chicken Kottu',
      description: 'Shredded rotti with spicy chicken curry',
      dietaryTags: ['spicy'],
      dietaryInformation: ['Spicy'],
      category: 'Kottu',
    };

    const fishMeal = {
      name: 'Fish Ambulthiyal',
      description: 'Traditional sour fish curry',
      dietaryTags: ['pescatarian'],
      category: 'Curry',
    };

    test('Vegetarian user is strictly protected from meat meals', () => {
      expect(passesDietaryRestrictions(vegMeal, 'vegetarian')).toBe(true);
      expect(passesDietaryRestrictions(chickenMeal, 'vegetarian')).toBe(false);
      expect(passesDietaryRestrictions(fishMeal, 'vegetarian')).toBe(false);
    });

    test('Vegan user is strictly protected from animal products', () => {
      const veganMeal = {
        name: 'Polos Curry',
        description: 'Tender baby jackfruit curry',
        dietaryTags: ['vegan'],
        dietaryInformation: ['Vegan'],
      };
      const dairyMeal = {
        name: 'Paneer Butter Masala',
        description: 'Rich cottage cheese in curd and butter gravy',
        dietaryTags: ['vegetarian'],
      };
      expect(passesDietaryRestrictions(veganMeal, 'vegan')).toBe(true);
      expect(passesDietaryRestrictions(dairyMeal, 'vegan')).toBe(false);
      expect(passesDietaryRestrictions(chickenMeal, 'vegan')).toBe(false);
    });

    test('Pescatarian user allows fish and vegetarian meals, forbids chicken/meat', () => {
      expect(passesDietaryRestrictions(fishMeal, 'pescatarian')).toBe(true);
      expect(passesDietaryRestrictions(vegMeal, 'pescatarian')).toBe(true);
      expect(passesDietaryRestrictions(chickenMeal, 'pescatarian')).toBe(false);
    });

    test('Non-vegetarian or no_preference allows all meals', () => {
      expect(passesDietaryRestrictions(chickenMeal, 'non_vegetarian')).toBe(true);
      expect(passesDietaryRestrictions(chickenMeal, 'no_preference')).toBe(true);
      expect(passesDietaryRestrictions(vegMeal, 'no_preference')).toBe(true);
    });
  });

  describe('Preferences Scoring', () => {
    test('Grants +35 points for matching dietary preference', () => {
      const meal = {
        name: 'Dhal Curry',
        price: 350,
        dietaryTags: ['vegetarian'],
        cuisine: 'Sri Lankan',
        spiceLevel: 'mild',
      };
      const result = scorePreferences(meal, { dietaryPreference: 'vegetarian' });
      expect(result.score).toBeGreaterThanOrEqual(35);
      expect(result.reasons).toContain('Vegetarian');
    });

    test('Grants +25 points for favourite cuisine match', () => {
      const meal = {
        name: 'Vegetable Biryani',
        price: 600,
        cuisine: 'Indian',
      };
      const result = scorePreferences(meal, { favouriteCuisines: ['indian'] });
      expect(result.score).toBe(25);
      expect(result.reasons).toContain('Indian');
    });

    test('Grants +20 points when within budget, penalizes if far exceeding budget', () => {
      const affordableMeal = { name: 'Roti', price: 400 };
      const expensiveMeal = { name: 'Seafood Platter', price: 2000 };

      const resAffordable = scorePreferences(affordableMeal, { maxBudget: 800 });
      const resExpensive = scorePreferences(expensiveMeal, { maxBudget: 800 });

      expect(resAffordable.score).toBe(20);
      expect(resAffordable.reasons).toContain('Within your budget');
      expect(resExpensive.score).toBe(-15);
    });

    test('Rewards matching spice level and penalizes high spice for mild eaters', () => {
      const mildMeal = { name: 'Milk Rice', spiceLevel: 'mild' };
      const spicyMeal = { name: 'Spicy Devilled Chicken', spiceLevel: 'spicy' };

      const resMild = scorePreferences(mildMeal, { spicePreference: 'mild' });
      const resSpicyForMildEater = scorePreferences(spicyMeal, { spicePreference: 'mild' });

      expect(resMild.score).toBe(10);
      expect(resMild.reasons).toContain('Mild spice');
      expect(resSpicyForMildEater.score).toBe(-20);
    });
  });

  describe('Past Orders & Ratings Scoring', () => {
    const meal = {
      _id: 'meal_123',
      name: 'Pol Rotti',
      cuisine: 'Sri Lankan',
      category: 'Breakfast',
    };

    test('Scores +10 if user previously ordered meal of same cuisine', () => {
      const pastOrders = [
        {
          items: [
            {
              meal: { _id: 'other_meal', cuisine: 'Sri Lankan', category: 'Dinner' },
            },
          ],
        },
      ];
      const result = scoreOrderHistory(meal, pastOrders);
      expect(result.score).toBe(10);
      expect(result.reasons).toContain('Similar to your past orders');
    });

    test('Increases score for 5-star reviewed meals and heavily penalizes disliked meals', () => {
      const highReviews = [{ meal: 'meal_123', rating: 5 }];
      const lowReviews = [{ meal: 'meal_123', rating: 1 }];

      const resHigh = scoreRatings(meal, highReviews);
      const resLow = scoreRatings(meal, lowReviews);

      expect(resHigh.score).toBe(15);
      expect(resHigh.reasons).toContain('You rated this 5★');
      expect(resLow.score).toBe(-35);
    });
  });

  describe('Popularity Scoring', () => {
    test('Calculates score based on 5-star rating scale', () => {
      const topMeal = { rating: 4.9, orderCount: 25 };
      const res = scorePopularity(topMeal);
      expect(res.score).toBeGreaterThanOrEqual(14);
      expect(res.reasons).toContain('Top rated (4.9 ★)');
      expect(res.reasons).toContain('Popular favourite');
    });
  });

  describe('Recommendation API Security & Validation', () => {
    const request = require('supertest');
    const app = require('../app');
    const jwt = require('jsonwebtoken');
    const environment = require('../config/environment');

    test('Rejects unauthenticated requests to recommendations endpoint', async () => {
      const response = await request(app).get('/api/recommendations/meals');
      expect(response.statusCode).toBe(401);
      expect(response.body.message).toBe('Authentication required');
    });

    test('Rejects unauthenticated requests to interaction tracking endpoint', async () => {
      const response = await request(app)
        .post('/api/recommendations/track')
        .send({ mealId: '507f191e810c19729de860ea', eventType: 'meal_clicked' });
      expect(response.statusCode).toBe(401);
    });

    test('Forbids non-customer roles from customer recommendation endpoint', async () => {
      const cookToken = jwt.sign({ id: '507f191e810c19729de860ea', role: 'cook' }, environment.jwtSecret);
      const response = await request(app)
        .get('/api/recommendations/meals')
        .set('Authorization', `Bearer ${cookToken}`);
      expect(response.statusCode).toBe(403);
    });

    test('Validates required fields for tracking interaction', async () => {
      const customerToken = jwt.sign({ id: '507f191e810c19729de860ea', role: 'customer' }, environment.jwtSecret);
      const response = await request(app)
        .post('/api/recommendations/track')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ eventType: 'meal_clicked' });
      expect(response.statusCode).toBe(400);
      expect(response.body.message).toContain('mealId and eventType are required');
    });
  });
});
