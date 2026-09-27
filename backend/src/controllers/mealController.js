const Meal = require('../models/Meal');
const mongoose = require('mongoose');
const { sendSuccess } = require('../utils/apiResponse');

async function listMeals(req, res) {
  const filter = req.query.category ? { category: req.query.category, available: true } : { available: true };
  return sendSuccess(res, await Meal.find(filter).populate('cook', 'name'));
}

async function getMeal(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ success: false, message: 'Meal not found' });
  }
  const meal = await Meal.findById(req.params.id).populate('cook', 'name');
  if (!meal) return res.status(404).json({ success: false, message: 'Meal not found' });
  return sendSuccess(res, meal);
}

async function createMeal(req, res) {
  const meal = await Meal.create({ ...req.body, cook: req.user.id });
  return sendSuccess(res, meal, 'Meal created', 201);
}

module.exports = { listMeals, getMeal, createMeal };
