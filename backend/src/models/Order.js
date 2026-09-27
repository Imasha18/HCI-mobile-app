const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  cook: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  items: [{ meal: { type: mongoose.Schema.Types.ObjectId, ref: 'Meal' }, quantity: Number, price: Number }],
  total: { type: Number, required: true, min: 0 },
  status: { type: String, default: 'pending' },
  deliveryAddress: String,
}, { timestamps: true });

module.exports = mongoose.model('Order', orderSchema);
