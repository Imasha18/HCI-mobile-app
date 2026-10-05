function validateAuth(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) errors.push('A valid email is required');
  if (typeof body.password !== 'string' || body.password.trim().length < 6) errors.push('Password must be at least 6 characters');
  return errors;
}

function isValidPhone(phone) {
  if (typeof phone !== 'string') return false;
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, '');
  return /^(?:\+94|0094|94|0)?[1-9]\d{8}$/.test(cleaned);
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
  return errors;
}

function validatePasswordReset(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) errors.push('A valid email is required');
  if (typeof body.code !== 'string' || body.code.trim().length !== 6) errors.push('A 6-digit reset code is required');
  if (typeof body.password !== 'string' || body.password.trim().length < 6) errors.push('Password must be at least 6 characters');
  return errors;
}

module.exports = { validateAuth, validateRegistration, validatePasswordReset, isValidPhone };
