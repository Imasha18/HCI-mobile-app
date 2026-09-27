const mongoose = require('mongoose');

const mealSchema = new mongoose.Schema({
  cook: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true },
  description: String,
  price: { type: Number, required: true, min: 0 },
  category: String,
  imageUrl: String,
  available: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Meal', mealSchema);
