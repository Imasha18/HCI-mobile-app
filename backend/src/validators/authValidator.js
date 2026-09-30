function validateAuth(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) errors.push('A valid email is required');
  if (typeof body.password !== 'string' || body.password.trim().length < 6) errors.push('Password must be at least 6 characters');
  return errors;
}

function validateRegistration(body) {
  const errors = validateAuth(body);
  if (typeof body.name !== 'string' || body.name.trim().length < 2) errors.push('Name is required when registering');
  return errors;
}

function validatePasswordReset(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) errors.push('A valid email is required');
  if (typeof body.code !== 'string' || body.code.trim().length !== 6) errors.push('A 6-digit reset code is required');
  if (typeof body.password !== 'string' || body.password.trim().length < 6) errors.push('Password must be at least 6 characters');
  return errors;
}

module.exports = { validateAuth, validateRegistration, validatePasswordReset };
