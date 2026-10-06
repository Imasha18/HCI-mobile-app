function validateAuth(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(body.email.trim())) {
    errors.push('A valid email is required');
  }
  if (typeof body.password !== 'string' || body.password.trim().length < 6) {
    errors.push('Password must be at least 6 characters');
  }
  return errors;
}

function isValidPhone(phone) {
  if (typeof phone !== 'string') return false;
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, '');
  return /^(?:\+94|0094|94|0)?[1-9]\d{8}$/.test(cleaned);
}

function normalizePhone(phone) {
  if (!phone || typeof phone !== 'string') return '';
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, '');
  const match = cleaned.match(/^(?:\+94|0094|94|0)?([1-9]\d{8})$/);
  if (match) {
    const national = match[1];
    const prefix = national.substring(0, 2);
    const p1 = national.substring(2, 5);
    const p2 = national.substring(5);
    return `+94 ${prefix} ${p1} ${p2}`;
  }
  return phone.trim();
}

function isValidNIC(nic) {
  if (typeof nic !== 'string') return false;
  const cleaned = nic.trim().toUpperCase();
  return /^[0-9]{9}[VX]$/.test(cleaned) || /^[0-9]{12}$/.test(cleaned);
}

function isValidVehiclePlate(plate) {
  if (typeof plate !== 'string') return false;
  const cleaned = plate.trim().toUpperCase();
  return /^(?:(?:[A-Z]{2}[-\s]?)?[A-Z]{1,3}[-\s]?\d{4}|(?:[A-Z]{2}[-\s]?)?\d{2,3}[-\s]?\d{4})$/.test(cleaned);
}

function isValidPostalCode(postalCode) {
  if (!postalCode) return true;
  const cleaned = String(postalCode).trim();
  return /^\d{5}$/.test(cleaned);
}

function validateRegistration(body) {
  const errors = validateAuth(body);
  if (typeof body.name !== 'string' || body.name.trim().length < 2) {
    errors.push('Name is required when registering');
  }
  if (!body.role || body.role === 'customer') {
    if (typeof body.phone !== 'string' || !isValidPhone(body.phone)) {
      errors.push('A valid phone number is required (e.g. 077 123 4567 or +94 77 123 4567)');
    }
    if (typeof body.address !== 'string' || body.address.trim().length < 5) {
      errors.push('A complete delivery address is required');
    }
  }
  if (body.role === 'rider') {
    if (body.phone && !isValidPhone(body.phone)) {
      errors.push('A valid phone number is required');
    }
    const plate = body.vehiclePlateNumber || body.vehicleNumber || body.plateNumber;
    if (plate && !isValidVehiclePlate(plate)) {
      errors.push('A valid vehicle plate number is required (e.g. WP BDF-4821)');
    }
  }
  return errors;
}

function validatePasswordReset(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(body.email.trim())) {
    errors.push('A valid email is required');
  }
  if (typeof body.code !== 'string' || body.code.trim().length !== 6) {
    errors.push('A 6-digit reset code is required');
  }
  if (typeof body.password !== 'string' || body.password.trim().length < 6) {
    errors.push('Password must be at least 6 characters');
  }
  return errors;
}

module.exports = {
  validateAuth,
  validateRegistration,
  validatePasswordReset,
  isValidPhone,
  normalizePhone,
  isValidNIC,
  isValidVehiclePlate,
  isValidPostalCode,
};
