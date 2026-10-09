const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const environment = require('./config/environment');
const { notFoundMiddleware, errorMiddleware } = require('./middleware/errorMiddleware');

const app = express();

// CORS
// - Native mobile apps (Android/iOS) send no Origin header and are always allowed.
// - CLIENT_ORIGIN may be '*' or a comma-separated list of explicit origins.
// - Outside production, any http(s)://localhost:<port> / 127.0.0.1:<port> origin is
//   allowed, because Flutter Web picks a random dev port (e.g. http://localhost:50113).
const allowedOrigins = environment.clientOrigin
  .split(',')
  .map((origin) => origin.trim().replace(/\/$/, ''))
  .filter(Boolean);
const allowAnyOrigin = allowedOrigins.includes('*');
const localDevOrigin = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/i;

const corsOptions = {
  origin(origin, callback) {
    if (!origin || allowAnyOrigin || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    if (environment.nodeEnv !== 'production' && localDevOrigin.test(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  },
  methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
  maxAge: 600,
};

// Allow uploaded images in /uploads to be loaded by the Flutter Web origin.
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

app.get('/api/health', (req, res) => {
  res.json({ success: true, data: { service: 'table-and-hearth-api', status: 'ok' } });
});

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/meals', require('./routes/mealRoutes'));
app.use('/api/customers', require('./routes/customerRoutes'));
app.use('/api/customer', require('./routes/customerRoutes'));
app.use('/api/recommendations', require('./routes/recommendationRoutes'));
app.use('/api/cooks', require('./routes/cookRoutes'));
app.use('/api/cook', require('./routes/cookRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/cart', require('./routes/cartRoutes'));
app.use('/api/payments', require('./routes/paymentRoutes'));
app.use('/api/payment', require('./routes/paymentRoutes'));
app.use('/api/reviews', require('./routes/reviewRoutes'));
app.use('/api/riders', require('./routes/riderRoutes'));
app.use('/api/rider', require('./routes/riderRoutes'));
app.use('/api/delivery', require('./routes/riderRoutes'));
app.use('/api/deliveries', require('./routes/deliveryRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));

app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
