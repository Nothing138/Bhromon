// utils/authUtils.js
import bcrypt from 'bcrypt';
import nodemailer from 'nodemailer';

// ========================================
// NODEMAILER SETUP
// ========================================
const transporter = nodemailer.createTransport({
  service: 'gmail', // or your email service
  auth: {
    user: process.env.EMAIL_USER, // Your email
    pass: process.env.EMAIL_PASSWORD, // Your app password
  },
});

// ========================================
// HASH PASSWORD
// ========================================
export const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
};

// ========================================
// COMPARE PASSWORD
// ========================================
export const comparePassword = async (password, hashedPassword) => {
  return await bcrypt.compare(password, hashedPassword);
};

// ========================================
// GENERATE OTP (configurable digits)
// ========================================
export const generateOTP = (digits = 5) => {
  const min = Math.pow(10, digits - 1);
  const max = Math.pow(10, digits) - 1;
  return String(Math.floor(Math.random() * (max - min + 1)) + min);
};

// ========================================
// SEND OTP EMAIL
// ========================================
export const sendOTPEmail = async (email, otp, fullName, userType = 'user') => {
  try {
    console.log(` Sending OTP email to ${email} for ${userType}`);

    let subject = '';
    let htmlContent = '';

    if (userType === 'user') {
      subject = '🔐 Verify Your Email - Bhromon';
      htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 500px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .otp-box { background: white; border: 2px solid #667eea; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; }
            .otp-code { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #667eea; font-family: 'Courier New', monospace; }
            .expiry { color: #e74c3c; font-size: 14px; margin-top: 10px; font-weight: bold; }
            .footer { text-align: center; font-size: 12px; color: #999; margin-top: 20px; }
            .button { background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to Bhromon! ✈️</h1>
            </div>
            <div class="content">
              <p>Hi <strong>${fullName}</strong>,</p>
              <p>Thank you for creating an account with Bhromon. To complete your registration and verify your email, please enter the following code:</p>
              
              <div class="otp-box">
                <div class="otp-code">${otp}</div>
                <div class="expiry">⏰ This code expires in 5 minutes</div>
              </div>
              
              <p>If you didn't request this code, please ignore this email.</p>
              
              <p>Happy traveling! 🌍</p>
              
              <p style="color: #999; font-size: 12px;">
                Bhromon - Explore the World | Made for Travelers
              </p>
            </div>
            <div class="footer">
              <p>&copy; ${new Date().getFullYear()} Bhromon. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `;
    } else if (userType === 'agency') {
      subject = '🔐 Verify Your Email - Bhromon Agency';
      htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 500px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .otp-box { background: white; border: 2px solid #f5576c; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; }
            .otp-code { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #f5576c; font-family: 'Courier New', monospace; }
            .expiry { color: #e74c3c; font-size: 14px; margin-top: 10px; font-weight: bold; }
            .footer { text-align: center; font-size: 12px; color: #999; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Bhromon Agency Partnership</h1>
            </div>
            <div class="content">
              <p>Hi <strong>${fullName}</strong>,</p>
              <p>Welcome to Bhromon's Agency Partner Program! To verify your email and complete registration, please enter the following code:</p>
              
              <div class="otp-box">
                <div class="otp-code">${otp}</div>
                <div class="expiry">⏰ This code expires in 10 minutes</div>
              </div>
              
              <p>If you didn't request this code, please contact our support team.</p>
              
              <p>Best regards,<br>Bhromon Team</p>
            </div>
            <div class="footer">
              <p>&copy; ${new Date().getFullYear()} Bhromon. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `;
    }

    const mailOptions = {
      from: `"Bhromon" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: subject,
      html: htmlContent,
    };

    await transporter.sendMail(mailOptions);
    console.log(` OTP email sent successfully to ${email}`);
    return true;

  } catch (error) {
    console.error(' Error sending OTP email:', error);
    throw new Error(`Failed to send email: ${error.message}`);
  }
};

// ========================================
// SEND WELCOME EMAIL (Optional)
// ========================================
export const sendWelcomeEmail = async (email, fullName) => {
  try {
    console.log(` Sending welcome email to ${email}`);

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 500px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to Bhromon! 🎉</h1>
          </div>
          <div class="content">
            <p>Hi <strong>${fullName}</strong>,</p>
            <p>Your email has been verified and your account is now active!</p>
            <p>You can now log in and start exploring the world with Bhromon.</p>
            <p>Happy traveling! 🌍</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const mailOptions = {
      from: `"Bhromon" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: ' Welcome to Bhromon!',
      html: htmlContent,
    };

    await transporter.sendMail(mailOptions);
    console.log(` Welcome email sent to ${email}`);
    return true;

  } catch (error) {
    console.error(' Error sending welcome email:', error);
    throw new Error(`Failed to send email: ${error.message}`);
  }
};

// ========================================
// SEND PASSWORD RESET EMAIL (Optional)
// ========================================
export const sendPasswordResetEmail = async (email, resetLink, fullName) => {
  try {
    console.log(` Sending password reset email to ${email}`);

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 500px; margin: 0 auto; padding: 20px; }
          .header { background: #e74c3c; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
          .button { background: #e74c3c; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Password Reset Request</h1>
          </div>
          <div class="content">
            <p>Hi <strong>${fullName}</strong>,</p>
            <p>We received a request to reset your password. Click the link below to proceed:</p>
            <p><a href="${resetLink}" class="button">Reset Password</a></p>
            <p>This link expires in 1 hour.</p>
            <p>If you didn't request this, please ignore this email.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const mailOptions = {
      from: `"Bhromon" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Password Reset Request - Bhromon',
      html: htmlContent,
    };

    await transporter.sendMail(mailOptions);
    console.log(` Password reset email sent to ${email}`);
    return true;

  } catch (error) {
    console.error(' Error sending password reset email:', error);
    throw new Error(`Failed to send email: ${error.message}`);
  }
};