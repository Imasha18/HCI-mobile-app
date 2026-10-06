const Delivery = require('../models/Delivery');
const Order = require('../models/Order');
const Earning = require('../models/Earning');
const Notification = require('../models/Notification');
const { sendSuccess } = require('../utils/apiResponse');

// GET /api/deliveries/available
async function getAvailableDeliveries(req, res) {
  // Find deliveries that are AVAILABLE
  let available = await Delivery.find({ status: 'AVAILABLE' })
    .sort({ createdAt: -1 })
    .populate({
      path: 'orderId',
      populate: [
        { path: 'items.meal', select: 'name imageUrl price category' },
        { path: 'customer', select: 'name phone address' },
        { path: 'cook', select: 'name kitchenName phone address profileImage' },
      ],
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  // If there are active orders without an available delivery doc, create them dynamically
  const activeOrders = await Order.find({
    status: { $in: ['Order Received', 'Pending', 'Placed', 'Accepted', 'Preparing', 'Ready For Pickup'] },
    rider: { $in: [null, undefined] },
  })
    .populate('cook', 'name kitchenName phone address profileImage')
    .populate('customer', 'name phone address')
    .populate('items.meal', 'name imageUrl price category');

  for (const order of activeOrders) {
    const existing = await Delivery.findOne({ orderId: order._id });
    if (!existing) {
      const newDel = await Delivery.create({
        orderId: order._id,
        order: order._id,
        cookId: order.cook?._id || order.cook,
        customerId: order.customer?._id || order.customer,
        pickupLocation: {
          address: order.cook?.address || '45/2 Galle Road, Colombo 03, Sri Lanka',
          latitude: 6.9034,
          longitude: 79.8546,
        },
        deliveryLocation: {
          address: order.deliveryAddress || order.customer?.address || '18 Flower Road, Colombo 07, Sri Lanka',
          latitude: 6.9128,
          longitude: 79.8653,
        },
        status: 'AVAILABLE',
        deliveryFee: 350.0,
        distanceKm: 3.8,
        estimatedMinutes: 20,
      });

      const populated = await Delivery.findById(newDel._id)
        .populate({
          path: 'orderId',
          populate: [
            { path: 'items.meal', select: 'name imageUrl price category' },
            { path: 'customer', select: 'name phone address' },
            { path: 'cook', select: 'name kitchenName phone address profileImage' },
          ],
        })
        .populate('cookId', 'name kitchenName phone address profileImage')
        .populate('customerId', 'name phone address');

      available.unshift(populated);
    }
  }

  return sendSuccess(res, available);
}

// GET /api/deliveries/:id
async function getDeliveryById(req, res) {
  const delivery = await Delivery.findById(req.params.id)
    .populate({
      path: 'orderId',
      populate: [
        { path: 'items.meal', select: 'name imageUrl price category' },
        { path: 'customer', select: 'name phone address' },
        { path: 'cook', select: 'name kitchenName phone address profileImage' },
      ],
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address')
    .populate('riderId', 'name phone vehicleDetails rating profileImage');

  if (!delivery) {
    return res.status(404).json({ success: false, message: 'Delivery not found' });
  }

  return sendSuccess(res, delivery);
}

// PATCH /api/deliveries/:id/accept
async function acceptDelivery(req, res) {
  const delivery = await Delivery.findById(req.params.id);
  if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });

  if (delivery.status !== 'AVAILABLE' && delivery.rider?.toString() !== req.user.id) {
    return res.status(400).json({ success: false, message: 'Delivery has already been assigned to another rider' });
  }

  delivery.rider = req.user.id;
  delivery.riderId = req.user.id;
  delivery.status = 'ACCEPTED';
  await delivery.save();

  // Also update Order rider reference and status
  if (delivery.orderId) {
    await Order.findByIdAndUpdate(delivery.orderId, {
      rider: req.user.id,
      status: 'Rider Assigned',
    });
  }

  // Send notifications to Customer and Cook
  if (delivery.customerId) {
    await Notification.create({
      user: delivery.customerId,
      title: 'Rider Assigned',
      body: 'A HomeBite rider has accepted your delivery and is heading to the kitchen.',
    });
  }
  if (delivery.cookId) {
    await Notification.create({
      user: delivery.cookId,
      title: 'Rider Assigned',
      body: 'A delivery rider has accepted the order and is on their way to pick up the food.',
    });
  }

  const populated = await Delivery.findById(delivery._id)
    .populate({
      path: 'orderId',
      populate: {
        path: 'items.meal',
        select: 'name imageUrl price category',
      },
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address')
    .populate('riderId', 'name phone vehicleDetails rating profileImage');

  return sendSuccess(res, populated || delivery, 'Delivery accepted successfully');
}

// PATCH /api/deliveries/:id/pickup
async function pickupDelivery(req, res) {
  const delivery = await Delivery.findOne({ _id: req.params.id, rider: req.user.id });
  if (!delivery) return res.status(404).json({ success: false, message: 'Delivery assignment not found' });

  delivery.status = 'PICKED_UP';
  delivery.pickedUpAt = new Date();
  await delivery.save();

  if (delivery.orderId) {
    await Order.findByIdAndUpdate(delivery.orderId, { status: 'Picked Up' });
  }

  if (delivery.customerId) {
    await Notification.create({
      user: delivery.customerId,
      title: 'Food Picked Up',
      body: 'Your rider has picked up your food from the kitchen.',
    });
  }
  if (delivery.cookId) {
    await Notification.create({
      user: delivery.cookId,
      title: 'Food Picked Up',
      body: 'The rider has picked up the food from your kitchen.',
    });
  }

  const populated = await Delivery.findById(delivery._id)
    .populate({
      path: 'orderId',
      populate: {
        path: 'items.meal',
        select: 'name imageUrl price category',
      },
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, populated || delivery, 'Food picked up from cook');
}

// PATCH /api/deliveries/:id/start
async function startDelivery(req, res) {
  const delivery = await Delivery.findOne({ _id: req.params.id, rider: req.user.id });
  if (!delivery) return res.status(404).json({ success: false, message: 'Delivery assignment not found' });

  delivery.status = 'IN_TRANSIT';
  await delivery.save();

  if (delivery.orderId) {
    await Order.findByIdAndUpdate(delivery.orderId, { status: 'Out for Delivery' });
  }

  if (delivery.customerId) {
    await Notification.create({
      user: delivery.customerId,
      title: 'Out for Delivery',
      body: 'Your rider is on the way with your delicious home-cooked meal!',
    });
  }

  const populated = await Delivery.findById(delivery._id)
    .populate({
      path: 'orderId',
      populate: {
        path: 'items.meal',
        select: 'name imageUrl price category',
      },
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, populated || delivery, 'Delivery is in transit');
}

// PATCH /api/deliveries/:id/complete
async function completeDelivery(req, res) {
  const delivery = await Delivery.findOne({ _id: req.params.id, rider: req.user.id });
  if (!delivery) return res.status(404).json({ success: false, message: 'Delivery assignment not found' });

  delivery.status = 'DELIVERED';
  delivery.deliveredAt = new Date();
  if (req.body.proofImageUrl) {
    delivery.proofImageUrl = req.body.proofImageUrl;
  }
  await delivery.save();

  // Update order status to Delivered and paymentStatus to paid
  if (delivery.orderId) {
    const updatedOrder = await Order.findByIdAndUpdate(
      delivery.orderId,
      { status: 'Delivered', paymentStatus: 'paid' },
      { new: true }
    );
    // Create Cook Earning record if not existing
    if (updatedOrder && updatedOrder.cook) {
      const existingCookEarning = await Earning.findOne({ orderId: updatedOrder._id, cookId: updatedOrder.cook });
      if (!existingCookEarning) {
        await Earning.create({
          cookId: updatedOrder.cook,
          orderId: updatedOrder._id,
          amount: updatedOrder.total,
          date: new Date(),
        });
      }
    }
  }

  // Create Rider Earning record
  const existingEarning = await Earning.findOne({ deliveryId: delivery._id });
  if (!existingEarning) {
    await Earning.create({
      riderId: req.user.id,
      deliveryId: delivery._id,
      amount: delivery.deliveryFee || 350.0,
      date: new Date(),
    });
  }

  // Send notifications
  if (delivery.customerId) {
    await Notification.create({
      user: delivery.customerId,
      title: 'Order Delivered',
      body: 'Your order has been safely delivered! Enjoy your meal.',
    });
  }
  if (delivery.cookId) {
    await Notification.create({
      user: delivery.cookId,
      title: 'Order Completed',
      body: 'Order has been delivered to customer and payment is completed.',
    });
  }

  await Notification.create({
    user: req.user.id,
    title: 'Delivery Completed',
    body: `Delivery finished successfully! Rs. ${(delivery.deliveryFee || 350).toFixed(2)} added to your earnings.`,
  });

  const populated = await Delivery.findById(delivery._id)
    .populate({
      path: 'orderId',
      populate: {
        path: 'items.meal',
        select: 'name imageUrl price category',
      },
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, populated || delivery, 'Delivery confirmed and completed');
}

// POST /api/deliveries (Create delivery request)
async function createDelivery(req, res) {
  const {
    orderId,
    cookId,
    customerId,
    pickupLocation,
    deliveryLocation,
    deliveryFee,
    distanceKm,
    estimatedMinutes,
    notes,
  } = req.body;

  const newDelivery = await Delivery.create({
    orderId: orderId || null,
    order: orderId || null,
    cookId: cookId || null,
    customerId: customerId || req.user.id,
    pickupLocation: pickupLocation || {
      address: '45/2 Galle Road, Colombo 03, Sri Lanka',
      latitude: 6.9034,
      longitude: 79.8546,
    },
    deliveryLocation: deliveryLocation || {
      address: '18 Flower Road, Colombo 07, Sri Lanka',
      latitude: 6.9128,
      longitude: 79.8653,
    },
    deliveryFee: Number(deliveryFee) || 350.0,
    distanceKm: Number(distanceKm) || 3.8,
    estimatedMinutes: Number(estimatedMinutes) || 20,
    notes: notes || '',
    status: 'AVAILABLE',
  });

  const populated = await Delivery.findById(newDelivery._id)
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return res.status(201).json({
    success: true,
    data: populated,
    message: 'Delivery request created successfully',
  });
}

// GET /api/deliveries (List deliveries with optional query filter)
async function listDeliveries(req, res) {
  const filter = {};
  if (req.query.status) filter.status = req.query.status;
  if (req.query.riderId || req.query.rider) filter.rider = req.query.riderId || req.query.rider;
  if (req.query.cookId) filter.cookId = req.query.cookId;
  if (req.query.customerId) filter.customerId = req.query.customerId;

  const deliveries = await Delivery.find(filter)
    .sort({ createdAt: -1 })
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address')
    .populate('riderId', 'name phone vehicleDetails rating profileImage');

  return sendSuccess(res, deliveries);
}

// PUT /api/deliveries/:id (Full update of delivery)
async function updateDelivery(req, res) {
  const allowed = [
    'pickupLocation',
    'deliveryLocation',
    'deliveryFee',
    'distanceKm',
    'estimatedMinutes',
    'status',
    'notes',
    'proofImageUrl',
  ];

  const updateData = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      updateData[key] = req.body[key];
    }
  }

  const updated = await Delivery.findByIdAndUpdate(req.params.id, updateData, { new: true })
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address')
    .populate('riderId', 'name phone vehicleDetails rating profileImage');

  if (!updated) {
    return res.status(404).json({ success: false, message: 'Delivery not found' });
  }

  return sendSuccess(res, updated, 'Delivery updated successfully');
}

// PATCH /api/deliveries/:id/cancel
async function cancelDelivery(req, res) {
  const delivery = await Delivery.findById(req.params.id);
  if (!delivery) {
    return res.status(404).json({ success: false, message: 'Delivery not found' });
  }

  delivery.status = 'CANCELLED';
  if (req.body.reason) {
    delivery.cancellationReason = req.body.reason;
  }
  await delivery.save();

  if (delivery.customerId) {
    await Notification.create({
      user: delivery.customerId,
      title: 'Delivery Cancelled',
      body: req.body.reason || 'Your delivery has been cancelled.',
    });
  }

  const populated = await Delivery.findById(delivery._id)
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, populated, 'Delivery cancelled successfully');
}

// DELETE /api/deliveries/:id
async function deleteDelivery(req, res) {
  const delivery = await Delivery.findByIdAndDelete(req.params.id);
  if (!delivery) {
    return res.status(404).json({ success: false, message: 'Delivery not found' });
  }

  return sendSuccess(res, {}, 'Delivery deleted successfully');
}

module.exports = {
  createDelivery,
  listDeliveries,
  getAvailableDeliveries,
  getDeliveryById,
  acceptDelivery,
  pickupDelivery,
  startDelivery,
  completeDelivery,
  updateDelivery,
  cancelDelivery,
  deleteDelivery,
};
