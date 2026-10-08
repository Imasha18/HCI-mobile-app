const mongoose = require('mongoose');

const pendingRegistrationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      trim: true,
      default: '',
    },
    address: {
      type: String,
      trim: true,
      default: '',
    },
    role: {
      type: String,
      enum: ['customer', 'rider', 'cook'],
      default: 'customer',
    },
    kitchenName: {
      type: String,
      default: '',
    },
    vehicleDetails: {
      type: { type: String, default: 'Motorbike' },
      model: { type: String, default: '' },
      plateNumber: { type: String, default: '' },
    },
    verificationCodeHash: {
      type: String,
      required: true,
    },
    verificationExpiresAt: {
      type: Date,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// TTL index: MongoDB automatically purges pending registrations once verificationExpiresAt passes
pendingRegistrationSchema.index({ verificationExpiresAt: 1 }, { expireAfterSeconds: 0 });

const PendingRegistration = mongoose.model('PendingRegistration', pendingRegistrationSchema);

module.exports = PendingRegistration;

