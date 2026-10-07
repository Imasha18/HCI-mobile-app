const {
  buildVerificationEmailHtml,
  buildPasswordResetEmailHtml,
  getAttachments,
} = require('../services/emailService');

describe('emailService templates & branding', () => {
  test('buildVerificationEmailHtml contains app logo with cid attachment', () => {
    const testCode = '266497';
    const html = buildVerificationEmailHtml(testCode, 15);

    // App logo
    expect(html).toContain('src="cid:app_logo"');
    expect(html).toContain('alt="HomeBite"');

    // Branding & Header
    expect(html).toContain('HomeBite');
    expect(html).toContain('Verify your email');
    expect(html).toContain('Welcome to HomeBite!');
    expect(html).toContain('Use the verification code below to complete your email verification.');

    // OTP box
    expect(html).toContain(testCode);
    expect(html).toContain('#D35400');
    expect(html).toContain('#FFF5ED');
    expect(html).toContain('letter-spacing: 8px');

    // Expiry & Security
    expect(html).toContain('This verification code will expire in 15 minutes.');
    expect(html).toContain("If you didn't request this verification code, you can safely ignore this email.");

    // Footer
    expect(html).toContain('Homemade goodness, delivered.');
    expect(html).toContain('All rights reserved.');
  });

  test('getAttachments returns app logo attachment with matching cid', () => {
    const attachments = getAttachments();
    expect(attachments.length).toBeGreaterThanOrEqual(1);
    expect(attachments[0]).toHaveProperty('cid', 'app_logo');
    expect(attachments[0]).toHaveProperty('filename', 'logo.png');
  });

  test('buildPasswordResetEmailHtml contains app logo and required fields', () => {
    const testCode = '839201';
    const html = buildPasswordResetEmailHtml(testCode, 15);

    expect(html).toContain('src="cid:app_logo"');
    expect(html).toContain('HomeBite');
    expect(html).toContain('Reset your password');
    expect(html).toContain('Account Security');
    expect(html).toContain(testCode);
    expect(html).toContain('This reset code will expire in 15 minutes.');
    expect(html).toContain('Homemade goodness, delivered.');
  });
});
