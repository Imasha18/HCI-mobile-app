const mongoose = require('mongoose');

const recommendationInteractionSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  meal: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Meal',
    required: true,
  },
  eventType: {
    type: String,
    enum: [
      'recommendation_shown',
      'meal_clicked',
      'added_to_cart',
      'ordered',
      'rated',
      'skipped',
    ],
    required: true,
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
}, {
  timestamps: true,
});

recommendationInteractionSchema.index({ user: 1, eventType: 1 });
recommendationInteractionSchema.index({ user: 1, meal: 1 });
recommendationInteractionSchema.index({ meal: 1, eventType: 1 });
recommendationInteractionSchema.index({ createdAt: -1 });

module.exports = mongoose.model('RecommendationInteraction', recommendationInteractionSchema);
