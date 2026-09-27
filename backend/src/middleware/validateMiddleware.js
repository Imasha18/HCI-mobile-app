function validateBody(schema) {
  return (req, res, next) => {
    const result = schema(req.body || {});
    if (result.length) return res.status(400).json({ success: false, message: 'Validation failed', details: result });
    return next();
  };
}

module.exports = { validateBody };
