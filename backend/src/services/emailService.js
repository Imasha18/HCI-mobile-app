const nodemailer = require('nodemailer');
const environment = require('../config/environment');

function createTransporter() {
  if (!environment.gmailUser || !environment.gmailAppPassword) return null;
  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user: environment.gmailUser, pass: environment.gmailAppPassword },
  });
}

async function sendVerificationCode(email, code) {
  const transporter = createTransporter();
  if (!transporter) {
    if (environment.nodeEnv === 'production') throw new Error('Gmail verification is not configured');
    console.log(`Verification code for ${email}: ${code}`);
    return;
  }
  await transporter.sendMail({
    from: environment.gmailUser,
    to: email,
    subject: 'HomeBite email verification',
    text: `Your HomeBite verification code is ${code}. It expires in ${environment.verificationUrlMinutes} minutes.`,
  });
}

module.exports = { sendVerificationCode };