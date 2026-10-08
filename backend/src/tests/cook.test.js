const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../app');
const environment = require('../config/environment');

describe('Home Cook Module API Tests', () => {
  const cookId = '507f191e810c19729de860eb';
  const customerId = '507f191e810c19729de860ec';

  const cookToken = jwt.sign(
    { id: cookId, role: 'cook' },
    environment.jwtSecret,
    { expiresIn: '1h' }
  );

  const customerToken = jwt.sign(
    { id: customerId, role: 'customer' },
    environment.jwtSecret,
    { expiresIn: '1h' }
  );

  test('cook kitchen endpoint requires authentication', async () => {
    const res = await request(app).get('/api/cook/kitchen');
    expect(res.statusCode).toBe(401);
  });

  test('rejects customer from accessing cook kitchen endpoint with 403', async () => {
    const res = await request(app)
      .get('/api/cook/kitchen')
      .set('Authorization', `Bearer ${customerToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('cook bank details requires authentication', async () => {
    const res = await request(app).get('/api/cook/bank-details');
    expect(res.statusCode).toBe(401);
  });

  test('cook bank details update validates required fields', async () => {
    const res = await request(app)
      .put('/api/cook/bank-details')
      .set('Authorization', `Bearer ${cookToken}`)
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Account holder name is required/i);
  });

  test('cook bank details update rejects invalid account number format', async () => {
    const res = await request(app)
      .put('/api/cook/bank-details')
      .set('Authorization', `Bearer ${cookToken}`)
      .send({
        accountHolderName: 'Amara Perera',
        bankName: 'Commercial Bank',
        branchName: 'Kollupitiya',
        accountNumber: '123',
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Account number must contain 6 to 20 digits/i);
  });

  test('cook documents requires authentication', async () => {
    const res = await request(app).get('/api/cook/documents');
    expect(res.statusCode).toBe(401);
  });

  test('cook documents submission rejects invalid document type', async () => {
    const res = await request(app)
      .post('/api/cook/documents')
      .set('Authorization', `Bearer ${cookToken}`)
      .send({
        documentType: 'invalid_type',
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/Invalid document type/i);
  });

  test('cook settings requires authentication', async () => {
    const res = await request(app).get('/api/cook/settings');
    expect(res.statusCode).toBe(401);
  });

  test('cook meals requires authentication', async () => {
    const res = await request(app).get('/api/cook/meals');
    expect(res.statusCode).toBe(401);
  });
});
