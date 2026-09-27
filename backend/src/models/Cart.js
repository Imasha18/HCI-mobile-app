const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  items: [{ meal: { type: mongoose.Schema.Types.ObjectId, ref: 'Meal' }, quantity: { type: Number, min: 1 } }],
}, { timestamps: true });

module.exports = mongoose.model('Cart', cartSchema);
