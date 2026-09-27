const { sendSuccess } = require('../utils/apiResponse');

async function getRiderSummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Rider workspace ready' });
}

module.exports = { getRiderSummary };
