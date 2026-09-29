const request = require('supertest');
const app = require('../app');

test('health endpoint reports the API is available', async () => {
  const response = await request(app).get('/api/health');
  expect(response.statusCode).toBe(200);
  expect(response.body.data.status).toBe('ok');
});

test('login rejects missing credentials', async () => {
  const response = await request(app)
    .post('/api/auth/login')
    .send({ email: '', password: '' });

  expect(response.statusCode).toBe(400);
  expect(response.body.details).toEqual([
    'A valid email is required',
    'Password must be at least 6 characters',
  ]);
});
