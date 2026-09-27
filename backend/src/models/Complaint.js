const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  subject: { type: String, required: true },
  description: { type: String, required: true },
  status: { type: String, default: 'open' },
}, { timestamps: true });

module.exports = mongoose.model('Complaint', complaintSchema);
