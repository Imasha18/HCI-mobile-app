const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { connectDatabase } = require('../config/db');
const User = require('../models/User');
const Meal = require('../models/Meal');
const Order = require('../models/Order');
const Earning = require('../models/Earning');

const cookEmail = process.env.SEED_COOK_EMAIL || 'cook@homebite.com';
const cookPassword = process.env.SEED_COOK_PASSWORD || 'cook123';

async function seedCook() {
  await connectDatabase();
  console.log('Connected to database for cook seeding...');

  const passwordHash = await bcrypt.hash(cookPassword, 12);

  // Create or update cook
  const cook = await User.findOneAndUpdate(
    { email: cookEmail },
    {
      name: 'Chef Sarah Jay',
      email: cookEmail,
      password: passwordHash,
      role: 'cook',
      phone: '+1 555-019-2834',
      address: '742 Evergreen Terrace, Brooklyn, NY',
      kitchenName: "Sarah's Gourmet Kitchen",
      profileImage: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=500&q=80',
      isVerified: true,
      rating: 4.9,
      isOnline: true,
      emailVerified: true,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // Also ensure customer exists for order links
  const customer = await User.findOneAndUpdate(
    { email: 'customer@homebite.com' },
    {
      name: 'Michael Scott',
      email: 'customer@homebite.com',
      password: passwordHash,
      role: 'customer',
      phone: '+1 555-012-4455',
      address: '1725 Slough Avenue, Brooklyn, NY',
      emailVerified: true,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // Seed meals across Rice, Curry, Kottu, Healthy
  const mealsData = [
    {
      name: 'Fragrant Yellow Rice & Chicken',
      description: 'Basmati rice cooked in turmeric ghee served with aromatic spiced roast chicken and spicy sambal.',
      category: 'Rice',
      price: 16.50,
      prepTimeMinutes: 25,
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
      ingredients: ['Basmati Rice', 'Chicken', 'Turmeric', 'Ghee', 'Cardamom', 'Onion'],
      dietaryInformation: ['Halal', 'Gluten-Free'],
      available: true,
      rating: 4.9,
      cook: cook._id,
    },
    {
      name: 'Creamy Coconut Fish Curry',
      description: 'Fresh local fish simmered slowly in rich coconut milk with cinnamon, lemongrass, and green chili.',
      category: 'Curry',
      price: 18.00,
      prepTimeMinutes: 30,
      imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&q=80',
      ingredients: ['Fish Fillet', 'Coconut Milk', 'Lemongrass', 'Curry Leaves', 'Garlic', 'Chili'],
      dietaryInformation: ['Dairy-Free', 'High Protein'],
      available: true,
      rating: 4.8,
      cook: cook._id,
    },
    {
      name: 'Special Chicken Kottu Roti',
      description: 'Shredded godamba flatbread stir-fried vigorously with egg, chicken, fresh vegetables, and spicy curry sauce.',
      category: 'Kottu',
      price: 14.50,
      prepTimeMinutes: 20,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80',
      ingredients: ['Godamba Roti', 'Shredded Chicken', 'Eggs', 'Cabbage', 'Carrots', 'Curry Sauce'],
      dietaryInformation: ['Contains Gluten', 'Spicy'],
      available: true,
      rating: 5.0,
      cook: cook._id,
    },
    {
      name: 'Roasted Beet & Quinoa Bowl',
      description: 'Nutrient-rich bowl with organic roasted beets, quinoa, avocado slices, chickpeas, and lemon tahini dressing.',
      category: 'Healthy',
      price: 13.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
      ingredients: ['Quinoa', 'Beets', 'Chickpeas', 'Avocado', 'Tahini', 'Baby Spinach'],
      dietaryInformation: ['Vegan', 'Gluten-Free', 'Organic'],
      available: true,
      rating: 4.7,
      cook: cook._id,
    },
    {
      name: 'Authentic Cheese & Egg Kottu',
      description: 'Wok-tossed chopped roti with melted mozzarella cheese, eggs, onions, and mild curry essence.',
      category: 'Kottu',
      price: 15.00,
      prepTimeMinutes: 20,
      imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600&q=80',
      ingredients: ['Roti', 'Mozzarella Cheese', 'Eggs', 'Leeks', 'Green Chilies'],
      dietaryInformation: ['Vegetarian'],
      available: true,
      rating: 4.8,
      cook: cook._id,
    },
  ];

  const seededMeals = [];
  for (const m of mealsData) {
    const meal = await Meal.findOneAndUpdate(
      { name: m.name, cook: cook._id },
      m,
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    seededMeals.push(meal);
  }

  // Seed incoming and active orders
  const ordersData = [
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[0]._id, name: seededMeals[0].name, quantity: 2, price: seededMeals[0].price },
        { meal: seededMeals[2]._id, name: seededMeals[2].name, quantity: 1, price: seededMeals[2].price },
      ],
      total: 47.50,
      paymentStatus: 'paid',
      status: 'Order Received',
      deliveryAddress: '245 Henry St, Apt 4B, Brooklyn, NY',
      orderNotes: 'Please ring bell 4B upon arrival. Extra spicy on the side.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[1]._id, name: seededMeals[1].name, quantity: 1, price: seededMeals[1].price },
      ],
      total: 18.00,
      paymentStatus: 'paid',
      status: 'Preparing',
      deliveryAddress: '112 Remsen St, Brooklyn, NY',
      orderNotes: 'No coriander please.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[3]._id, name: seededMeals[3].name, quantity: 2, price: seededMeals[3].price },
      ],
      total: 26.00,
      paymentStatus: 'paid',
      status: 'Ready For Pickup',
      deliveryAddress: '55 Clark St, Brooklyn, NY',
      orderNotes: 'Leave with doorman.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[0]._id, name: seededMeals[0].name, quantity: 3, price: seededMeals[0].price },
      ],
      total: 49.50,
      paymentStatus: 'paid',
      status: 'Completed',
      deliveryAddress: '88 Montague St, Brooklyn, NY',
    },
  ];

  for (const o of ordersData) {
    const existing = await Order.findOne({
      customer: o.customer,
      cook: o.cook,
      deliveryAddress: o.deliveryAddress,
      total: o.total,
    });
    if (!existing) {
      await Order.create(o);
    }
  }

  // Seed sample earnings for past week
  const pastDays = [0, 1, 2, 3, 4, 5, 6];
  const sampleAmounts = [142.50, 98.00, 175.50, 120.00, 210.00, 185.00, 160.00];

  for (let i = 0; i < pastDays.length; i++) {
    const d = new Date();
    d.setDate(d.getDate() - pastDays[i]);
    const count = await Earning.countDocuments({
      cookId: cook._id,
      date: {
        $gte: new Date(d.getFullYear(), d.getMonth(), d.getDate()),
        $lt: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1),
      },
    });
    if (count === 0) {
      await Earning.create({
        cookId: cook._id,
        amount: sampleAmounts[i],
        date: d,
      });
    }
  }

  console.log('Successfully seeded cook, meals, orders, and earnings!');
  console.log(`Cook login: ${cookEmail} | Password: ${cookPassword}`);
}

seedCook()
  .catch((err) => {
    console.error('Seed cook error:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
