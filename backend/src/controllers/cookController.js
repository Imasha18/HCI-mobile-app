const { sendSuccess } = require('../utils/apiResponse');

async function getCookSummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Cook workspace ready' });
}

module.exports = { getCookSummary };
