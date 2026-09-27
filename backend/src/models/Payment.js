const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  amount: { type: Number, required: true, min: 0 },
  status: { type: String, enum: ['pending', 'paid', 'failed', 'refunded'], default: 'pending' },
  provider: String,
  transactionId: String,
}, { timestamps: true });

module.exports = mongoose.model('Payment', paymentSchema);
