const { sendSuccess } = require('../utils/apiResponse');

async function getCustomerSummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Customer workspace ready' });
}

module.exports = { getCustomerSummary };
