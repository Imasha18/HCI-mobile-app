const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  cook: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  items: [{
    meal: { type: mongoose.Schema.Types.ObjectId, ref: 'Meal' },
    name: String,
    quantity: { type: Number, default: 1 },
    price: { type: Number, required: true },
  }],
  total: { type: Number, required: true, min: 0 },
  paymentStatus: { type: String, enum: ['pending', 'paid', 'failed'], default: 'pending' },
  paymentMethod: { type: String, default: 'Cash on Delivery' },
  status: { type: String, default: 'Order Received' },
  deliveryAddress: { type: mongoose.Schema.Types.Mixed },
  deliveryPhone: { type: String, trim: true },
  orderNotes: String,
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

orderSchema.virtual('totalAmount')
  .get(function() { return this.total; })
  .set(function(v) { this.total = v; });

orderSchema.virtual('orderStatus')
  .get(function() { return this.status; })
  .set(function(v) { this.status = v; });

orderSchema.virtual('customerId')
  .get(function() { return this.customer; })
  .set(function(v) { this.customer = v; });

orderSchema.virtual('cookId')
  .get(function() { return this.cook; })
  .set(function(v) { this.cook = v; });

orderSchema.index({ customer: 1, createdAt: -1 });
orderSchema.index({ cook: 1, createdAt: -1 });
orderSchema.index({ rider: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
