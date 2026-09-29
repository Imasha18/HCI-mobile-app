const Meal = require('../models/Meal');
const mongoose = require('mongoose');
const { sendSuccess } = require('../utils/apiResponse');

async function listMeals(req, res) {
  const filter = { available: true };
  if (req.query.category) filter.category = req.query.category;
  if (req.query.minPrice || req.query.maxPrice) {
    filter.price = {};
    if (req.query.minPrice) filter.price.$gte = Number(req.query.minPrice);
    if (req.query.maxPrice) filter.price.$lte = Number(req.query.maxPrice);
  }
  if (req.query.rating) filter.rating = { $gte: Number(req.query.rating) };
  if (req.query.q) {
    filter.$or = [
      { name: { $regex: req.query.q, $options: 'i' } },
      { description: { $regex: req.query.q, $options: 'i' } },
      { category: { $regex: req.query.q, $options: 'i' } },
    ];
  }
  return sendSuccess(res, await Meal.find(filter).populate('cook', 'name address phone'));
}

async function searchMeals(req, res) {
  return listMeals(req, res);
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

module.exports = { listMeals, searchMeals, getMeal, createMeal };
