const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema({
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  rider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  pickupLocation: String,
  dropoffLocation: String,
  status: { type: String, default: 'pending' },
  pickedUpAt: Date,
  deliveredAt: Date,
}, { timestamps: true });

module.exports = mongoose.model('Delivery', deliverySchema);
