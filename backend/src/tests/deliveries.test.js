const request = require('supertest');
const app = require('../app');

describe('Delivery Rider Module API Tests', () => {
  // Delivery CRUD & Workflow
  test('deliveries list endpoint requires authentication', async () => {
    const res = await request(app).get('/api/deliveries');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('create delivery endpoint requires authentication', async () => {
    const res = await request(app).post('/api/deliveries').send({
      deliveryFee: 350,
      notes: 'Please handle with care',
    });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('available deliveries endpoint requires authentication', async () => {
    const res = await request(app).get('/api/deliveries/available');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('delivery details endpoint requires authentication', async () => {
    const res = await request(app).get('/api/deliveries/674bd8d0d30123456789abcd');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('update delivery endpoint requires authentication', async () => {
    const res = await request(app)
      .put('/api/deliveries/674bd8d0d30123456789abcd')
      .send({ notes: 'Updated delivery instructions' });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('cancel delivery endpoint requires authentication', async () => {
    const res = await request(app)
      .patch('/api/deliveries/674bd8d0d30123456789abcd/cancel')
      .send({ reason: 'Customer requested cancellation' });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('delete delivery endpoint requires authentication', async () => {
    const res = await request(app).delete('/api/deliveries/674bd8d0d30123456789abcd');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('accept delivery requires authentication', async () => {
    const res = await request(app).patch('/api/deliveries/674bd8d0d30123456789abcd/accept');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('pickup delivery requires authentication', async () => {
    const res = await request(app).patch('/api/deliveries/674bd8d0d30123456789abcd/pickup');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('start delivery transit requires authentication', async () => {
    const res = await request(app).patch('/api/deliveries/674bd8d0d30123456789abcd/start');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('complete delivery requires authentication', async () => {
    const res = await request(app).patch('/api/deliveries/674bd8d0d30123456789abcd/complete');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  // Rider Endpoints
  test('rider dashboard requires authentication', async () => {
    const res = await request(app).get('/api/rider/dashboard');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('rider earnings requires authentication', async () => {
    const res = await request(app).get('/api/rider/earnings');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('rider profile requires authentication', async () => {
    const res = await request(app).get('/api/rider/profile');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('update rider profile requires authentication', async () => {
    const res = await request(app)
      .put('/api/rider/profile')
      .send({ name: 'Rider Name' });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('rider location update requires authentication', async () => {
    const res = await request(app)
      .patch('/api/rider/location')
      .send({ latitude: 6.9034, longitude: 79.8546 });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  // Notifications Endpoints
  test('notifications list endpoint requires authentication', async () => {
    const res = await request(app).get('/api/notifications');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('mark all notifications read requires authentication', async () => {
    const res = await request(app).patch('/api/notifications/read-all');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('mark notification read requires authentication', async () => {
    const res = await request(app).patch('/api/notifications/674bd8d0d30123456789abcd/read');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });

  test('delete notification requires authentication', async () => {
    const res = await request(app).delete('/api/notifications/674bd8d0d30123456789abcd');
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Authentication required');
  });
});
