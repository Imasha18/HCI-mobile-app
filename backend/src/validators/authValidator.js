function validateAuth(body) {
  const errors = [];
  if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) errors.push('A valid email is required');
  if (typeof body.password !== 'string' || body.password.trim().length < 6) errors.push('Password must be at least 6 characters');
  if (body.name === '' || (body.name === undefined && body.role !== undefined)) errors.push('Name is required when registering');
  return errors;
}

module.exports = { validateAuth };
