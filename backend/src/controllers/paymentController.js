const { sendSuccess } = require('../utils/apiResponse');

async function createPayment(req, res) {
  return sendSuccess(res, { status: 'pending', ...req.body }, 'Payment intent created', 201);
}

module.exports = { createPayment };
