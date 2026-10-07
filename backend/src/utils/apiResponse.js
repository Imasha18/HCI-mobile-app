function sendSuccess(res, data, message = 'Success', statusCode = 200, pagination = null) {
  const payload = { success: true, message, data };
  if (pagination) payload.pagination = pagination;
  return res.status(statusCode).json(payload);
}

function sendError(res, message, statusCode = 500, details) {
  return res.status(statusCode).json({ success: false, message, ...(details ? { details } : {}) });
}

module.exports = { sendSuccess, sendError };
