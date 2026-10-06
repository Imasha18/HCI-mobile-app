const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../app');
const environment = require('../config/environment');
const {
  normalizeDocKey,
  normalizeVerificationDocuments,
  calculateRiderVerificationStatus,
} = require('../controllers/riderController');

describe('Rider Document Verification & Profile Tests', () => {
  describe('Authentication & Access Control', () => {
    test('verification status endpoint requires authentication', async () => {
      const res = await request(app).get('/api/rider/verification');
      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Authentication required');
    });

    test('document upload endpoint requires authentication', async () => {
      const res = await request(app).post('/api/rider/documents/upload').send({
        fileUrl: 'https://example.com/doc.pdf',
      });
      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Authentication required');
    });

    test('verification submit endpoint requires authentication', async () => {
      const res = await request(app).post('/api/rider/verification/submit').send({
        documents: {},
      });
      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Authentication required');
    });

    test('admin rider verify endpoint requires admin authentication', async () => {
      const res = await request(app).patch('/api/admin/riders/674bd8d0d30123456789abcd/verify').send({
        status: 'approved',
      });
      expect(res.statusCode).toBe(401);
    });

    test('rider profile update endpoint requires authentication', async () => {
      const res = await request(app).put('/api/rider/profile').send({
        vehicleDetails: { type: 'Motorbike', model: 'Honda Dio', plateNumber: 'WP BDF-4821' },
      });
      expect(res.statusCode).toBe(401);
    });

    test('rider cannot access admin rider verify endpoint (403 Forbidden)', async () => {
      const riderToken = jwt.sign(
        { id: '674bd8d0d30123456789abcd', role: 'rider' },
        environment.jwtSecret,
        { expiresIn: '1h' }
      );
      const res = await request(app)
        .patch('/api/admin/riders/674bd8d0d30123456789abcd/verify')
        .set('Authorization', `Bearer ${riderToken}`)
        .send({ status: 'approved' });
      expect(res.statusCode).toBe(403);
    });

    test('customer cannot access admin rider verify endpoint (403 Forbidden)', async () => {
      const customerToken = jwt.sign(
        { id: '674bd8d0d30123456789abce', role: 'customer' },
        environment.jwtSecret,
        { expiresIn: '1h' }
      );
      const res = await request(app)
        .patch('/api/admin/riders/674bd8d0d30123456789abcd/verify')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ status: 'approved' });
      expect(res.statusCode).toBe(403);
    });

    test('admin rider verify rejects invalid status', async () => {
      const adminToken = jwt.sign(
        { id: '674bd8d0d30123456789abcf', role: 'admin' },
        environment.jwtSecret,
        { expiresIn: '1h' }
      );
      const res = await request(app)
        .patch('/api/admin/riders/674bd8d0d30123456789abcd/verify')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'invalid_status' });
      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('Status must be approved or rejected');
    });

    test('admin rider verify rejects rejection without a reason', async () => {
      const adminToken = jwt.sign(
        { id: '674bd8d0d30123456789abcf', role: 'admin' },
        environment.jwtSecret,
        { expiresIn: '1h' }
      );
      const res = await request(app)
        .patch('/api/admin/riders/674bd8d0d30123456789abcd/verify')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'rejected' });
      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('Please provide a reason for rejecting the verification request.');
    });
  });

  describe('normalizeDocKey Helper', () => {
    test('normalizes variants of NIC key', () => {
      expect(normalizeDocKey('nic')).toBe('nic');
      expect(normalizeDocKey('NIC')).toBe('nic');
      expect(normalizeDocKey('national_id')).toBe('nic');
      expect(normalizeDocKey('nationalId')).toBe('nic');
      expect(normalizeDocKey('id_card')).toBe('nic');
    });

    test('normalizes variants of Driving License key', () => {
      expect(normalizeDocKey('driving_license')).toBe('drivingLicense');
      expect(normalizeDocKey('drivingLicense')).toBe('drivingLicense');
      expect(normalizeDocKey('Driving_License')).toBe('drivingLicense');
      expect(normalizeDocKey('license')).toBe('drivingLicense');
    });

    test('normalizes variants of Vehicle Document key', () => {
      expect(normalizeDocKey('vehicle_document')).toBe('vehicleDocument');
      expect(normalizeDocKey('vehicleDocument')).toBe('vehicleDocument');
      expect(normalizeDocKey('vehicle_registration')).toBe('vehicleDocument');
      expect(normalizeDocKey('revenue_license')).toBe('vehicleDocument');
    });

    test('normalizes variants of Insurance key', () => {
      expect(normalizeDocKey('insurance')).toBe('insurance');
      expect(normalizeDocKey('vehicle_insurance')).toBe('insurance');
      expect(normalizeDocKey('vehicleInsurance')).toBe('insurance');
    });
  });

  describe('normalizeVerificationDocuments Helper', () => {
    test('provides clean structure with 4 required document slots', () => {
      const normalized = normalizeVerificationDocuments();
      expect(normalized).toHaveProperty('nic');
      expect(normalized).toHaveProperty('drivingLicense');
      expect(normalized).toHaveProperty('vehicleDocument');
      expect(normalized).toHaveProperty('insurance');

      expect(normalized.nic.status).toBe('not_submitted');
      expect(normalized.nic.fileUrl).toBe('');
      expect(normalized.drivingLicense.status).toBe('not_submitted');
      expect(normalized.vehicleDocument.status).toBe('not_submitted');
      expect(normalized.insurance.status).toBe('not_submitted');
    });

    test('preserves existing document records and maps snake_case keys', () => {
      const existing = {
        driving_license: {
          fileUrl: 'https://storage.homebite.lk/license.jpg',
          fileName: 'license.jpg',
          status: 'approved',
          rejectionReason: null,
          approvedAt: '2026-10-01T00:00:00.000Z',
          approvedBy: 'admin123',
        },
      };
      const normalized = normalizeVerificationDocuments(existing);
      expect(normalized.drivingLicense.fileUrl).toBe('https://storage.homebite.lk/license.jpg');
      expect(normalized.drivingLicense.status).toBe('approved');
      expect(normalized.drivingLicense.approvedBy).toBe('admin123');
      expect(normalized.nic.status).toBe('not_submitted');
    });
  });

  describe('calculateRiderVerificationStatus Helper', () => {
    test('returns not_submitted when all documents are empty', () => {
      const result = calculateRiderVerificationStatus({});
      expect(result.verificationStatus).toBe('not_submitted');
      expect(result.isVerified).toBe(false);
    });

    test('returns pending when at least one document is pending and none rejected', () => {
      const docs = {
        nic: { fileUrl: 'https://storage.com/nic.jpg', status: 'pending' },
        drivingLicense: { fileUrl: 'https://storage.com/dl.jpg', status: 'approved' },
        vehicleDocument: { fileUrl: '', status: 'not_submitted' },
        insurance: { fileUrl: '', status: 'not_submitted' },
      };
      const result = calculateRiderVerificationStatus(docs);
      expect(result.verificationStatus).toBe('pending');
      expect(result.isVerified).toBe(false);
    });

    test('returns rejected when any document is rejected even if others are approved', () => {
      const docs = {
        nic: { fileUrl: 'https://storage.com/nic.jpg', status: 'approved' },
        drivingLicense: { fileUrl: 'https://storage.com/dl.jpg', status: 'rejected', rejectionReason: 'Blurry photo' },
        vehicleDocument: { fileUrl: 'https://storage.com/vd.jpg', status: 'approved' },
        insurance: { fileUrl: 'https://storage.com/ins.jpg', status: 'approved' },
      };
      const result = calculateRiderVerificationStatus(docs);
      expect(result.verificationStatus).toBe('rejected');
      expect(result.isVerified).toBe(false);
    });

    test('returns approved and isVerified: true ONLY when all 4 documents are approved with URLs', () => {
      const docs = {
        nic: { fileUrl: 'https://storage.com/nic.jpg', status: 'approved' },
        drivingLicense: { fileUrl: 'https://storage.com/dl.jpg', status: 'approved' },
        vehicleDocument: { fileUrl: 'https://storage.com/vd.jpg', status: 'approved' },
        insurance: { fileUrl: 'https://storage.com/ins.jpg', status: 'approved' },
      };
      const result = calculateRiderVerificationStatus(docs);
      expect(result.verificationStatus).toBe('approved');
      expect(result.isVerified).toBe(true);
    });

    test('does NOT approve if 4 docs are marked approved but fileUrl is missing', () => {
      const docs = {
        nic: { fileUrl: 'https://storage.com/nic.jpg', status: 'approved' },
        drivingLicense: { fileUrl: 'https://storage.com/dl.jpg', status: 'approved' },
        vehicleDocument: { fileUrl: 'https://storage.com/vd.jpg', status: 'approved' },
        insurance: { fileUrl: '', status: 'approved' }, // missing url
      };
      const result = calculateRiderVerificationStatus(docs);
      expect(result.verificationStatus).toBe('not_submitted');
      expect(result.isVerified).toBe(false);
    });
  });
});

