const request = require('supertest');
const app = require('../app');

test('unknown meal ids return a structured 404', async () => {
  const response = await request(app).get('/api/meals/unknown-route');
  expect(response.statusCode).toBe(404);
  expect(response.body.success).toBe(false);
});
