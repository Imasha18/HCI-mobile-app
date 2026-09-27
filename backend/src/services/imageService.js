const { getCloudinaryConfig } = require('../config/cloudinary');

function isConfigured() {
  const config = getCloudinaryConfig();
  return Boolean(config.cloudName && config.apiKey && config.apiSecret);
}

module.exports = { isConfigured };
