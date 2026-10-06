const request = require('supertest');
const app = require('../app');
const {
  isValidPhone,
  normalizePhone,
  isValidNIC,
  isValidVehiclePlate,
  isValidPostalCode,
} = require('../validators/authValidator');

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

describe('Sri Lankan Input Validation and Normalization', () => {
  test('validates valid Sri Lankan mobile and landline phone formats', () => {
    expect(isValidPhone('0771234567')).toBe(true);
    expect(isValidPhone('077 123 4567')).toBe(true);
    expect(isValidPhone('+94 77 123 4567')).toBe(true);
    expect(isValidPhone('+94771234567')).toBe(true);
    expect(isValidPhone('0112345678')).toBe(true);
    expect(isValidPhone('071-234-5678')).toBe(true);

    expect(isValidPhone('12345')).toBe(false);
    expect(isValidPhone('077123456789')).toBe(false);
    expect(isValidPhone('not_a_phone')).toBe(false);
  });

  test('normalizes Sri Lankan phone numbers consistently into international display format', () => {
    expect(normalizePhone('0771234567')).toBe('+94 77 123 4567');
    expect(normalizePhone('+94771234567')).toBe('+94 77 123 4567');
    expect(normalizePhone('+94 77 123 4567')).toBe('+94 77 123 4567');
    expect(normalizePhone('071-987-6543')).toBe('+94 71 987 6543');
  });

  test('validates both old (9 digits + V/X) and new (12 digits) Sri Lankan NIC formats', () => {
    expect(isValidNIC('981234567V')).toBe(true);
    expect(isValidNIC('981234567X')).toBe(true);
    expect(isValidNIC('981234567v')).toBe(true);
    expect(isValidNIC('200012345678')).toBe(true);
    expect(isValidNIC('199512345678')).toBe(true);

    expect(isValidNIC('12345')).toBe(false);
    expect(isValidNIC('981234567A')).toBe(false);
    expect(isValidNIC('12345678901234')).toBe(false);
  });

  test('validates Sri Lankan vehicle registration plate formats reasonably', () => {
    expect(isValidVehiclePlate('WP BDF-4821')).toBe(true);
    expect(isValidVehiclePlate('BDF-4821')).toBe(true);
    expect(isValidVehiclePlate('WP 123-4567')).toBe(true);
    expect(isValidVehiclePlate('64-1234')).toBe(true);
    expect(isValidVehiclePlate('WP CA 1234')).toBe(true);

    expect(isValidVehiclePlate('INVALID-PLATE-NUMBER-TOO-LONG')).toBe(false);
    expect(isValidVehiclePlate('123')).toBe(false);
  });

  test('validates Sri Lankan postal codes', () => {
    expect(isValidPostalCode('10250')).toBe(true);
    expect(isValidPostalCode('00100')).toBe(true);
    expect(isValidPostalCode('')).toBe(true); // Optional
    expect(isValidPostalCode('123')).toBe(false);
    expect(isValidPostalCode('ABCDE')).toBe(false);
  });
});
