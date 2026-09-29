const mongoose = require('mongoose');
const dns = require('node:dns');
const environment = require('./environment');

function createDnsLookup() {
  if (!environment.mongoDnsServers.length) return undefined;

  return async (hostname, options, callback) => {
    try {
      const addresses = await dns.promises.resolve4(hostname);
      if (options?.all) {
        callback(null, addresses.map((address) => ({ address, family: 4 })));
      } else {
        callback(null, addresses[0], 4);
      }
    } catch (error) {
      callback(error);
    }
  };
}

async function connectDatabase() {
  if (!environment.mongoUri) return null;
  if (environment.mongoDnsServers.length) dns.setServers(environment.mongoDnsServers);

  try {
    const connection = await mongoose.connect(environment.mongoUri, {
      lookup: createDnsLookup(),
    });
    console.log('MongoDB connected');
    return connection;
  } catch (error) {
    console.error(`MongoDB connection failed: ${error.message}`);
    throw error;
  }
}

module.exports = { connectDatabase };
