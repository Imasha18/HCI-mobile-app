function validateAuth(body) {
  const errors = [];
  if (!body.email || !/^\S+@\S+\.\S+$/.test(body.email)) errors.push('A valid email is required');
  if (!body.password || body.password.length < 6) errors.push('Password must be at least 6 characters');
  if (body.name === '' || (body.name === undefined && body.role !== undefined)) errors.push('Name is required when registering');
  return errors;
}

module.exports = { validateAuth };
