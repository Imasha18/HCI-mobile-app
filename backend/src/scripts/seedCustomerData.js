const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const { connectDatabase } = require('../config/db');
const User = require('../models/User');
const Meal = require('../models/Meal');

const customerEmail = process.env.SEED_CUSTOMER_EMAIL || 'customer@homebite.local';
const customerPassword = process.env.SEED_CUSTOMER_PASSWORD || 'HomeBite123!';
const cookEmail = process.env.SEED_COOK_EMAIL || 'cook@homebite.local';
const cookPassword = process.env.SEED_COOK_PASSWORD || 'HomeBite123!';

async function seed() {
  await connectDatabase();
  const [customerPasswordHash, cookPasswordHash] = await Promise.all([
    bcrypt.hash(customerPassword, 12),
    bcrypt.hash(cookPassword, 12),
  ]);

  await User.findOneAndUpdate(
    { email: customerEmail },
    { name: 'HomeBite Customer', email: customerEmail, password: customerPasswordHash, role: 'customer', emailVerified: true, address: 'Brooklyn Heights' },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  const cook = await User.findOneAndUpdate(
    { email: cookEmail },
    { name: 'Mara Kitchen', email: cookEmail, password: cookPasswordHash, role: 'cook', emailVerified: true, address: 'Brooklyn Heights' },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  const meals = [
    { name: 'Sunday Roast', category: 'Lunch', price: 18, description: 'Slow-roasted comfort food with seasonal vegetables.', rating: 4.9, prepTimeMinutes: 45, ingredients: ['beef', 'potatoes', 'carrots'], dietaryInformation: [], cook: cook._id },
    { name: 'Coconut Curry', category: 'Dinner', price: 15, description: 'Creamy coconut curry with fragrant herbs and rice.', rating: 4.8, prepTimeMinutes: 30, ingredients: ['coconut', 'vegetables', 'rice'], dietaryInformation: ['vegetarian'], cook: cook._id },
    { name: 'Lemon Olive Cake', category: 'Healthy', price: 9, description: 'Bright lemon cake finished with extra virgin olive oil.', rating: 4.7, prepTimeMinutes: 25, ingredients: ['lemon', 'olive oil', 'flour'], dietaryInformation: ['vegetarian'], cook: cook._id },
  ];

  for (const meal of meals) {
    await Meal.findOneAndUpdate(
      { name: meal.name, cook: cook._id },
      meal,
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
  }

  console.log(`Seeded customer ${customerEmail}, cook ${cookEmail}, and ${meals.length} meals.`);
  console.log(`Customer login password: ${customerPassword}`);
}

seed()
  .catch((error) => {
    console.error('Customer seed failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });