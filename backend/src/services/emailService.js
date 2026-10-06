const path = require('node:path');
const fs = require('node:fs');
const nodemailer = require('nodemailer');
const environment = require('../config/environment');

const primaryLogoPath = path.join(__dirname, '../assets/logo.png');
const fallbackLogoPath = path.join(__dirname, '../../../assets/images/logo.png');

function getLogoPath() {
  if (fs.existsSync(primaryLogoPath)) return primaryLogoPath;
  if (fs.existsSync(fallbackLogoPath)) return fallbackLogoPath;
  return null;
}

function getAttachments() {
  const resolved = getLogoPath();
  if (resolved) {
    return [
      {
        filename: 'logo.png',
        path: resolved,
        cid: 'app_logo',
      },
    ];
  }
  return [];
}

function createTransporter() {
  if (environment.smtpHost && environment.smtpUser && environment.smtpPass) {
    return nodemailer.createTransport({
      host: environment.smtpHost,
      port: environment.smtpPort,
      secure: environment.smtpSecure,
      auth: {
        user: environment.smtpUser,
        pass: environment.smtpPass,
      },
    });
  }

  if (environment.gmailUser && environment.gmailAppPassword) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: { user: environment.gmailUser, pass: environment.gmailAppPassword },
    });
  }

  return null;
}

function getSender() {
  if (environment.emailFrom) {
    return environment.emailFrom;
  }
  if (environment.gmailUser) {
    return `"HomeBite" <${environment.gmailUser}>`;
  }
  return '"HomeBite" <noreply@homebite.com>';
}

function buildVerificationEmailHtml(code, minutes = 15) {
  const currentYear = new Date().getFullYear();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>HomeBite – Verify Your Email</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAF7F2; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #252525;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #FAF7F2; table-layout: fixed;">
    <tr>
      <td align="center" style="padding: 40px 16px;">
        <!-- Card Container (max-width: 580px) -->
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 580px; background-color: #FFFFFF; border-radius: 20px; border: 1px solid #EFEAE3; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.04); overflow: hidden;">
          
          <!-- Top Accent Bar -->
          <tr>
            <td height="6" style="background-color: #FF7A00; line-height: 6px; font-size: 6px;">&nbsp;</td>
          </tr>

          <!-- Header with HomeBite Branding -->
          <tr>
            <td align="center" style="padding: 36px 32px 12px 32px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <!-- App Logo -->
                    <img src="cid:app_logo" alt="HomeBite" width="56" height="56" style="display: block; margin: 0 auto 12px auto; border-radius: 16px; width: 56px; height: 56px; object-fit: contain; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);" />
                  </td>
                </tr>
                <tr>
                  <td align="center">
                    <span style="font-size: 24px; font-weight: 800; color: #FF7A00; letter-spacing: -0.5px; text-decoration: none;">HomeBite</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td align="center" style="padding: 12px 36px 0 36px;">
              <h1 style="margin: 0 0 8px 0; font-size: 26px; font-weight: 800; color: #1E1E1E; letter-spacing: -0.4px; line-height: 1.25;">Verify your email</h1>
              <p style="margin: 0 0 12px 0; font-size: 16px; font-weight: 600; color: #FF7A00;">Welcome to HomeBite!</p>
              <p style="margin: 0 0 28px 0; font-size: 15px; color: #555555; line-height: 1.55; max-width: 440px;">Use the verification code below to complete your email verification.</p>
            </td>
          </tr>

          <!-- OTP Box -->
          <tr>
            <td align="center" style="padding: 0 36px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin: 0 auto; max-width: 320px; width: 100%;">
                <tr>
                  <td align="center" style="background-color: #FFF5ED; border: 1.5px dashed #FF7A00; border-radius: 16px; padding: 20px 24px;">
                    <div style="font-family: 'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Courier New', monospace; font-size: 38px; font-weight: 800; color: #D35400; letter-spacing: 8px; line-height: 1; padding-left: 8px;">
                      ${code}
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Expiry Notice -->
          <tr>
            <td align="center" style="padding: 18px 36px 0 36px;">
              <p style="margin: 0; font-size: 13.5px; font-weight: 500; color: #777777; line-height: 1.4;">
                ⏱&nbsp;&nbsp;This verification code will expire in ${minutes} minutes.
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 24px 36px 0 36px;">
              <div style="border-top: 1px solid #F0ECE6; width: 100%;"></div>
            </td>
          </tr>

          <!-- Security Notice -->
          <tr>
            <td align="center" style="padding: 20px 36px 32px 36px;">
              <p style="margin: 0; font-size: 13px; color: #888888; line-height: 1.5; max-width: 440px;">
                If you didn't request this verification code, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer Inside Card -->
          <tr>
            <td align="center" style="background-color: #FAF7F2; border-top: 1px solid #EFEAE3; padding: 24px 32px;">
              <p style="margin: 0 0 4px 0; font-size: 14px; font-weight: 700; color: #FF7A00; letter-spacing: -0.2px;">HomeBite</p>
              <p style="margin: 0 0 12px 0; font-size: 12.5px; color: #777777;">Homemade goodness, delivered.</p>
              <p style="margin: 0; font-size: 11.5px; color: #AAAAAA;">&copy; ${currentYear} HomeBite. All rights reserved.</p>
            </td>
          </tr>

        </table>

        <!-- Micro-footer -->
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 580px; margin-top: 16px;">
          <tr>
            <td align="center">
              <p style="margin: 0; font-size: 11px; color: #BBBBBB;">This is an automated security message. Please do not reply directly to this email.</p>
            </td>
          </tr>
        </table>

      </td>
    </tr>
  </table>
</body>
</html>`;
}

function buildPasswordResetEmailHtml(code, minutes = 15) {
  const currentYear = new Date().getFullYear();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>HomeBite – Reset Your Password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAF7F2; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #252525;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #FAF7F2; table-layout: fixed;">
    <tr>
      <td align="center" style="padding: 40px 16px;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 580px; background-color: #FFFFFF; border-radius: 20px; border: 1px solid #EFEAE3; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.04); overflow: hidden;">
          
          <tr>
            <td height="6" style="background-color: #FF7A00; line-height: 6px; font-size: 6px;">&nbsp;</td>
          </tr>

          <tr>
            <td align="center" style="padding: 36px 32px 12px 32px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <!-- App Logo -->
                    <img src="cid:app_logo" alt="HomeBite" width="56" height="56" style="display: block; margin: 0 auto 12px auto; border-radius: 16px; width: 56px; height: 56px; object-fit: contain; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);" />
                  </td>
                </tr>
                <tr>
                  <td align="center">
                    <span style="font-size: 24px; font-weight: 800; color: #FF7A00; letter-spacing: -0.5px; text-decoration: none;">HomeBite</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td align="center" style="padding: 12px 36px 0 36px;">
              <h1 style="margin: 0 0 8px 0; font-size: 26px; font-weight: 800; color: #1E1E1E; letter-spacing: -0.4px; line-height: 1.25;">Reset your password</h1>
              <p style="margin: 0 0 12px 0; font-size: 16px; font-weight: 600; color: #FF7A00;">Account Security</p>
              <p style="margin: 0 0 28px 0; font-size: 15px; color: #555555; line-height: 1.55; max-width: 440px;">Use the reset code below to create a new password for your HomeBite account.</p>
            </td>
          </tr>

          <tr>
            <td align="center" style="padding: 0 36px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin: 0 auto; max-width: 320px; width: 100%;">
                <tr>
                  <td align="center" style="background-color: #FFF5ED; border: 1.5px dashed #FF7A00; border-radius: 16px; padding: 20px 24px;">
                    <div style="font-family: 'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Courier New', monospace; font-size: 38px; font-weight: 800; color: #D35400; letter-spacing: 8px; line-height: 1; padding-left: 8px;">
                      ${code}
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td align="center" style="padding: 18px 36px 0 36px;">
              <p style="margin: 0; font-size: 13.5px; font-weight: 500; color: #777777; line-height: 1.4;">
                ⏱&nbsp;&nbsp;This reset code will expire in ${minutes} minutes.
              </p>
            </td>
          </tr>

          <tr>
            <td style="padding: 24px 36px 0 36px;">
              <div style="border-top: 1px solid #F0ECE6; width: 100%;"></div>
            </td>
          </tr>

          <tr>
            <td align="center" style="padding: 20px 36px 32px 36px;">
              <p style="margin: 0; font-size: 13px; color: #888888; line-height: 1.5; max-width: 440px;">
                If you didn't request a password reset, you can safely ignore this email. Your account remains secure.
              </p>
            </td>
          </tr>

          <tr>
            <td align="center" style="background-color: #FAF7F2; border-top: 1px solid #EFEAE3; padding: 24px 32px;">
              <p style="margin: 0 0 4px 0; font-size: 14px; font-weight: 700; color: #FF7A00; letter-spacing: -0.2px;">HomeBite</p>
              <p style="margin: 0 0 12px 0; font-size: 12.5px; color: #777777;">Homemade goodness, delivered.</p>
              <p style="margin: 0; font-size: 11.5px; color: #AAAAAA;">&copy; ${currentYear} HomeBite. All rights reserved.</p>
            </td>
          </tr>

        </table>

        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 580px; margin-top: 16px;">
          <tr>
            <td align="center">
              <p style="margin: 0; font-size: 11px; color: #BBBBBB;">This is an automated security message. Please do not reply directly to this email.</p>
            </td>
          </tr>
        </table>

      </td>
    </tr>
  </table>
</body>
</html>`;
}

async function sendVerificationCode(email, code) {
  const minutes = environment.verificationUrlMinutes || 15;
  const transporter = createTransporter();
  if (!transporter) {
    if (environment.nodeEnv === 'production') throw new Error('Email service is not configured');
    if (environment.nodeEnv !== 'test') {
      console.log(`[Dev] Verification code dispatch for ${email}`);
    }
    return;
  }
  const attachments = getAttachments();
  await transporter.sendMail({
    from: getSender(),
    to: email,
    replyTo: environment.replyToEmail || 'noreply@homebite.com',
    subject: 'HomeBite – Verify Your Email',
    text: `Welcome to HomeBite!\n\nYour verification code is: ${code}\n\nThis code expires in ${minutes} minutes.\n\nIf you didn't request this code, you can ignore this email.\n\nHomeBite\nHomemade goodness, delivered.`,
    html: buildVerificationEmailHtml(code, minutes),
    attachments,
  });
}

async function sendPasswordResetCode(email, code) {
  const minutes = environment.verificationUrlMinutes || 15;
  const transporter = createTransporter();
  if (!transporter) {
    if (environment.nodeEnv === 'production') throw new Error('Email service is not configured');
    if (environment.nodeEnv !== 'test') {
      console.log(`[Dev] Password reset code dispatch for ${email}`);
    }
    return;
  }
  const attachments = getAttachments();
  await transporter.sendMail({
    from: getSender(),
    to: email,
    replyTo: environment.replyToEmail || 'noreply@homebite.com',
    subject: 'HomeBite – Reset Your Password',
    text: `Welcome to HomeBite!\n\nYour password reset code is: ${code}\n\nThis code expires in ${minutes} minutes.\n\nIf you didn't request a password reset, you can safely ignore this email.\n\nHomeBite\nHomemade goodness, delivered.`,
    html: buildPasswordResetEmailHtml(code, minutes),
    attachments,
  });
}

module.exports = {
  sendVerificationCode,
  sendPasswordResetCode,
  buildVerificationEmailHtml,
  buildPasswordResetEmailHtml,
  getAttachments,
  getSender,
  createTransporter,
};