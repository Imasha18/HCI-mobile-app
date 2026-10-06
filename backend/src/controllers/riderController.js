const mongoose = require('mongoose');
const User = require('../models/User');
const Delivery = require('../models/Delivery');
const Earning = require('../models/Earning');
const Location = require('../models/Location');
const Notification = require('../models/Notification');
const { sendSuccess } = require('../utils/apiResponse');
const { uploadImage } = require('../services/imageService');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { normalizePhone } = require('../validators/authValidator');

// Helper to normalize document key from snake_case or camelCase or aliases
function normalizeDocKey(key) {
  if (!key) return null;
  const k = String(key).toLowerCase().replace(/[-_]/g, '');
  if (k === 'nic' || k === 'nationalid' || k === 'idcard') return 'nic';
  if (k === 'drivinglicense' || k === 'license') return 'drivingLicense';
  if (k === 'vehicledocument' || k === 'vehicleregistration' || k === 'revenuelicense') return 'vehicleDocument';
  if (k === 'insurance' || k === 'vehicleinsurance') return 'insurance';
  return key;
}

// Helper to normalize verificationDocuments into consistent 4-document structure
function normalizeVerificationDocuments(docs) {
  const defaultDoc = (type) => ({
    type,
    fileUrl: '',
    fileName: '',
    status: 'not_submitted',
    rejectionReason: null,
    uploadedAt: null,
    approvedAt: null,
    approvedBy: null,
  });

  const standardKeys = ['nic', 'drivingLicense', 'vehicleDocument', 'insurance'];
  const result = {
    nic: defaultDoc('nic'),
    drivingLicense: defaultDoc('drivingLicense'),
    vehicleDocument: defaultDoc('vehicleDocument'),
    insurance: defaultDoc('insurance'),
  };

  if (!docs || typeof docs !== 'object' || Array.isArray(docs)) {
    return result;
  }

  for (const [rawKey, d] of Object.entries(docs)) {
    const key = normalizeDocKey(rawKey);
    if (!key || !standardKeys.includes(key)) continue;

    if (d && typeof d === 'object') {
      result[key] = {
        type: key,
        fileUrl: d.fileUrl || d.documentUrl || '',
        fileName: d.fileName || d.title || (key ? `${key} Document` : ''),
        status: d.status || 'not_submitted',
        rejectionReason: d.rejectionReason || null,
        uploadedAt: d.uploadedAt || null,
        approvedAt: d.approvedAt || null,
        approvedBy: d.approvedBy || null,
      };
    }
  }
  return result;
}

// Helper to calculate overall rider verification status from documents
function calculateRiderVerificationStatus(docs) {
  const normalized = normalizeVerificationDocuments(docs);
  const requiredKeys = ['nic', 'drivingLicense', 'vehicleDocument', 'insurance'];

  // 1. If any required doc is rejected -> rejected
  const hasRejected = requiredKeys.some((k) => normalized[k].status === 'rejected');
  if (hasRejected) {
    return { verificationStatus: 'rejected', isVerified: false };
  }

  // 2. If any required doc is pending -> pending
  const hasPending = requiredKeys.some((k) => normalized[k].status === 'pending');
  if (hasPending) {
    return { verificationStatus: 'pending', isVerified: false };
  }

  // 3. If all 4 required docs have a fileUrl and status === 'approved' -> approved
  const allApproved = requiredKeys.every(
    (k) => Boolean(normalized[k].fileUrl) && normalized[k].status === 'approved'
  );
  if (allApproved) {
    return { verificationStatus: 'approved', isVerified: true };
  }

  // 4. Default: not_submitted
  return { verificationStatus: 'not_submitted', isVerified: false };
}

// GET /api/rider/profile
async function getRiderProfile(req, res) {
  const rider = await User.findById(req.user.id).select('-password');
  if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });

  const riderObj = rider.toObject();
  riderObj.verificationStatus = riderObj.verificationStatus || 'not_submitted';
  riderObj.isVerified = riderObj.isVerified ?? (riderObj.verificationStatus === 'approved');
  riderObj.verificationDocuments = normalizeVerificationDocuments(riderObj.verificationDocuments);

  return sendSuccess(res, riderObj);
}

// PUT or PATCH /api/rider/profile or /api/delivery/profile
async function updateRiderProfile(req, res) {
  try {
    const rider = await User.findById(req.user.id);
    if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });

    // 1. Partial updates for allowed profile fields
    if (req.body.name !== undefined) {
      const trimmed = String(req.body.name).trim();
      if (!trimmed) {
        return res.status(400).json({ success: false, message: 'Name cannot be empty' });
      }
      rider.name = trimmed;
    }

    if (req.body.phone !== undefined) {
      rider.phone = normalizePhone(String(req.body.phone).trim());
    }

    if (req.body.address !== undefined) {
      rider.address = String(req.body.address).trim();
    }

    if (req.body.profileImage !== undefined) {
      rider.profileImage = String(req.body.profileImage).trim();
    }

    if (req.body.isOnline !== undefined) {
      rider.isOnline = Boolean(req.body.isOnline);
    }

    // 2. Partial updates for vehicle details without overwriting existing data with null
    if (!rider.vehicleDetails) {
      rider.vehicleDetails = { type: 'Motorbike', model: '', plateNumber: '' };
    }

    // Nested object support: vehicleDetails: { type, model, plateNumber }
    if (req.body.vehicleDetails && typeof req.body.vehicleDetails === 'object') {
      if (req.body.vehicleDetails.type !== undefined) {
        rider.vehicleDetails.type = String(req.body.vehicleDetails.type).trim();
      }
      if (req.body.vehicleDetails.model !== undefined) {
        rider.vehicleDetails.model = String(req.body.vehicleDetails.model).trim();
      }
      const plate = req.body.vehicleDetails.plateNumber ?? req.body.vehicleDetails.vehicleNumber;
      if (plate !== undefined) {
        rider.vehicleDetails.plateNumber = String(plate).trim().toUpperCase();
      }
    }

    // Direct / flat fields support (e.g. vehicleNumber, vehicleType, vehicleModel)
    const directPlate = req.body.vehicleNumber ?? req.body.vehiclePlateNumber ?? req.body.plateNumber;
    if (directPlate !== undefined) {
      rider.vehicleDetails.plateNumber = String(directPlate).trim().toUpperCase();
    }

    const directType = req.body.vehicleType ?? req.body.type;
    if (directType !== undefined) {
      rider.vehicleDetails.type = String(directType).trim();
    }

    const directModel = req.body.vehicleModel ?? req.body.model;
    if (directModel !== undefined) {
      rider.vehicleDetails.model = String(directModel).trim();
    }

    // 3. Optional partial update for verification documents
    if (req.body.verificationDocuments && typeof req.body.verificationDocuments === 'object') {
      const incomingDocs = req.body.verificationDocuments;
      const currentDocs = normalizeVerificationDocuments(rider.verificationDocuments);
      for (const rawKey of Object.keys(incomingDocs)) {
        const key = normalizeDocKey(rawKey);
        if (key && ['nic', 'drivingLicense', 'vehicleDocument', 'insurance'].includes(key)) {
          const item = incomingDocs[rawKey];
          if (item && typeof item === 'object') {
            const hasNewFile = item.fileUrl && String(item.fileUrl).trim() !== currentDocs[key].fileUrl;
            currentDocs[key] = {
              type: key,
              fileUrl: item.fileUrl !== undefined ? String(item.fileUrl).trim() : currentDocs[key].fileUrl,
              fileName: item.fileName !== undefined ? String(item.fileName).trim() : currentDocs[key].fileName,
              status: hasNewFile ? 'pending' : (currentDocs[key].status || 'not_submitted'),
              rejectionReason: hasNewFile ? null : currentDocs[key].rejectionReason,
              uploadedAt: hasNewFile ? new Date() : currentDocs[key].uploadedAt,
              approvedAt: hasNewFile ? null : currentDocs[key].approvedAt,
              approvedBy: hasNewFile ? null : currentDocs[key].approvedBy,
            };
          }
        }
      }
      const { verificationStatus, isVerified } = calculateRiderVerificationStatus(currentDocs);
      rider.verificationDocuments = currentDocs;
      rider.verificationStatus = verificationStatus;
      rider.isVerified = isVerified;
      rider.markModified('verificationDocuments');
    }

    // Explicitly mark modified for embedded Mongoose subdocument
    rider.markModified('vehicleDetails');
    await rider.save();

    const updated = await User.findById(rider._id).select('-password');
    const riderObj = updated.toObject();
    riderObj.verificationStatus = riderObj.verificationStatus || 'not_submitted';
    riderObj.isVerified = riderObj.isVerified ?? (riderObj.verificationStatus === 'approved');
    riderObj.verificationDocuments = normalizeVerificationDocuments(riderObj.verificationDocuments);

    return sendSuccess(res, riderObj, 'Profile updated successfully');
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

// POST /api/rider/documents or PATCH /api/rider/documents/:type or POST /api/rider/documents/upload
async function uploadOrSaveRiderDocument(req, res) {
  try {
    const rawType = req.params.type || req.params.documentKey || req.body.type || req.body.documentType || req.body.key;
    const documentKey = normalizeDocKey(rawType);

    let fileUrl = req.body.fileUrl || req.body.url;
    let fileName = req.body.fileName || req.body.name || (documentKey ? `${documentKey} Document` : 'document');

    if (req.file) {
      fileName = req.file.originalname || fileName;
      const uploaded = await uploadImage(req.file, 'homebite/documents');
      if (uploaded) fileUrl = uploaded;
    }

    if (!fileUrl) {
      return res.status(400).json({ success: false, message: 'No file or document URL provided' });
    }

    // If no specific document type is requested, return the uploaded file info (generic upload)
    if (!documentKey) {
      return sendSuccess(res, {
        fileUrl,
        fileName,
        uploadedAt: new Date(),
      }, 'Document uploaded successfully');
    }

    const rider = await User.findById(req.user.id);
    if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });

    const currentDocs = normalizeVerificationDocuments(rider.verificationDocuments);

    // Update the specific document
    // NOTE: Rider CANNOT self-approve. Re-upload or replace resets status to pending!
    currentDocs[documentKey] = {
      type: documentKey,
      fileUrl: String(fileUrl).trim(),
      fileName: String(fileName).trim(),
      status: 'pending',
      rejectionReason: null,
      uploadedAt: new Date(),
      approvedAt: null,
      approvedBy: null,
    };

    const { verificationStatus, isVerified } = calculateRiderVerificationStatus(currentDocs);

    rider.verificationDocuments = currentDocs;
    rider.verificationStatus = verificationStatus;
    rider.isVerified = isVerified;
    rider.markModified('verificationDocuments');
    await rider.save();

    // Notify admins of new/updated document upload
    const admins = await User.find({ role: 'admin' }).select('_id');
    for (const admin of admins) {
      await Notification.create({
        user: admin._id,
        title: 'Rider Document Uploaded',
        body: `${rider.name} uploaded/updated their ${documentKey} document for review.`,
      }).catch(() => {});
    }

    const updated = await User.findById(rider._id).select('-password');
    const riderObj = updated.toObject();
    riderObj.verificationDocuments = normalizeVerificationDocuments(riderObj.verificationDocuments);

    return sendSuccess(res, riderObj, 'Document saved and submitted for admin review successfully');
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

// POST /api/rider/documents/upload (alias for uploadOrSaveRiderDocument)
async function uploadDocument(req, res) {
  return uploadOrSaveRiderDocument(req, res);
}

// POST /api/rider/verification/submit
async function submitVerification(req, res) {
  try {
    let currentDocs = normalizeVerificationDocuments();
    let rider = null;

    if (mongoose.connection.readyState === 1) {
      rider = await User.findById(req.user.id);
      if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });
      currentDocs = normalizeVerificationDocuments(rider.verificationDocuments);
    }

    const incomingDocs = req.body.documents || {};
    const requiredKeys = ['nic', 'drivingLicense', 'vehicleDocument', 'insurance'];
    const mergedDocs = { ...currentDocs };

    for (const key of requiredKeys) {
      if (incomingDocs[key] && typeof incomingDocs[key] === 'object') {
        const item = incomingDocs[key];
        if (item.fileUrl) {
          mergedDocs[key] = {
            fileUrl: String(item.fileUrl).trim(),
            fileName: String(item.fileName || key).trim(),
            status: 'pending',
            rejectionReason: null,
            uploadedAt: new Date(),
          };
        }
      }
    }

    // Verify all 4 required documents have a non-empty fileUrl
    const missingDocs = [];
    if (!mergedDocs.nic.fileUrl) missingDocs.push('National ID (NIC)');
    if (!mergedDocs.drivingLicense.fileUrl) missingDocs.push('Driving License');
    if (!mergedDocs.vehicleDocument.fileUrl) missingDocs.push('Vehicle Revenue License');
    if (!mergedDocs.insurance.fileUrl) missingDocs.push('Vehicle Insurance');

    if (missingDocs.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Please upload all required documents before submitting for verification.',
        missing: missingDocs,
      });
    }

    // Mark non-approved documents as pending review
    for (const key of requiredKeys) {
      if (mergedDocs[key].status !== 'approved') {
        mergedDocs[key].status = 'pending';
        mergedDocs[key].rejectionReason = null;
        mergedDocs[key].uploadedAt = mergedDocs[key].uploadedAt || new Date();
      }
    }

    if (rider) {
      rider.verificationDocuments = mergedDocs;
      rider.verificationStatus = 'pending';
      rider.isVerified = false;
      rider.markModified('verificationDocuments');
      await rider.save();

      // Notify admins of new pending verification
      const admins = await User.find({ role: 'admin' }).select('_id');
      for (const admin of admins) {
        await Notification.create({
          user: admin._id,
          title: 'New Rider Verification Request',
          body: `${rider.name} submitted all required documents for delivery partner verification.`,
        }).catch(() => {});
      }
    }

    const riderObj = rider ? rider.toObject() : { verificationStatus: 'pending' };
    delete riderObj.password;
    riderObj.verificationDocuments = mergedDocs;

    return sendSuccess(
      res,
      riderObj,
      'Documents submitted for verification successfully. Waiting for admin approval.'
    );
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

// GET /api/rider/dashboard
async function getRiderDashboard(req, res) {
  const riderId = req.user.id;
  const rider = await User.findById(riderId).select(
    'name email phone address profileImage isOnline rating vehicleDetails isVerified verificationStatus verificationDocuments'
  );

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  // Today's completed deliveries
  const todayDeliveriesDocs = await Delivery.find({
    rider: riderId,
    status: 'DELIVERED',
    updatedAt: { $gte: startOfToday },
  });

  const todayDeliveries = todayDeliveriesDocs.length;
  const distanceTravelled = todayDeliveriesDocs.reduce((sum, d) => sum + (d.distanceKm || 0), 0);

  // Today's earnings
  const todayEarningsDocs = await Earning.find({
    riderId,
    date: { $gte: startOfToday },
  });
  const todayEarnings = todayEarningsDocs.reduce((sum, e) => sum + (e.amount || 0), 0);

  // Current active delivery (ACCEPTED, PICKED_UP, or IN_TRANSIT)
  const currentDelivery = await Delivery.findOne({
    rider: riderId,
    status: { $in: ['ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'] },
  })
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, {
    rider: {
      id: rider?._id || riderId,
      _id: rider?._id || riderId,
      name: rider?.name || 'HomeBite Rider',
      email: rider?.email || '',
      phone: rider?.phone || '',
      address: rider?.address || '',
      profileImage: rider?.profileImage || '',
      isOnline: rider?.isOnline ?? true,
      rating: rider?.rating || 5.0,
      isVerified: rider?.isVerified ?? (rider?.verificationStatus === 'approved'),
      verificationStatus: rider?.verificationStatus || 'not_submitted',
      verificationDocuments: normalizeVerificationDocuments(rider?.verificationDocuments),
      vehicleDetails: {
        type: rider?.vehicleDetails?.type || 'Motorbike',
        model: rider?.vehicleDetails?.model || '',
        plateNumber: rider?.vehicleDetails?.plateNumber || '',
      },
    },
    statistics: {
      todayDeliveries,
      todayEarnings,
      rating: rider?.rating || 5.0,
      distanceTravelled: Number(distanceTravelled.toFixed(1)),
    },
    currentDelivery,
  });
}

// GET /api/rider/deliveries (History)
async function getRiderDeliveries(req, res) {
  const riderId = req.user.id;
  const filter = { rider: riderId };

  if (req.query.status && req.query.status !== 'ALL') {
    filter.status = req.query.status.toUpperCase();
  }

  const { page, limit, skip } = parsePagination(req.query, 10);
  const total = await Delivery.countDocuments(filter);

  const deliveries = await Delivery.find(filter)
    .populate({
      path: 'orderId',
      populate: { path: 'items.meal', select: 'name imageUrl price category' },
    })
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  return sendSuccess(res, deliveries, 'Success', 200, buildPaginationMeta(page, limit, total, deliveries.length));
}

// GET /api/rider/earnings
async function getRiderEarnings(req, res) {
  const riderId = req.user.id;

  const earnings = await Earning.find({ riderId }).sort({ date: -1 });
  const totalEarnings = earnings.reduce((sum, e) => sum + e.amount, 0);

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfToday)
    .reduce((sum, e) => sum + e.amount, 0);

  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);
  const weeklyEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfWeek)
    .reduce((sum, e) => sum + e.amount, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthlyEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfMonth)
    .reduce((sum, e) => sum + e.amount, 0);

  const dailyBreakdown = [];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const dayEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);

    const dayEarnings = earnings
      .filter((e) => new Date(e.date) >= dayStart && new Date(e.date) < dayEnd)
      .reduce((sum, e) => sum + e.amount, 0);

    const deliveryCount = await Delivery.countDocuments({
      rider: riderId,
      status: 'DELIVERED',
      updatedAt: { $gte: dayStart, $lt: dayEnd },
    });

    dailyBreakdown.push({
      day: days[d.getDay()],
      date: d.toISOString().split('T')[0],
      amount: dayEarnings,
      deliveries: deliveryCount,
    });
  }

  return sendSuccess(res, {
    totalEarnings,
    todayEarnings,
    weeklyEarnings,
    monthlyEarnings,
    dailyBreakdown,
  });
}

// PATCH /api/rider/location
async function updateRiderLocation(req, res) {
  const { latitude, longitude } = req.body;
  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ success: false, message: 'Latitude and longitude are required' });
  }

  const loc = await Location.create({
    riderId: req.user.id,
    latitude: Number(latitude),
    longitude: Number(longitude),
    timestamp: new Date(),
  });

  return sendSuccess(res, loc, 'Location updated successfully');
}

module.exports = {
  getRiderProfile,
  updateRiderProfile,
  uploadDocument,
  uploadOrSaveRiderDocument,
  submitVerification,
  getRiderDashboard,
  getRiderDeliveries,
  getRiderEarnings,
  updateRiderLocation,
  normalizeDocKey,
  normalizeVerificationDocuments,
  calculateRiderVerificationStatus,
};
