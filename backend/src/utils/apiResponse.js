function sendSuccess(res, data, message = 'Success', statusCode = 200) {
  return res.status(statusCode).json({ success: true, message, data });
}

function sendError(res, message, statusCode = 500, details) {
  return res.status(statusCode).json({ success: false, message, ...(details ? { details } : {}) });
}

module.exports = { sendSuccess, sendError };
