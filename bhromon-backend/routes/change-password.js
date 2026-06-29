// routes/change-password.js
import express from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const router = express.Router();

//  Supabase Admin Client
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ========================
// MIDDLEWARE - Check Authentication Token
// ========================
const authenticateToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'No authentication token provided' 
      });
    }

    // Verify token with Supabase
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid or expired token' 
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error(' Auth middleware error:', error);
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication failed' 
    });
  }
};

// ========================
// CHANGE PASSWORD (For logged-in users)
// ========================
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword, confirmPassword } = req.body;
    const userId = req.user.id;

    //  Validation
    if (!currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters',
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'New passwords do not match',
      });
    }

    console.log(` Change password request for user: ${userId}`);

    //  Get user email for verification
    const { data: { user }, error: getUserError } = await supabaseAdmin.auth.admin.getUserById(userId);

    if (getUserError || !user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const userEmail = user.email;

    //  Verify current password by attempting to sign in
    try {
      const supabaseClient = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY
      );

      const { error: signInError } = await supabaseClient.auth.signInWithPassword({
        email: userEmail,
        password: currentPassword,
      });

      if (signInError) {
        console.log(` Current password verification failed for: ${userEmail}`);
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect',
        });
      }
    } catch (error) {
      console.log(` Password verification error: ${error.message}`);
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    //  Update password using Admin SDK
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      { password: newPassword }
    );

    if (updateError) {
      console.error(' Error updating password:', updateError);
      return res.status(500).json({
        success: false,
        message: 'Failed to update password',
        error: updateError.message,
      });
    }

    console.log(` Password changed successfully for: ${userEmail}`);

    return res.status(200).json({
      success: true,
      message: 'Password has been changed successfully',
    });

  } catch (error) {
    console.error(' Change password error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to change password',
      error: error.message,
    });
  }
});

export default router;