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

test('google login returns proper error for invalid or missing idToken', async () => {
  for (const role of ['customer', 'cook', 'rider']) {
    const response = await request(app)
      .post('/api/auth/google')
      .send({ idToken: 'invalid-token', role });
    expect([401, 503]).toContain(response.statusCode);
  }
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

describe('PendingRegistration Model and Registration Flow', () => {
  const PendingRegistration = require('../models/PendingRegistration');

  test('PendingRegistration is a Mongoose Model with findOneAndUpdate function', () => {
    expect(typeof PendingRegistration).toBe('function');
    expect(typeof PendingRegistration.findOneAndUpdate).toBe('function');
    expect(typeof PendingRegistration.findOne).toBe('function');
    expect(typeof PendingRegistration.deleteOne).toBe('function');
  });

  test('creates a valid PendingRegistration document with hashed password and verification hash', () => {
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const pending = new PendingRegistration({
      name: 'Nimal Perera',
      email: 'nimal@example.com',
      password: 'hashed_password_123',
      phone: '+94 77 123 4567',
      address: '42 Galle Road, Colombo 03',
      role: 'customer',
      verificationCodeHash: 'abcdef1234567890',
      verificationExpiresAt: expiresAt,
    });

    expect(pending.name).toBe('Nimal Perera');
    expect(pending.email).toBe('nimal@example.com');
    expect(pending.password).toBe('hashed_password_123');
    expect(pending.phone).toBe('+94 77 123 4567');
    expect(pending.address).toBe('42 Galle Road, Colombo 03');
    expect(pending.role).toBe('customer');
    expect(pending.verificationCodeHash).toBe('abcdef1234567890');
    expect(pending.verificationExpiresAt).toBe(expiresAt);
  });

  test('PendingRegistration model enforces required fields', () => {
    const invalidPending = new PendingRegistration({});
    const validationError = invalidPending.validateSync();

    expect(validationError).toBeDefined();
    expect(validationError.errors.name).toBeDefined();
    expect(validationError.errors.email).toBeDefined();
    expect(validationError.errors.password).toBeDefined();
    expect(validationError.errors.verificationCodeHash).toBeDefined();
    expect(validationError.errors.verificationExpiresAt).toBeDefined();
  });

  test('PendingRegistration supports rider vehicleDetails', () => {
    const pendingRider = new PendingRegistration({
      name: 'Kamal Silva',
      email: 'kamal@example.com',
      password: 'hashed_password_456',
      phone: '+94 71 234 5678',
      role: 'rider',
      vehicleDetails: {
        type: 'Motorbike',
        model: 'Honda Dio',
        plateNumber: 'WP BDF-4821',
      },
      verificationCodeHash: '123456abcdef',
      verificationExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
    });

    expect(pendingRider.role).toBe('rider');
    expect(pendingRider.vehicleDetails.plateNumber).toBe('WP BDF-4821');
  });

  test('PendingRegistration supports cook kitchenName', () => {
    const pendingCook = new PendingRegistration({
      name: 'Sunil Cook',
      email: 'sunil@example.com',
      password: 'hashed_password_789',
      phone: '+94 77 123 4567',
      address: '45/2 Galle Road, Colombo 03',
      kitchenName: "Sunil's Kitchen",
      role: 'cook',
      verificationCodeHash: 'abcdef789',
      verificationExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
    });

    expect(pendingCook.role).toBe('cook');
    expect(pendingCook.kitchenName).toBe("Sunil's Kitchen");
  });

  test('email verification endpoint rejects missing verification code', async () => {
    const response = await request(app)
      .post('/api/auth/verify-email')
      .send({ email: 'test@example.com', code: '' });

    expect(response.statusCode).toBe(400);
    expect(response.body.message).toBe('Verification code is required');
  });
});

describe('validateCookRegistration', () => {
  const { validateCookRegistration } = require('../validators/authValidator');

  test('validates valid cook registration data', () => {
    const errors = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'Password123',
    });
    expect(errors).toHaveLength(0);
  });

  test('rejects short name', () => {
    const errors = validateCookRegistration({
      name: 'A',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'Password123',
    });
    expect(errors).toContain('Enter your full name.');
  });

  test('rejects short kitchen name', () => {
    const errors = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: 'A',
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'Password123',
    });
    expect(errors).toContain('Enter your kitchen name.');
  });

  test('rejects invalid email', () => {
    const errors = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'invalid-email',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'Password123',
    });
    expect(errors).toContain('Enter a valid email address.');
  });

  test('rejects invalid phone number', () => {
    const errors = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '12345',
      address: '45/2 Galle Road, Colombo 03',
      password: 'Password123',
    });
    expect(errors).toContain('Enter a valid Sri Lankan phone number.');
  });

  test('rejects short address', () => {
    const errors = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: 'Col',
      password: 'Password123',
    });
    expect(errors).toContain('Enter your kitchen address.');
  });

  test('rejects password without minimum length or number', () => {
    const errors1 = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'short',
    });
    expect(errors1).toContain('Password must be at least 8 characters.');

    const errors2 = validateCookRegistration({
      name: 'Amara Fernando',
      kitchenName: "Amara's Kitchen",
      email: 'amara@gmail.com',
      phone: '0771234567',
      address: '45/2 Galle Road, Colombo 03',
      password: 'passwordonly',
    });
    expect(errors2).toContain('Password must include at least one number.');
  });
});

