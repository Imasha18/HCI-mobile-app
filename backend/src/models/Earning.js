const mongoose = require('mongoose');

const earningSchema = new mongoose.Schema({
  cookId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  riderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  deliveryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Delivery' },
  amount: { type: Number, required: true },
  date: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('Earning', earningSchema);
