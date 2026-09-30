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

module.exports = { validateAuth, validateRegistration };
