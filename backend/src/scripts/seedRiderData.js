const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { connectDatabase } = require('../config/db');
const User = require('../models/User');
const Order = require('../models/Order');
const Delivery = require('../models/Delivery');
const Earning = require('../models/Earning');

const riderEmail = process.env.SEED_RIDER_EMAIL || 'rider@homebite.com';
const riderPassword = process.env.SEED_RIDER_PASSWORD || 'rider123';

async function seedRider() {
  await connectDatabase();
  console.log('Connected to database for rider seeding...');

  const passwordHash = await bcrypt.hash(riderPassword, 12);

  // 1. Create or update rider user
  const rider = await User.findOneAndUpdate(
    { email: riderEmail },
    {
      name: 'Kamal Perera',
      email: riderEmail,
      password: passwordHash,
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

  // 2. Find cooks and customers for linking
  const cook = await User.findOne({ role: 'cook' });
  const customer = await User.findOne({ role: 'customer' });

  // 3. Find or seed an order for delivery
  let orders = await Order.find({}).limit(5);

  // 4. Seed available deliveries
  if (orders.length > 0 && cook && customer) {
    const existingAvailable = await Delivery.findOne({ status: 'AVAILABLE' });
    if (!existingAvailable) {
      await Delivery.create({
        orderId: orders[0]._id,
        order: orders[0]._id,
        cookId: cook._id,
        customerId: customer._id,
        pickupLocation: {
          address: cook.address || '45/2 Galle Road, Colombo 03, Sri Lanka',
          latitude: 6.9034,
          longitude: 79.8546,
        },
        deliveryLocation: {
          address: customer.address || '18 Flower Road, Colombo 07, Sri Lanka',
          latitude: 6.9128,
          longitude: 79.8653,
        },
        status: 'AVAILABLE',
        deliveryFee: 450.0,
        distanceKm: 4.2,
        estimatedMinutes: 25,
      });
    }

    // Seed active delivery for Kamal
    const existingActive = await Delivery.findOne({
      rider: rider._id,
      status: { $in: ['ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'] },
    });
    if (!existingActive && orders.length > 1) {
      await Delivery.create({
        orderId: orders[1]._id,
        order: orders[1]._id,
        riderId: rider._id,
        rider: rider._id,
        cookId: cook._id,
        customerId: customer._id,
        pickupLocation: {
          address: cook.address || '45/2 Galle Road, Colombo 03, Sri Lanka',
          latitude: 6.9034,
          longitude: 79.8546,
        },
        deliveryLocation: {
          address: '55 Nawala Road, Rajagiriya, Colombo',
          latitude: 6.9056,
          longitude: 79.8924,
        },
        status: 'ACCEPTED',
        deliveryFee: 500.0,
        distanceKm: 5.1,
        estimatedMinutes: 28,
      });
    }

    // Seed completed past deliveries for history
    const pastCompletedCount = await Delivery.countDocuments({
      rider: rider._id,
      status: 'DELIVERED',
    });

    if (pastCompletedCount < 3 && orders.length > 2) {
      const pastDelivery = await Delivery.create({
        orderId: orders[2]._id,
        order: orders[2]._id,
        riderId: rider._id,
        rider: rider._id,
        cookId: cook._id,
        customerId: customer._id,
        pickupLocation: {
          address: cook.address || '45/2 Galle Road, Colombo 03, Sri Lanka',
          latitude: 6.9034,
          longitude: 79.8546,
        },
        deliveryLocation: {
          address: '102 Ward Place, Colombo 07',
          latitude: 6.9152,
          longitude: 79.8712,
        },
        status: 'DELIVERED',
        deliveryFee: 420.0,
        distanceKm: 3.6,
        estimatedMinutes: 20,
        pickedUpAt: new Date(Date.now() - 3600000 * 3),
        deliveredAt: new Date(Date.now() - 3600000 * 2),
      });

      await Earning.create({
        riderId: rider._id,
        deliveryId: pastDelivery._id,
        amount: 420.0,
        date: new Date(),
      });
    }
  }

  // 5. Seed sample daily earnings in Rs. (past 7 days)
  const pastDays = [0, 1, 2, 3, 4, 5, 6];
  const sampleAmounts = [2450.0, 3100.0, 1850.0, 4200.0, 2900.0, 3750.0, 4100.0];

  for (let i = 0; i < pastDays.length; i++) {
    const d = new Date();
    d.setDate(d.getDate() - pastDays[i]);
    const count = await Earning.countDocuments({
      riderId: rider._id,
      date: {
        $gte: new Date(d.getFullYear(), d.getMonth(), d.getDate()),
        $lt: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1),
      },
    });

    if (count === 0) {
      await Earning.create({
        riderId: rider._id,
        amount: sampleAmounts[i],
        date: d,
      });
    }
  }

  console.log('Successfully seeded Sri Lankan rider, deliveries, and earnings in Rs.!');
  console.log(`Rider login: ${riderEmail} | Password: ${riderPassword}`);
}

seedRider()
  .catch((err) => {
    console.error('Seed rider error:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
