const mongoose = require('mongoose');
const environment = require('./environment');

async function connectDatabase() {
  if (!environment.mongoUri) return null;
  return mongoose.connect(environment.mongoUri);
}

module.exports = { connectDatabase };
