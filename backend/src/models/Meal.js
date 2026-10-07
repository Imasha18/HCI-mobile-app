const mongoose = require('mongoose');

const mealSchema = new mongoose.Schema({
  cook: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true },
  description: String,
  price: { type: Number, required: true, min: 0 },
  category: String,
  imageUrl: String,
  ingredients: [String],
  dietaryInformation: [String],
  prepTimeMinutes: { type: Number, default: 25 },
  rating: { type: Number, min: 0, max: 5, default: 4.8 },
  available: { type: Boolean, default: true },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

mealSchema.virtual('cookId')
  .get(function() { return this.cook; })
  .set(function(v) { this.cook = v; });

mealSchema.virtual('image')
  .get(function() { return this.imageUrl; })
  .set(function(v) { this.imageUrl = v; });

mealSchema.virtual('availability')
  .get(function() { return this.available; })
  .set(function(v) { this.available = v; });

mealSchema.virtual('cookingTime')
  .get(function() { return this.prepTimeMinutes; })
  .set(function(v) { this.prepTimeMinutes = v; });

mealSchema.index({ cook: 1, available: 1 });
mealSchema.index({ category: 1, available: 1 });
mealSchema.index({ available: 1, createdAt: -1 });
mealSchema.index({ name: 'text', description: 'text', category: 'text' });

module.exports = mongoose.model('Meal', mealSchema);
