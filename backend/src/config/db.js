const mongoose = require('mongoose');
const dns = require('node:dns');
const environment = require('./environment');

async function connectDatabase() {
  if (!environment.mongoUri) return null;
  if (environment.mongoDnsServers.length) dns.setServers(environment.mongoDnsServers);

  try {
    const connection = await mongoose.connect(environment.mongoUri);
    console.log('MongoDB connected');
    return connection;
  } catch (error) {
    console.error(`MongoDB connection failed: ${error.message}`);
    throw error;
  }
}

module.exports = { connectDatabase };
