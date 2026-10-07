const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const environment = require('./config/environment');
const { notFoundMiddleware, errorMiddleware } = require('./middleware/errorMiddleware');

const app = express();

app.use(helmet());
app.use(cors({ origin: environment.clientOrigin === '*' ? true : environment.clientOrigin }));
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
app.use('/api/deliveries', require('./routes/deliveryRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));

app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
