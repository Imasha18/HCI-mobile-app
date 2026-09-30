const path = require('node:path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const environment = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 5000),
  mongoUri: process.env.MONGODB_URI || process.env.MONGO_URI || '',
  mongoDnsServers: (process.env.MONGO_DNS_SERVERS || '').split(',').map((server) => server.trim()).filter(Boolean),
  jwtSecret: process.env.JWT_SECRET || 'development-only-secret',
  clientOrigin: process.env.CLIENT_ORIGIN || '*',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  gmailUser: process.env.GMAIL_USER || '',
  gmailAppPassword: process.env.GMAIL_APP_PASSWORD || '',
  verificationUrlMinutes: Number(process.env.VERIFICATION_URL_MINUTES || 15),
};

module.exports = environment;
