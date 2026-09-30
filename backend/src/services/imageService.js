const cloudinary = require('cloudinary').v2;
const { getCloudinaryConfig } = require('../config/cloudinary');

function isConfigured() {
  const config = getCloudinaryConfig();
  return Boolean(config.cloudName && config.apiKey && config.apiSecret);
}

async function uploadImage(file, folder = 'homebite/meals') {
  if (!file) return null;

  if (isConfigured()) {
    try {
      const config = getCloudinaryConfig();
      cloudinary.config({
        cloud_name: config.cloudName,
        api_key: config.apiKey,
        api_secret: config.apiSecret,
      });

      const result = await cloudinary.uploader.upload(file.path, {
        folder,
        resource_type: 'auto',
      });
      return result.secure_url;
    } catch (err) {
      console.warn('Cloudinary upload failed, falling back to local file:', err.message);
    }
  }

  // Local static file path fallback
  return `/uploads/${file.filename}`;
}

module.exports = { isConfigured, uploadImage };
