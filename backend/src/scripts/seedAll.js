const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { connectDatabase } = require('../config/db');
const User = require('../models/User');
const Meal = require('../models/Meal');
const Order = require('../models/Order');
const Delivery = require('../models/Delivery');
const Earning = require('../models/Earning');
const Notification = require('../models/Notification');
const Complaint = require('../models/Complaint');

async function seedAll() {
  console.log('--- Connecting to MongoDB Atlas for Full 3-Module Integration Seeding ---');
  await connectDatabase();

  const defaultPassword = 'password123';
  const passwordHash = await bcrypt.hash(defaultPassword, 12);
  const cookHash = await bcrypt.hash('cook123', 12);
  const customerHash = await bcrypt.hash('customer123', 12);
  const riderHash = await bcrypt.hash('rider123', 12);
  const adminHash = await bcrypt.hash('admin123', 12);

  // 0. Seed Administrator
  console.log('0. Seeding System Administrator...');
  const admin = await User.findOneAndUpdate(
    { email: 'admin@homebite.com' },
    {
      name: 'System Administrator',
      email: 'admin@homebite.com',
      password: adminHash,
      role: 'admin',
      phone: '+94 77 000 0001',
      address: 'HomeBite HQ, Colombo 03, Sri Lanka',
      profileImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&q=80',
      isVerified: true,
      emailVerified: true,
      verificationStatus: 'approved',
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // Seed pending cook for verification queue
  await User.findOneAndUpdate(
    { email: 'pendingcook@homebite.com' },
    {
      name: 'Priyani Fernando',
      email: 'pendingcook@homebite.com',
      password: cookHash,
      role: 'cook',
      phone: '+94 77 888 1234',
      address: '32 Temple Road, Negombo',
      kitchenName: "Priyani's Heritage Spices",
      profileImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&q=80',
      isVerified: false,
      verificationStatus: 'pending',
      rating: 5.0,
      emailVerified: true,
      verificationDocuments: [
        { title: 'Food Hygiene Certificate', documentUrl: 'https://example.com/hygiene-cert.pdf', status: 'pending' },
        { title: 'National Identity Card (NIC)', documentUrl: 'https://example.com/nic-front.jpg', status: 'pending' },
      ],
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // Seed pending rider for verification queue
  await User.findOneAndUpdate(
    { email: 'pendingrider@homebite.com' },
    {
      name: 'Kasun Wickramasinghe',
      email: 'pendingrider@homebite.com',
      password: riderHash,
      role: 'rider',
      phone: '+94 71 444 7890',
      address: '15 Highlevel Road, Nugegoda',
      profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80',
      isVerified: false,
      verificationStatus: 'pending',
      rating: 5.0,
      emailVerified: true,
      vehicleDetails: {
        type: 'Motorbike',
        model: 'Yamaha FZ 150',
        plateNumber: 'WP CAR-1029',
      },
      verificationDocuments: [
        { title: 'Driving License (Front & Back)', documentUrl: 'https://example.com/license.pdf', status: 'pending' },
        { title: 'Vehicle Revenue License 2026', documentUrl: 'https://example.com/revenue-license.pdf', status: 'pending' },
      ],
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 1. Seed Home Cook (Supplier)
  console.log('1. Seeding Home Cook...');
  const cook = await User.findOneAndUpdate(
    { email: 'cook@homebite.com' },
    {
      name: 'Chef Sunethra Silva',
      email: 'cook@homebite.com',
      password: cookHash,
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

  // Also support mara kitchen login
  await User.findOneAndUpdate(
    { email: 'cook@homebite.local' },
    {
      name: 'Mara Kitchen',
      email: 'cook@homebite.local',
      password: passwordHash,
      role: 'cook',
      kitchenName: 'Mara Kitchen',
      phone: '+94 77 345 6789',
      address: '12 Temple Trees Avenue, Colombo 03',
      profileImage: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=500&q=80',
      isVerified: true,
      rating: 4.8,
      isOnline: true,
      emailVerified: true,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 2. Seed Customer (Home Bite)
  console.log('2. Seeding Customer...');
  const customer = await User.findOneAndUpdate(
    { email: 'customer@homebite.com' },
    {
      name: 'Nimal Jayasuriya',
      email: 'customer@homebite.com',
      password: customerHash,
      role: 'customer',
      phone: '+94 71 890 1234',
      address: '18 Flower Road, Colombo 07, Sri Lanka',
      emailVerified: true,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 3. Seed Delivery Rider
  console.log('3. Seeding Delivery Rider...');
  const rider = await User.findOneAndUpdate(
    { email: 'rider@homebite.com' },
    {
      name: 'Kamal Perera',
      email: 'rider@homebite.com',
      password: riderHash,
      role: 'rider',
      phone: '+94 77 555 9876',
      address: '24/1 Baseline Road, Colombo 09, Sri Lanka',
      profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      isVerified: true,
      rating: 4.9,
      isOnline: true,
      emailVerified: true,
      vehicleDetails: {
        type: 'Motorbike',
        model: 'Honda Dio 110cc',
        plateNumber: 'WP BZ-4892',
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 4. Seed Foods (Added by Home Cook)
  console.log('4. Seeding Sri Lankan Foods added by Home Cook...');
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

  // 5. Seed Customer Order
  console.log('5. Seeding Customer Orders connecting Home Cook & Customer...');
  const order1 = await Order.findOneAndUpdate(
    {
      customer: customer._id,
      cook: cook._id,
      deliveryAddress: '18 Flower Road, Colombo 07, Sri Lanka',
      total: 2700.00,
    },
    {
      customer: customer._id,
      cook: cook._id,
      items: [
        { meal: seededMeals[0]._id, name: seededMeals[0].name, quantity: 1, price: seededMeals[0].price },
        { meal: seededMeals[2]._id, name: seededMeals[2].name, quantity: 1, price: seededMeals[2].price },
      ],
      total: 2700.00,
      paymentStatus: 'paid',
      status: 'Order Received',
      deliveryAddress: '18 Flower Road, Colombo 07, Sri Lanka',
      orderNotes: 'Please ring the doorbell upon arrival.',
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 6. Seed Available Delivery for Delivery Rider
  console.log('6. Seeding Available Delivery for Delivery Rider...');
  await Delivery.findOneAndUpdate(
    { orderId: order1._id },
    {
      orderId: order1._id,
      order: order1._id,
      cookId: cook._id,
      customerId: customer._id,
      pickupLocation: {
        address: cook.address,
        latitude: 6.9034,
        longitude: 79.8546,
      },
      deliveryLocation: {
        address: customer.address,
        latitude: 6.9128,
        longitude: 79.8653,
      },
      status: 'AVAILABLE',
      deliveryFee: 450.0,
      distanceKm: 3.8,
      estimatedMinutes: 22,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 7. Seed In-Transit / Active Delivery for Kamal
  const order2 = await Order.findOneAndUpdate(
    {
      customer: customer._id,
      cook: cook._id,
      deliveryAddress: '55 Nawala Road, Rajagiriya, Colombo',
      total: 1900.00,
    },
    {
      customer: customer._id,
      cook: cook._id,
      rider: rider._id,
      items: [
        { meal: seededMeals[1]._id, name: seededMeals[1].name, quantity: 1, price: seededMeals[1].price },
        { meal: seededMeals[2]._id, name: seededMeals[2].name, quantity: 1, price: seededMeals[2].price },
      ],
      total: 1900.00,
      paymentStatus: 'paid',
      status: 'Out for Delivery',
      deliveryAddress: '55 Nawala Road, Rajagiriya, Colombo',
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  await Delivery.findOneAndUpdate(
    { orderId: order2._id },
    {
      orderId: order2._id,
      order: order2._id,
      riderId: rider._id,
      rider: rider._id,
      cookId: cook._id,
      customerId: customer._id,
      pickupLocation: {
        address: cook.address,
        latitude: 6.9034,
        longitude: 79.8546,
      },
      deliveryLocation: {
        address: '55 Nawala Road, Rajagiriya, Colombo',
        latitude: 6.9056,
        longitude: 79.8924,
      },
      status: 'IN_TRANSIT',
      deliveryFee: 500.0,
      distanceKm: 5.1,
      estimatedMinutes: 25,
      pickedUpAt: new Date(Date.now() - 15 * 60000),
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  // 8. Seed Complaints for Admin moderation
  console.log('8. Seeding Complaints for Admin moderation...');
  await Complaint.findOneAndUpdate(
    { subject: 'Late delivery issue' },
    {
      user: customer._id,
      order: order1._id,
      subject: 'Late delivery issue',
      description: 'The driver arrived 20 minutes past the estimated arrival time, but the food was still warm.',
      status: 'pending',
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  await Complaint.findOneAndUpdate(
    { subject: 'Missing item in package' },
    {
      user: customer._id,
      order: order2._id,
      subject: 'Missing item in package',
      description: 'Ordered two curry dishes but only one portion of cutlery was provided.',
      status: 'pending',
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  console.log('\n======================================================');
  console.log('✅ ALL FOUR MODULES SUCCESSFULLY SEEDED & INTEGRATED!');
  console.log('======================================================');
  console.log('0. SYSTEM ADMINISTRATOR:');
  console.log(`   Email: ${admin.email} | Password: admin123`);
  console.log('1. HOME COOK:');
  console.log(`   Email: ${cook.email} | Password: cook123`);
  console.log(`   Kitchen: ${cook.kitchenName} (${seededMeals.length} Sri Lankan dishes live)`);
  console.log('2. CUSTOMER (HOME BITE):');
  console.log(`   Email: ${customer.email} | Password: customer123`);
  console.log(`   Can view dishes from ${cook.kitchenName} and place orders.`);
  console.log('3. DELIVERY RIDER:');
  console.log(`   Email: ${rider.email} | Password: rider123`);
  console.log(`   Can view and accept delivery requests directly in Delivery Requests screen.`);
  console.log('======================================================\n');
}

seedAll()
  .catch((err) => {
    console.error('Seeding failed:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
