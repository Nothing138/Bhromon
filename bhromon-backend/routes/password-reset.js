// routes/password-reset.js
// ✅ Password reset endpoints using Supabase Admin SDK

import express from 'express';
import { createClient } from '@supabase/supabase-js';
import { randomBytes } from 'crypto';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const router = express.Router();

// ✅ Supabase Admin Client (with service role key)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ✅ Email Service Setup (Gmail/Nodemailer)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASSWORD,
  },
});

// ========================
// 1️⃣ REQUEST PASSWORD RESET
// ========================
router.post('/request-password-reset', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    console.log(`🔄 Password reset requested for: ${email}`);

    // ✅ Check if user exists
    const { data: user, error: userError } = await supabaseAdmin.auth.admin.getUserByEmail(email);

    if (userError || !user) {
      console.log(`⚠️ User not found: ${email}`);
      // Don't reveal whether email exists (security)
      return res.status(200).json({ 
        message: 'If email exists, reset code will be sent' 
      });
    }

    // ✅ Generate secure reset token (32 characters)
    const resetToken = randomBytes(16).toString('hex');
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // ✅ Store reset token in database
    const { error: insertError } = await supabaseAdmin
      .from('password_reset_tokens')
      .insert({
        user_id: user.id,
        reset_token: resetToken,
        is_used: false,
        expires_at: expiresAt,
      });

    if (insertError) {
      console.error('❌ Error storing reset token:', insertError);
      return res.status(500).json({ message: 'Failed to generate reset code' });
    }

    // ✅ Extract first 6 characters for email display (user-friendly code)
    const displayToken = resetToken.substring(0, 6).toUpperCase();

    // ✅ Send password reset email
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}&email=${email}`;

    const mailOptions = {
      from: process.env.GMAIL_USER,
      to: email,
      subject: '🔐 Bhromon - Password Reset Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0;">
            <h1 style="margin: 0; font-size: 28px;">🔐 Password Reset</h1>
            <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Bhromon Travel Social Platform</p>
          </div>
          
          <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px;">
            <p style="color: #333; font-size: 16px; margin: 0 0 20px 0;">
              Hi there! We received a request to reset your password. If you didn't make this request, you can ignore this email.
            </p>

            <div style="background: white; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
              <p style="color: #666; font-size: 14px; margin: 0 0 10px 0;">Your Password Reset Code:</p>
              <h2 style="color: #667eea; font-size: 32px; letter-spacing: 4px; margin: 0; font-family: monospace;">
                ${displayToken}
              </h2>
              <p style="color: #999; font-size: 12px; margin: 10px 0 0 0;">This code expires in 24 hours</p>
            </div>

            <p style="color: #333; font-size: 14px; margin: 20px 0;">
              Or use this link:
            </p>
            <a href="${resetUrl}" style="display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold;">
              Reset Password
            </a>

            <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">

            <p style="color: #666; font-size: 12px; margin: 0;">
              <strong>Security Tip:</strong> Never share this code with anyone. Bhromon support will never ask for your reset code.
            </p>
            <p style="color: #999; font-size: 12px; margin: 10px 0 0 0;">
              © 2024 Bhromon. All rights reserved.
            </p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ Password reset email sent to: ${email}`);

    return res.status(200).json({ 
      message: 'Password reset email sent successfully',
      displayToken, // Only for development/testing
    });

  } catch (error) {
    console.error('❌ Password reset request error:', error);
    return res.status(500).json({ 
      message: 'Failed to process password reset request',
      error: error.message 
    });
  }
});

// ========================
// 2️⃣ VERIFY TOKEN & RESET PASSWORD
// ========================
router.post('/reset-password', async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ 
        message: 'Email, reset token, and new password are required' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        message: 'Password must be at least 6 characters' 
      });
    }

    console.log(`🔄 Verifying reset token for: ${email}`);

    // ✅ Get user by email
    const { data: user, error: userError } = await supabaseAdmin.auth.admin.getUserByEmail(email);

    if (userError || !user) {
      console.log(`❌ User not found: ${email}`);
      return res.status(404).json({ message: 'User not found' });
    }

    // ✅ Find and verify reset token
    const { data: tokenData, error: tokenError } = await supabaseAdmin
      .from('password_reset_tokens')
      .select('*')
      .eq('user_id', user.id)
      .eq('reset_token', resetToken)
      .eq('is_used', false)
      .single();

    if (tokenError || !tokenData) {
      console.log(`❌ Invalid or missing reset token for: ${email}`);
      return res.status(400).json({ message: 'Invalid reset code' });
    }

    // ✅ Check if token is expired
    if (new Date(tokenData.expires_at) < new Date()) {
      console.log(`❌ Reset token expired for: ${email}`);
      return res.status(400).json({ message: 'Token expired. Please request a new reset email.' });
    }

    // ✅ Update password using Admin SDK
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      user.id,
      { password: newPassword }
    );

    if (updateError) {
      console.error('❌ Error updating password:', updateError);
      return res.status(500).json({ message: 'Failed to update password', error: updateError.message });
    }

    // ✅ Mark token as used
    const { error: markUsedError } = await supabaseAdmin
      .from('password_reset_tokens')
      .update({
        is_used: true,
        used_at: new Date(),
      })
      .eq('id', tokenData.id);

    if (markUsedError) {
      console.error('⚠️ Error marking token as used:', markUsedError);
      // Don't return error - password was already updated
    }

    console.log(`✅ Password reset successful for: ${email}`);

    return res.status(200).json({ 
      message: 'Password has been reset successfully. You can now login with your new password.' 
    });

  } catch (error) {
    console.error('❌ Password reset error:', error);
    return res.status(500).json({ 
      message: 'Failed to reset password',
      error: error.message 
    });
  }
});

// ========================
// 3️⃣ VALIDATE RESET TOKEN (Optional)
// ========================
router.post('/validate-reset-token', async (req, res) => {
  try {
    const { email, resetToken } = req.body;

    if (!email || !resetToken) {
      return res.status(400).json({ 
        message: 'Email and reset token are required' 
      });
    }

    console.log(`🔍 Validating reset token for: ${email}`);

    // ✅ Get user by email
    const { data: user, error: userError } = await supabaseAdmin.auth.admin.getUserByEmail(email);

    if (userError || !user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // ✅ Check token
    const { data: tokenData, error: tokenError } = await supabaseAdmin
      .from('password_reset_tokens')
      .select('*')
      .eq('user_id', user.id)
      .eq('reset_token', resetToken)
      .eq('is_used', false)
      .single();

    if (tokenError || !tokenData) {
      return res.status(400).json({ message: 'Invalid reset code' });
    }

    // ✅ Check expiration
    if (new Date(tokenData.expires_at) < new Date()) {
      return res.status(400).json({ message: 'Token expired' });
    }

    console.log(`✅ Reset token is valid for: ${email}`);

    return res.status(200).json({ 
      message: 'Token is valid',
      valid: true,
      expiresAt: tokenData.expires_at 
    });

  } catch (error) {
    console.error('❌ Token validation error:', error);
    return res.status(500).json({ 
      message: 'Failed to validate token',
      error: error.message 
    });
  }
});

export default router;