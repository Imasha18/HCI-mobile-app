const { OAuth2Client } = require('google-auth-library');
const environment = require('../config/environment');

/**
 * Verifies Google credentials sent by the Flutter app and returns only
 * Google-verified identity fields. Nothing sent by the client (email, name...)
 * is trusted directly.
 *
 * - Android / iOS send an ID token (JWT) minted for our Web client ID
 *   (serverClientId). Verified offline against Google's signing keys.
 * - Flutter Web (google_sign_in_web / Google Identity Services) returns an
 *   OAuth access token instead of an ID token. It is verified with Google's
 *   tokeninfo endpoint, and its audience must be one of our client IDs, so a
 *   token issued to some other app cannot be replayed here.
 */

class GoogleAuthError extends Error {
  constructor(message, status = 401) {
    super(message);
    this.status = status;
  }
}

function allowedAudiences() {
  return String(environment.googleClientId || '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
}

let client;
function getClient() {
  if (!client) client = new OAuth2Client();
  return client;
}

async function verifyIdToken(idToken, audiences) {
  const ticket = await getClient().verifyIdToken({ idToken, audience: audiences });
  const payload = ticket.getPayload() || {};
  return {
    sub: payload.sub,
    email: payload.email,
    emailVerified: payload.email_verified === true || payload.email_verified === 'true',
    name: payload.name,
    picture: payload.picture,
  };
}

async function verifyAccessToken(accessToken, audiences) {
  const info = await getClient().getTokenInfo(accessToken);
  const audienceOk = audiences.includes(info.aud) || audiences.includes(info.azp);
  if (!audienceOk) {
    throw new GoogleAuthError('Google token was not issued for HomeBite');
  }

  // Name / picture are not part of tokeninfo; fetch them with the same token.
  let profile = {};
  try {
    const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (response.ok) profile = await response.json();
  } catch (_) {
    // Profile details are optional; identity is already verified above.
  }

  // Identity fields come from tokeninfo (bound to the verified audience);
  // userinfo must refer to the same Google account to be used.
  if (profile.sub && profile.sub !== info.sub) profile = {};

  return {
    sub: info.sub,
    email: info.email,
    emailVerified: info.email_verified === true || info.email_verified === 'true',
    name: profile.name,
    picture: profile.picture,
  };
}

async function verifyGoogleCredential({ idToken, accessToken } = {}) {
  const audiences = allowedAudiences();
  if (audiences.length === 0) {
    throw new GoogleAuthError('Google authentication is not configured', 503);
  }
  if (typeof idToken !== 'string' && typeof accessToken !== 'string') {
    throw new GoogleAuthError('Google credential is required', 400);
  }

  let identity;
  try {
    identity = idToken
      ? await verifyIdToken(idToken, audiences)
      : await verifyAccessToken(accessToken, audiences);
  } catch (error) {
    if (error instanceof GoogleAuthError) throw error;
    throw new GoogleAuthError('Google sign-in could not be verified. Please try again.');
  }

  if (!identity.sub || !identity.email) {
    throw new GoogleAuthError('Google sign-in could not be verified. Please try again.');
  }
  if (!identity.emailVerified) {
    throw new GoogleAuthError('A verified Google email is required');
  }
  return { ...identity, email: identity.email.toLowerCase() };
}

module.exports = { verifyGoogleCredential, GoogleAuthError };

