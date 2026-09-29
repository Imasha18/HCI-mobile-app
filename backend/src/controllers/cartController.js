const Cart = require('../models/Cart');
const { sendSuccess } = require('../utils/apiResponse');

async function saveCart(req, res, items) {
  return sendSuccess(res, await Cart.findOneAndUpdate(
    { customer: req.user.id },
    { customer: req.user.id, items },
    { upsert: true, new: true, runValidators: true },
  ).populate('items.meal'));
}

async function getCart(req, res) {
  return sendSuccess(res, await Cart.findOne({ customer: req.user.id }).populate('items.meal'));
}

async function updateCart(req, res) {
  return saveCart(req, res, req.body.items || []);
}

async function addCartItem(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id });
  const items = cart?.items ? [...cart.items] : [];
  const existing = items.find((item) => item.meal.toString() === req.body.mealId);
  if (existing) existing.quantity += Number(req.body.quantity || 1);
  else items.push({ meal: req.body.mealId, quantity: Number(req.body.quantity || 1) });
  return saveCart(req, res, items);
}

async function updateCartItem(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id });
  const items = (cart?.items || []).map((item) => item.meal.toString() === req.params.id
    ? { meal: item.meal, quantity: Number(req.body.quantity) }
    : item);
  return saveCart(req, res, items.filter((item) => item.quantity > 0));
}

async function removeCartItem(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id });
  const items = (cart?.items || []).filter((item) => item.meal.toString() !== req.params.id);
  return saveCart(req, res, items);
}

module.exports = { getCart, updateCart, addCartItem, updateCartItem, removeCartItem };
