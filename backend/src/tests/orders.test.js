const request = require('supertest');
const app = require('../app');

test('orders require authentication', async () => {
  const response = await request(app).get('/api/orders');
  expect(response.statusCode).toBe(401);
  expect(response.body.message).toBe('Authentication required');
});
