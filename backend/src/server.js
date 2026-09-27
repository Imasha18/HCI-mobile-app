const app = require('./app');
const environment = require('./config/environment');
const { connectDatabase } = require('./config/db');

async function startServer() {
  await connectDatabase();
  return app.listen(environment.port, () => {
    console.log(`Table & Hearth API listening on port ${environment.port}`);
  });
}

if (require.main === module) {
  startServer().catch((error) => {
    console.error('Failed to start server', error);
    process.exitCode = 1;
  });
}

module.exports = { app, startServer };
