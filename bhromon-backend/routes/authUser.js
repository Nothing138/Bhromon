// routes/authUser.js - FIXED: upsert profile to avoid duplicate key on auto-created profiles
import express from 'express';
import getSupabaseClient from '../config/supabaseConfig.js';
import { generateOTP, sendOTPEmail } from '../utils/authUtils.js';

const router = express.Router();

// ========================================
// USER REGISTRATION WITH OTP (Via Backend)
// ========================================
router.post('/register/user', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { fullName, email, password } = req.body;

    console.log('🔹 Starting user registration for:', email);

    // Validate input
    if (!fullName || !email || !password) {
      return res.status(400).json({
        message: 'Full name, email, and password are required',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'Password must be at least 8 characters',
      });
    }

    // Check if email already exists in profiles via auth admin
    const { data: existingAuth } = await supabase.auth.admin.listUsers();
    const emailExists = existingAuth?.users?.some(
      (u) => u.email === email.trim()
    );

    if (emailExists) {
      return res.status(400).json({
        message: 'This email is already registered. Please login instead.',
      });
    }

    // Create user in Supabase Auth
    const { data: authData, error: authError } =
      await supabase.auth.admin.createUser({
        email: email.trim(),
        password: password.trim(),
        email_confirm: false, // Will be confirmed after OTP verification
        user_metadata: {
          full_name: fullName.trim(),
        },
      });

    if (authError) {
      console.error(' Auth creation error:', authError);
      return res.status(400).json({
        message: authError.message || 'Failed to create user account',
      });
    }

    const userId = authData.user.id;
    console.log(' User created in Supabase Auth:', userId);

    //  FIX: Use UPSERT instead of INSERT
    // Supabase may auto-create a profile row via a trigger on auth.users,
    // so we upsert to avoid the duplicate key (23505) error.
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(
        {
          id: userId,
          full_name: fullName.trim(),
          username: email.split('@')[0],
          user_type: 'user',
          otp_verified: false,
        },
        { onConflict: 'id' }
      );

    if (profileError) {
      console.error(' Profile upsert error:', profileError);
      // Clean up: Delete user from auth if profile creation fails
      await supabase.auth.admin.deleteUser(userId);
      return res.status(400).json({
        message: 'Failed to create user profile. Please try again.',
      });
    }

    console.log(' Profile upserted for user:', userId);

    // Generate 5-digit OTP
    const otp = generateOTP(5);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Invalidate any existing unused OTPs for this user first
    await supabase
      .from('user_otp')
      .update({ is_used: true })
      .eq('user_id', userId)
      .eq('is_used', false);

    // Save new OTP to database
    const { error: otpError } = await supabase.from('user_otp').insert({
      user_id: userId,
      otp_code: otp,
      is_used: false,
      expires_at: expiresAt.toISOString(),
    });

    if (otpError) {
      console.error(' OTP creation error:', otpError);
      return res.status(400).json({
        message: 'Failed to generate OTP. Please try again.',
      });
    }

    console.log(' OTP generated and saved:', otp);

    // Send OTP via email
    try {
      await sendOTPEmail(email, otp, fullName, 'user');
      console.log(' OTP email sent successfully');
    } catch (emailError) {
      console.error('Email sending failed:', emailError);
      return res.status(500).json({
        message: 'Failed to send OTP email. Please try again.',
      });
    }

    // Success response
    res.status(200).json({
      success: true,
      message: 'Registration successful! OTP has been sent to your email.',
      userId: userId,
      email: email,
      otpExpiresIn: 300, // 5 minutes in seconds
    });
  } catch (error) {
    console.error(' User registration error:', error);
    res.status(500).json({
      message: 'An error occurred during registration. Please try again.',
    });
  }
});

// ========================================
// USER OTP VERIFICATION
// ========================================
router.post('/verify-user-otp', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { userId, otpCode } = req.body;

    console.log('🔹 Verifying user OTP for userId:', userId);

    if (!userId || !otpCode) {
      return res.status(400).json({
        message: 'User ID and OTP code are required',
      });
    }

    // Find the OTP record
    const { data: otpRecord, error: fetchError } = await supabase
      .from('user_otp')
      .select('*')
      .eq('user_id', userId)
      .eq('otp_code', otpCode.trim())
      .eq('is_used', false)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (fetchError || !otpRecord) {
      console.error(' OTP not found or already used');
      return res.status(400).json({
        message: 'Invalid or expired OTP. Please try again.',
      });
    }

    // Check expiry
    const now = new Date();
    const expiresAt = new Date(otpRecord.expires_at);

    if (now > expiresAt) {
      console.error(' OTP has expired');
      return res.status(400).json({
        message: 'OTP has expired. Please request a new one.',
      });
    }

    // Mark OTP as used
    const { error: updateOtpError } = await supabase
      .from('user_otp')
      .update({
        is_used: true,
        used_at: now.toISOString(),
      })
      .eq('id', otpRecord.id);

    if (updateOtpError) {
      console.error(' Failed to mark OTP as used:', updateOtpError);
      return res.status(500).json({
        message: 'Failed to verify OTP. Please try again.',
      });
    }

    // Update profile — set otp_verified to true
    const { error: profileUpdateError } = await supabase
      .from('profiles')
      .update({
        otp_verified: true,
        otp_verified_at: now.toISOString(),
      })
      .eq('id', userId);

    if (profileUpdateError) {
      console.error(' Failed to update profile:', profileUpdateError);
      return res.status(500).json({
        message: 'Failed to verify user. Please try again.',
      });
    }

    // Confirm user email in Supabase Auth
    const { error: confirmError } = await supabase.auth.admin.updateUserById(
      userId,
      { email_confirm: true }
    );

    if (confirmError) {
      console.error('Failed to confirm email in auth (non-critical):', confirmError);
      // Continue — profile is already marked verified
    }

    console.log(' User OTP verified successfully');

    res.status(200).json({
      success: true,
      message: 'Email verified successfully! You can now log in.',
      userId: userId,
    });
  } catch (error) {
    console.error(' User OTP verification error:', error);
    res.status(500).json({
      message: 'An error occurred during verification. Please try again.',
    });
  }
});

// ========================================
// RESEND USER OTP
// ========================================
router.post('/resend-user-otp', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { userId } = req.body;

    console.log('🔹 Resending OTP for userId:', userId);

    if (!userId) {
      return res.status(400).json({
        message: 'User ID is required',
      });
    }

    // Get user profile for full name
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      return res.status(400).json({
        message: 'User profile not found',
      });
    }

    // Get user email from Supabase Auth
    const { data: authUser, error: authError } =
      await supabase.auth.admin.getUserById(userId);

    if (authError || !authUser.user) {
      return res.status(400).json({
        message: 'User not found',
      });
    }

    const email = authUser.user.email;

    // Invalidate old OTPs
    await supabase
      .from('user_otp')
      .update({ is_used: true })
      .eq('user_id', userId)
      .eq('is_used', false);

    // Generate new 5-digit OTP
    const otp = generateOTP(5);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    const { error: otpError } = await supabase.from('user_otp').insert({
      user_id: userId,
      otp_code: otp,
      is_used: false,
      expires_at: expiresAt.toISOString(),
    });

    if (otpError) {
      console.error(' OTP creation error:', otpError);
      return res.status(400).json({
        message: 'Failed to generate OTP. Please try again.',
      });
    }

    // Send OTP via email
    try {
      await sendOTPEmail(email, otp, profile.full_name, 'user');
      console.log(' OTP resent successfully');
    } catch (emailError) {
      console.error('Email sending failed:', emailError);
      return res.status(500).json({
        message: 'Failed to send OTP email. Please try again.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'OTP has been resent to your email.',
      otpExpiresIn: 300,
    });
  } catch (error) {
    console.error(' Resend OTP error:', error);
    res.status(500).json({
      message: 'An error occurred. Please try again.',
    });
  }
});

// ========================================
// AGENCY REGISTRATION (Via Backend)
// ========================================
router.post('/register/agency', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const {
      agencyName,
      ownerFullName,
      ownerEmail,
      ownerPhone,
      password,
      officeAddress,
      officePhone,
      businessLicenseNumber,
      taxId,
      websiteUrl,
      bankAccountHolder,
      bankAccountNumber,
      bankName,
      branchName,
    } = req.body;

    if (!agencyName || !ownerFullName || !ownerEmail || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    console.log('🔹 Starting agency registration for:', ownerEmail);

    const { data: authData, error: authError } =
      await supabase.auth.admin.createUser({
        email: ownerEmail.trim(),
        password: password.trim(),
        email_confirm: true,
        user_metadata: { full_name: ownerFullName.trim() },
      });

    if (authError && !authError.message.includes('already exists')) {
      return res.status(400).json({ message: authError.message });
    }

    const userId = authData?.user?.id;
    if (!userId) {
      return res.status(400).json({ message: 'Failed to get user ID' });
    }

    //  FIX: upsert profile
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(
        {
          id: userId,
          full_name: ownerFullName.trim(),
          username: ownerEmail.split('@')[0],
          user_type: 'agency',
          otp_verified: false,
        },
        { onConflict: 'id' }
      );

    if (profileError) {
      console.error(' Profile upsert error:', profileError);
      return res.status(500).json({ message: 'Failed to create profile' });
    }

    // Check if agency record already exists
    const { data: agencyExists } = await supabase
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    let agencyId;

    if (agencyExists) {
      const { data: updated, error: updateError } = await supabase
        .from('travel_agencies')
        .update({
          agency_name: agencyName.trim(),
          owner_full_name: ownerFullName.trim(),
          owner_email: ownerEmail.trim(),
          owner_phone: ownerPhone?.trim(),
          office_address: officeAddress?.trim(),
          office_phone: officePhone,
          business_license_number: businessLicenseNumber,
          tax_id: taxId,
          website_url: websiteUrl,
          bank_account_holder: bankAccountHolder,
          bank_account_number: bankAccountNumber,
          bank_name: bankName,
          branch_name: branchName,
          verification_status: 'approved',
          verified_at: new Date().toISOString(),
        })
        .eq('user_id', userId)
        .select('id')
        .single();

      if (updateError) {
        return res.status(500).json({ message: updateError.message });
      }
      agencyId = updated.id;
    } else {
      const { data: agencyData, error: agencyError } = await supabase
        .from('travel_agencies')
        .insert({
          user_id: userId,
          agency_name: agencyName.trim(),
          owner_full_name: ownerFullName.trim(),
          owner_email: ownerEmail.trim(),
          owner_phone: ownerPhone?.trim(),
          office_address: officeAddress?.trim(),
          office_phone: officePhone,
          business_license_number: businessLicenseNumber,
          tax_id: taxId,
          website_url: websiteUrl,
          bank_account_holder: bankAccountHolder,
          bank_account_number: bankAccountNumber,
          bank_name: bankName,
          branch_name: branchName,
          verification_status: 'approved',
          verified_at: new Date().toISOString(),
          otp_verified: false,
        })
        .select('id')
        .single();

      if (agencyError) {
        return res.status(500).json({ message: agencyError.message });
      }
      agencyId = agencyData.id;
    }

    res.status(200).json({
      success: true,
      message: 'Agency registered successfully!',
      agencyId: agencyId,
    });
  } catch (error) {
    console.error(' Agency registration error:', error);
    res.status(500).json({ message: 'An error occurred during registration.' });
  }
});

// ========================================
// VERIFY OTP (Agency)
// ========================================
router.post('/verify-otp', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { agencyId, otpCode } = req.body;

    if (!agencyId || !otpCode) {
      return res.status(400).json({ message: 'Missing agencyId or otpCode' });
    }

    const { data: otpRecord, error: otpError } = await supabase
      .from('agency_otp')
      .select()
      .eq('agency_id', agencyId)
      .eq('is_used', false)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (otpError || !otpRecord) {
      return res.status(400).json({ message: 'No valid OTP found' });
    }

    if (otpRecord.otp_code !== otpCode.trim()) {
      return res.status(400).json({ message: 'Invalid OTP code' });
    }

    if (new Date() > new Date(otpRecord.expires_at)) {
      return res.status(400).json({ message: 'OTP has expired' });
    }

    await supabase
      .from('agency_otp')
      .update({ is_used: true, used_at: new Date().toISOString() })
      .eq('id', otpRecord.id);

    await supabase
      .from('travel_agencies')
      .update({ otp_verified: true, otp_verified_at: new Date().toISOString() })
      .eq('id', agencyId);

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully!',
      agencyId,
    });
  } catch (error) {
    console.error(' OTP verification error:', error);
    res.status(500).json({ message: 'An error occurred during verification.' });
  }
});

// ========================================
// RESEND OTP (Agency)
// ========================================
router.post('/resend-otp', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { agencyId } = req.body;

    if (!agencyId) {
      return res.status(400).json({ message: 'Missing agencyId' });
    }

    const { data: agency, error: agencyError } = await supabase
      .from('travel_agencies')
      .select('agency_name, owner_email')
      .eq('id', agencyId)
      .single();

    if (agencyError || !agency) {
      return res.status(400).json({ message: 'Agency not found' });
    }

    const { generateOTP: gen, sendOTPEmail: sendEmail } = await import(
      '../utils/authUtils.js'
    );
    const otp = gen(6);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    await supabase.from('agency_otp').insert({
      agency_id: agencyId,
      otp_code: otp,
      expires_at: expiresAt,
    });

    await sendEmail(agency.owner_email, otp, agency.agency_name, 'agency');

    res.status(200).json({
      success: true,
      message: 'New OTP sent to your email.',
      otpExpiresIn: 600,
    });
  } catch (error) {
    console.error(' Resend OTP error:', error);
    res.status(500).json({ message: 'An error occurred.' });
  }
});

// ========================================
// REQUEST PASSWORD RESET
// ========================================
router.post('/request-password-reset', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    await supabase.auth.resetPasswordForEmail(email.trim());

    res.status(200).json({
      success: true,
      message: 'Password reset email sent.',
    });
  } catch (error) {
    console.error(' Password reset request error:', error);
    res.status(500).json({ message: 'An error occurred.' });
  }
});

// ========================================
// RESET PASSWORD WITH TOKEN
// ========================================
router.post('/reset-password', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { email, resetToken, newPassword } = req.body;

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Look up the reset token
    const { data: tokenRecord, error: tokenError } = await supabase
      .from('password_reset_tokens')
      .select('*, auth.users!inner(email)')
      .eq('reset_token', resetToken)
      .eq('is_used', false)
      .single();

    if (tokenError || !tokenRecord) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    if (new Date() > new Date(tokenRecord.expires_at)) {
      return res.status(400).json({ message: 'Reset token has expired' });
    }

    // Update password
    const { error: updateError } = await supabase.auth.admin.updateUserById(
      tokenRecord.user_id,
      { password: newPassword.trim() }
    );

    if (updateError) {
      return res.status(500).json({ message: updateError.message });
    }

    // Mark token as used
    await supabase
      .from('password_reset_tokens')
      .update({ is_used: true })
      .eq('id', tokenRecord.id);

    res.status(200).json({
      success: true,
      message: 'Password reset successful.',
    });
  } catch (error) {
    console.error(' Password reset error:', error);
    res.status(500).json({ message: 'An error occurred.' });
  }
});

// ========================================
// CHANGE PASSWORD
// ========================================
router.post('/change-password', async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const token = authHeader.split(' ')[1];
    const { currentPassword, newPassword, confirmPassword } = req.body;

    if (!currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({ message: 'All password fields are required' });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ message: 'New passwords do not match' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    // Get user from token
    const { data: userData, error: userError } =
      await supabase.auth.getUser(token);

    if (userError || !userData.user) {
      return res.status(401).json({ message: 'Invalid session' });
    }

    // Verify current password by attempting sign-in
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: userData.user.email,
      password: currentPassword.trim(),
    });

    if (signInError) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    // Update to new password
    const { error: updateError } = await supabase.auth.admin.updateUserById(
      userData.user.id,
      { password: newPassword.trim() }
    );

    if (updateError) {
      return res.status(500).json({ message: updateError.message });
    }

    res.status(200).json({
      success: true,
      message: 'Password changed successfully.',
    });
  } catch (error) {
    console.error(' Change password error:', error);
    res.status(500).json({ message: 'An error occurred.' });
  }
});

export default router;