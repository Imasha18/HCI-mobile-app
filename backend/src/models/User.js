const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ['customer', 'cook', 'rider', 'admin'], default: 'customer' },
  phone: { type: String, trim: true },
  address: { type: String, trim: true },
  profileImage: String,
  isVerified: { type: Boolean, default: true },
  rating: { type: Number, default: 4.8 },
  isOnline: { type: Boolean, default: true },
  kitchenName: String,
  vehicleDetails: {
    type: { type: String, default: 'Motorbike' },
    model: { type: String, default: 'Honda Dio' },
    plateNumber: { type: String, default: 'WP BZ-4892' },
  },
  emailVerified: { type: Boolean, default: false },
  isBlocked: { type: Boolean, default: false },
  verificationStatus: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'approved' },
  verificationDocuments: [{
    title: { type: String, default: 'National ID / Driving License' },
    documentUrl: { type: String, default: '' },
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    uploadedAt: { type: Date, default: Date.now }
  }],
  verificationCodeHash: { type: String, select: false },
  verificationExpiresAt: { type: Date, select: false },
  resetCodeHash: { type: String, select: false },
  resetExpiresAt: { type: Date, select: false },
  googleId: { type: String, unique: true, sparse: true },
  preferences: {
    dietaryPreference: {
      type: String,
      enum: ['vegetarian', 'vegan', 'non_vegetarian', 'pescatarian', 'no_preference'],
      default: 'no_preference',
    },
    favouriteCuisines: [{ type: String }],
    maxBudget: { type: Number },
    budgetPreference: {
      type: String,
      enum: ['under_500', '500_800', '800_1200', '1200_plus', 'no_preference'],
      default: 'no_preference',
    },
    spicePreference: {
      type: String,
      enum: ['mild', 'medium', 'spicy', 'no_preference'],
      default: 'no_preference',
    },
    onboardingCompleted: { type: Boolean, default: false },
  },
}, { timestamps: true });

userSchema.index({ role: 1 });
userSchema.index({ verificationStatus: 1 });
userSchema.index({ isBlocked: 1 });
userSchema.index({ role: 1, isBlocked: 1 });

module.exports = mongoose.model('User', userSchema);
