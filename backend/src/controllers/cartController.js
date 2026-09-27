const Cart = require('../models/Cart');
const { sendSuccess } = require('../utils/apiResponse');

async function getCart(req, res) {
  return sendSuccess(res, await Cart.findOne({ customer: req.user.id }).populate('items.meal'));
}

async function updateCart(req, res) {
  return sendSuccess(res, await Cart.findOneAndUpdate({ customer: req.user.id }, { customer: req.user.id, items: req.body.items || [] }, { upsert: true, new: true }).populate('items.meal'));
}

module.exports = { getCart, updateCart };
