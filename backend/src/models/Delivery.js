const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema({
  orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  riderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  cookId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  pickupLocation: {
    address: { type: String, default: '45/2 Galle Road, Colombo 03, Sri Lanka' },
    latitude: { type: Number, default: 6.9034 },
    longitude: { type: Number, default: 79.8546 },
  },
  deliveryLocation: {
    address: { type: String, default: '18 Flower Road, Colombo 07, Sri Lanka' },
    latitude: { type: Number, default: 6.9128 },
    longitude: { type: Number, default: 79.8653 },
  },
  status: {
    type: String,
    enum: ['AVAILABLE', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'],
    default: 'AVAILABLE',
  },
  deliveryFee: { type: Number, default: 350.0 },
  distanceKm: { type: Number, default: 3.8 },
  estimatedMinutes: { type: Number, default: 22 },
  pickedUpAt: Date,
  deliveredAt: Date,
  proofImageUrl: String,
  notes: String,
  cancellationReason: String,
}, { timestamps: true });

deliverySchema.pre('save', function (next) {
  if (this.orderId && !this.order) this.order = this.orderId;
  if (this.order && !this.orderId) this.orderId = this.order;
  if (this.riderId && !this.rider) this.rider = this.riderId;
  if (this.rider && !this.riderId) this.riderId = this.rider;
  next();
});

module.exports = mongoose.model('Delivery', deliverySchema);
