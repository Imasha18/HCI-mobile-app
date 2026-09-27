const { sendSuccess } = require('../utils/apiResponse');

async function getAdminSummary(req, res) {
  return sendSuccess(res, { message: 'Admin workspace ready' });
}

module.exports = { getAdminSummary };
