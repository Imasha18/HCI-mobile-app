const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../app');
const Order = require('../models/Order');
const environment = require('../config/environment');

test('orders require authentication', async () => {
  const response = await request(app).get('/api/orders');
  expect(response.statusCode).toBe(401);
  expect(response.body.message).toBe('Authentication required');
});

test('Order model stores deliveryAddress snapshot as an object with address and phone', () => {
  const order = new Order({
    customer: '507f191e810c19729de860ea',
    items: [{ price: 350, quantity: 2, name: 'Rice & Curry' }],
    total: 700,
    deliveryAddress: {
      address: '25 Main Street, Nugegoda',
      phone: '077 123 4567',
    },
    deliveryPhone: '077 123 4567',
  });

  expect(order.deliveryAddress).toEqual({
    address: '25 Main Street, Nugegoda',
    phone: '077 123 4567',
  });
  expect(order.deliveryPhone).toBe('077 123 4567');
});

test('Order model maintains legacy deliveryAddress string compatibility', () => {
  const legacyOrder = new Order({
    customer: '507f191e810c19729de860ea',
    items: [{ price: 350, quantity: 1, name: 'Kottu' }],
    total: 350,
    deliveryAddress: '18 Flower Road, Colombo 07',
  });

  expect(legacyOrder.deliveryAddress).toBe('18 Flower Road, Colombo 07');
});

test('rejects customer from accepting order with 403 Forbidden', async () => {
  const customerToken = jwt.sign(
    { id: '507f191e810c19729de860ea', role: 'customer' },
    environment.jwtSecret,
    { expiresIn: '1h' }
  );

  const res = await request(app)
    .patch('/api/orders/507f191e810c19729de860eb/accept')
    .set('Authorization', `Bearer ${customerToken}`);

  expect(res.statusCode).toBe(403);
});

test('rejects customer from rejecting order with 403 Forbidden', async () => {
  const customerToken = jwt.sign(
    { id: '507f191e810c19729de860ea', role: 'customer' },
    environment.jwtSecret,
    { expiresIn: '1h' }
  );

  const res = await request(app)
    .patch('/api/orders/507f191e810c19729de860eb/reject')
    .set('Authorization', `Bearer ${customerToken}`);

  expect(res.statusCode).toBe(403);
});
