function validateOrder(body) {
  const errors = [];
  if (!Array.isArray(body.items) || body.items.length === 0) errors.push('At least one order item is required');
  if (typeof body.total !== 'number' || body.total < 0) errors.push('A valid total is required');
  return errors;
}

module.exports = { validateOrder };
