const request = require('supertest');
const app = require('../app');
const jwt = require('jsonwebtoken');
const environment = require('../config/environment');

describe('Admin API Authentication and Authorization', () => {
  test('rejects unauthenticated requests to /api/admin/summary with 401', async () => {
    const response = await request(app).get('/api/admin/summary');
    expect(response.statusCode).toBe(401);
  });

  test('rejects non-admin token with 403 Forbidden', async () => {
    const customerToken = jwt.sign(
      { id: '507f191e810c19729de860ea', role: 'customer' },
      environment.jwtSecret,
      { expiresIn: '1h' }
    );
    const response = await request(app)
      .get('/api/admin/summary')
      .set('Authorization', `Bearer ${customerToken}`);
    expect(response.statusCode).toBe(403);
  });

  test('rejects cook token from admin routes with 403', async () => {
    const cookToken = jwt.sign(
      { id: '507f191e810c19729de860eb', role: 'cook' },
      environment.jwtSecret,
      { expiresIn: '1h' }
    );
    const response = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${cookToken}`);
    expect(response.statusCode).toBe(403);
  });
});
