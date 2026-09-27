const { sendSuccess } = require('../utils/apiResponse');

async function getDeliverySummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Delivery workspace ready' });
}

module.exports = { getDeliverySummary };
