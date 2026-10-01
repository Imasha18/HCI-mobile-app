const Meal = require('../models/Meal');
const mongoose = require('mongoose');
const { sendSuccess } = require('../utils/apiResponse');
const { uploadImage } = require('../services/imageService');

// Helper to parse array inputs that might come from FormData as comma-separated or json string
function parseArrayInput(input) {
  if (!input) return [];
  if (Array.isArray(input)) return input;
  if (typeof input === 'string') {
    try {
      const parsed = JSON.parse(input);
      if (Array.isArray(parsed)) return parsed;
    } catch (_) {}
    return input.split(',').map((s) => s.trim()).filter(Boolean);
  }
  return [];
}

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

// POST /api/meals
async function createMeal(req, res) {
  const {
    name,
    description,
    price,
    category,
    cookingTime,
    prepTimeMinutes,
    ingredients,
    dietaryInformation,
    available,
    availability,
  } = req.body;

  let imageUrl = req.body.imageUrl || req.body.image;
  if (req.file) {
    const uploaded = await uploadImage(req.file);
    if (uploaded) imageUrl = uploaded;
  }

  const meal = await Meal.create({
    cook: req.user.id,
    name: name?.trim() || 'Untitled Meal',
    description: description?.trim() || '',
    price: Number(price) || 0,
    category: category || 'Rice',
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
    ingredients: parseArrayInput(ingredients),
    dietaryInformation: parseArrayInput(dietaryInformation),
    prepTimeMinutes: Number(cookingTime || prepTimeMinutes) || 25,
    available: available !== undefined ? Boolean(available) : (availability !== undefined ? Boolean(availability) : true),
    rating: 5.0,
  });

  return sendSuccess(res, meal, 'Meal created successfully', 201);
}

// PUT /api/meals/:id
async function updateMeal(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ success: false, message: 'Invalid meal ID' });
  }

  const meal = await Meal.findOne({ _id: req.params.id, cook: req.user.id });
  if (!meal) {
    return res.status(404).json({ success: false, message: 'Meal not found or not owned by you' });
  }

  if (req.file) {
    const uploaded = await uploadImage(req.file);
    if (uploaded) meal.imageUrl = uploaded;
  } else if (req.body.imageUrl || req.body.image) {
    meal.imageUrl = req.body.imageUrl || req.body.image;
  }

  if (req.body.name !== undefined) meal.name = req.body.name.trim();
  if (req.body.description !== undefined) meal.description = req.body.description.trim();
  if (req.body.price !== undefined) meal.price = Number(req.body.price);
  if (req.body.category !== undefined) meal.category = req.body.category;
  if (req.body.cookingTime !== undefined || req.body.prepTimeMinutes !== undefined) {
    meal.prepTimeMinutes = Number(req.body.cookingTime || req.body.prepTimeMinutes);
  }
  if (req.body.ingredients !== undefined) {
    meal.ingredients = parseArrayInput(req.body.ingredients);
  }
  if (req.body.dietaryInformation !== undefined) {
    meal.dietaryInformation = parseArrayInput(req.body.dietaryInformation);
  }
  if (req.body.available !== undefined) {
    meal.available = Boolean(req.body.available);
  } else if (req.body.availability !== undefined) {
    meal.available = Boolean(req.body.availability);
  }

  await meal.save();
  return sendSuccess(res, meal, 'Meal updated successfully');
}

// DELETE /api/meals/:id
async function deleteMeal(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ success: false, message: 'Invalid meal ID' });
  }

  const meal = await Meal.findOneAndDelete({ _id: req.params.id, cook: req.user.id });
  if (!meal) {
    return res.status(404).json({ success: false, message: 'Meal not found or not owned by you' });
  }

  return sendSuccess(res, { id: meal._id }, 'Meal deleted successfully');
}

// PATCH /api/meals/:id/availability
async function toggleAvailability(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ success: false, message: 'Invalid meal ID' });
  }

  const meal = await Meal.findOne({ _id: req.params.id, cook: req.user.id });
  if (!meal) {
    return res.status(404).json({ success: false, message: 'Meal not found' });
  }

  meal.available = req.body.available !== undefined ? Boolean(req.body.available) : !meal.available;
  await meal.save();

  return sendSuccess(res, meal, `Meal availability updated to ${meal.available}`);
}

module.exports = {
  listMeals,
  searchMeals,
  getMeal,
  createMeal,
  updateMeal,
  deleteMeal,
  toggleAvailability,
};
