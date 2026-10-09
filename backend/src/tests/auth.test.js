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

test('registration rejects missing name, phone and address for customer', async () => {
  const response = await request(app)
    .post('/api/auth/register')
    .send({ email: 'missing-fields@example.com', password: 'HomeBite123!' });

  expect(response.statusCode).toBe(400);
  expect(response.body.details).toContain('Name is required when registering');
  expect(response.body.details).toContain('A valid phone number is required (e.g. 077 123 4567 or +94 77 123 4567)');
  expect(response.body.details).toContain('A complete delivery address is required');
});

test('registration rejects invalid phone number format', async () => {
  const response = await request(app)
    .post('/api/auth/register')
    .send({
      name: 'John Doe',
      email: 'john@example.com',
      password: 'HomeBite123!',
      phone: '12345',
      address: '25 Main Street, Nugegoda',
    });

  expect(response.statusCode).toBe(400);
  expect(response.body.details).toContain('A valid phone number is required (e.g. 077 123 4567 or +94 77 123 4567)');
});

test('forgot password routes reject missing credentials', async () => {
  const response = await request(app)
    .post('/api/auth/reset-password')
    .send({ email: '', code: '', password: '' });

  expect(response.statusCode).toBe(400);
});

test('cook registration rejects missing credentials', async () => {
  const response = await request(app)
    .post('/api/auth/register-cook')
    .send({ email: '' });

  expect(response.statusCode).toBe(400);
});

test('rider registration rejects missing credentials', async () => {
  const response = await request(app)
    .post('/api/auth/register-rider')
    .send({ email: '' });

  expect(response.statusCode).toBe(400);
});

test('resend-verification rejects missing email', async () => {
  const response = await request(app)
    .post('/api/auth/resend-verification')
    .send({});

  expect(response.statusCode).toBe(400);
  expect(response.body.message).toBe('Email is required');
});

