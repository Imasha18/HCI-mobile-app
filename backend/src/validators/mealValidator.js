function validateMeal(body) {
  const errors = [];
  if (!body.name) errors.push('Meal name is required');
  if (typeof body.price !== 'number' || body.price < 0) errors.push('A non-negative price is required');
  return errors;
}

module.exports = { validateMeal };
