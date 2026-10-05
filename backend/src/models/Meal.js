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
  dietaryTags: [String],
  cuisine: { type: String, default: 'Sri Lankan', trim: true },
  spiceLevel: { type: String, enum: ['mild', 'medium', 'spicy'], default: 'medium' },
  prepTimeMinutes: { type: Number, default: 25 },
  rating: { type: Number, min: 0, max: 5, default: 4.8 },
  ratingCount: { type: Number, default: 0, min: 0 },
  orderCount: { type: Number, default: 0, min: 0 },
  available: { type: Boolean, default: true },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

mealSchema.virtual('cookId')
  .get(function() {
    return (this.cook && this.cook._id) ? this.cook._id : this.cook;
  })
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
mealSchema.index({ available: 1, rating: -1 });
mealSchema.index({ cuisine: 1, available: 1 });
mealSchema.index({ price: 1, available: 1 });
mealSchema.index({ name: 'text', description: 'text', category: 'text' });

module.exports = mongoose.model('Meal', mealSchema);
