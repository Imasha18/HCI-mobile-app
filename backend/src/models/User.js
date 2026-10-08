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
    model: { type: String, default: '' },
    plateNumber: { type: String, default: '' },
  },
  isBlocked: { type: Boolean, default: false },
  emailVerified: { type: Boolean, default: false },
  verificationStatus: {
    type: String,
    enum: ['not_submitted', 'pending', 'approved', 'rejected'],
    default: 'not_submitted',
  },
  verificationDocuments: {
    type: mongoose.Schema.Types.Mixed,
    default: () => ({
      nic: { type: 'nic', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
      drivingLicense: { type: 'drivingLicense', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
      vehicleDocument: { type: 'vehicleDocument', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
      insurance: { type: 'insurance', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
    }),
  },
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
