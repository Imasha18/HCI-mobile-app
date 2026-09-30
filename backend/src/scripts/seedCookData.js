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
      name: 'Chef Sunethra Silva',
      email: cookEmail,
      password: passwordHash,
      role: 'cook',
      phone: '+94 77 234 5678',
      address: '45/2 Galle Road, Colombo 03, Sri Lanka',
      kitchenName: "Amma's Spice Kitchen",
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
      name: 'Nimal Jayasuriya',
      email: 'customer@homebite.com',
      password: passwordHash,
      role: 'customer',
      phone: '+94 71 890 1234',
      address: '18 Flower Road, Colombo 07, Sri Lanka',
      emailVerified: true,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // Seed Sri Lankan meals across Rice, Curry, Kottu, Healthy
  const mealsData = [
    {
      name: 'Authentic Sri Lankan Lamprais',
      description: 'Fragrant samba rice cooked in rich stock, served with mixed spiced chicken curry, frikkadels, seeni sambol, and ash plantain wrapped and baked in a fresh banana leaf.',
      category: 'Rice',
      price: 1450.00,
      prepTimeMinutes: 30,
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
      ingredients: ['Samba Rice', 'Spiced Chicken', 'Frikkadels', 'Seeni Sambol', 'Ash Plantain', 'Banana Leaf'],
      dietaryInformation: ['Halal', 'Traditional'],
      available: true,
      rating: 4.9,
      cook: cook._id,
    },
    {
      name: 'Polos & Dhal Village Curry Plate',
      description: 'Slow-cooked tender young jackfruit (polos) curry in thick roasted curry powder and coconut milk, accompanied by creamy tempered red lentil dhal.',
      category: 'Curry',
      price: 750.00,
      prepTimeMinutes: 25,
      imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&q=80',
      ingredients: ['Baby Jackfruit (Polos)', 'Red Lentils (Dhal)', 'Coconut Milk', 'Curry Leaves', 'Rampe', 'Garlic'],
      dietaryInformation: ['Vegan', 'Gluten-Free'],
      available: true,
      rating: 4.8,
      cook: cook._id,
    },
    {
      name: 'Spicy Chicken Cheese Kottu',
      description: 'Fresh godamba roti sliced and tossed vigorously on hot griddle with succulent spiced chicken, scrambled farm eggs, melted cheese, and aromatic gravy.',
      category: 'Kottu',
      price: 1250.00,
      prepTimeMinutes: 20,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80',
      ingredients: ['Godamba Roti', 'Shredded Roast Chicken', 'Cheese', 'Eggs', 'Leeks', 'Sri Lankan Spices'],
      dietaryInformation: ['Halal', 'Spicy'],
      available: true,
      rating: 5.0,
      cook: cook._id,
    },
    {
      name: 'Red Rice & Gotukola Sambol Bowl',
      description: 'Traditional Sri Lankan organic red raw rice served with freshly chopped pennywort (gotukola) coconut sambol, tempered dhal, and boiled farm egg.',
      category: 'Healthy',
      price: 650.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
      ingredients: ['Red Raw Rice', 'Gotukola', 'Fresh Grated Coconut', 'Red Onion', 'Lime Juice', 'Boiled Egg'],
      dietaryInformation: ['Healthy', 'Vegetarian', 'High Fiber'],
      available: true,
      rating: 4.7,
      cook: cook._id,
    },
    {
      name: 'Jaffna Style Lagoon Crab Curry',
      description: 'Fresh lagoon crabs simmered in authentic Jaffna roasted curry powder, tamarind pulp, thick coconut milk, and fragrant murunga leaves.',
      category: 'Curry',
      price: 1850.00,
      prepTimeMinutes: 35,
      imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600&q=80',
      ingredients: ['Fresh Lagoon Crab', 'Jaffna Curry Powder', 'Coconut Milk', 'Tamarind', 'Murunga Leaves'],
      dietaryInformation: ['Spicy', 'Seafood', 'Gluten-Free'],
      available: true,
      rating: 4.9,
      cook: cook._id,
    },
    {
      name: 'Authentic Roast Paan Kottu',
      description: 'Crispy roasted Sri Lankan bread (roast paan) chopped and stir-fried with farm eggs, green chillies, rich curry gravy, and melted cheese.',
      category: 'Kottu',
      price: 950.00,
      prepTimeMinutes: 20,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80',
      ingredients: ['Roast Paan', 'Farm Eggs', 'Green Chillies', 'Curry Gravy', 'Onions'],
      dietaryInformation: ['Spicy', 'Vegetarian'],
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

  // Seed incoming and active Sri Lankan orders
  const ordersData = [
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[2]._id, name: seededMeals[2].name, quantity: 2, price: seededMeals[2].price },
        { meal: seededMeals[1]._id, name: seededMeals[1].name, quantity: 1, price: seededMeals[1].price },
      ],
      total: 3250.00,
      paymentStatus: 'paid',
      status: 'Order Received',
      deliveryAddress: '88 High Level Road, Nugegoda, Colombo',
      orderNotes: 'Please add extra kochchi sambol and chili pieces on the side.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[0]._id, name: seededMeals[0].name, quantity: 2, price: seededMeals[0].price },
      ],
      total: 2900.00,
      paymentStatus: 'paid',
      status: 'Preparing',
      deliveryAddress: '14/3 Havelock Road, Colombo 05',
      orderNotes: 'Extra seeni sambol if possible please.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[3]._id, name: seededMeals[3].name, quantity: 2, price: seededMeals[3].price },
        { meal: seededMeals[5]._id, name: seededMeals[5].name, quantity: 1, price: seededMeals[5].price },
      ],
      total: 2250.00,
      paymentStatus: 'paid',
      status: 'Ready For Pickup',
      deliveryAddress: '55 Nawala Road, Rajagiriya, Colombo',
      orderNotes: 'Hand over to HomeBite delivery rider at gate.',
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[4]._id, name: seededMeals[4].name, quantity: 1, price: seededMeals[4].price },
        { meal: seededMeals[3]._id, name: seededMeals[3].name, quantity: 2, price: seededMeals[3].price },
      ],
      total: 3150.00,
      paymentStatus: 'paid',
      status: 'Completed',
      deliveryAddress: '102 Ward Place, Colombo 07',
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

  // Seed sample daily earnings in Sri Lankan Rupees (Rs.) for past week
  const pastDays = [0, 1, 2, 3, 4, 5, 6];
  const sampleAmounts = [14250.00, 9800.00, 17550.00, 12000.00, 21000.00, 18500.00, 16000.00];

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

  console.log('Successfully seeded Sri Lankan cook, meals, orders, and earnings in Rs. (LKR)!');
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
