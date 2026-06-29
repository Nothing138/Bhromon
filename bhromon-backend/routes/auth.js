// backend/routes/auth.js - WITH USER OTP SUPPORT
import express from 'express';
import { createClient } from '@supabase/supabase-js';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const router = express.Router();

// ========================
// SUPABASE ADMIN CLIENT
// ========================
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// ========================
// GMAIL CONFIGURATION
// ========================
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASSWORD,
  },
});

transporter.verify((error, success) => {
  if (error) {
    console.error(' Gmail SMTP connection error:', error.message);
  } else {
    console.log(' Gmail SMTP connection successful');
  }
});

async function sendEmail(email, subject, html) {
  try {
    console.log(` Sending email to ${email}: ${subject}`);
    const mailOptions = {
      from: `"Bhromon" <${process.env.GMAIL_USER}>`,
      to: email,
      subject,
      html,
    };
    const info = await transporter.sendMail(mailOptions);
    console.log(` Email sent to ${email} (ID: ${info.messageId})`);
    return true;
  } catch (error) {
    console.error(` Email send error: ${error.message}`);
    throw error;
  }
}

// ========================
// HELPER: OTP Generator (6 digit)
// ========================
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ========================
// EMAIL TEMPLATES
// ========================
function getRegistrationOTPEmail(name, otp) {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>
      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Welcome to Bhromon, ${name}! 🎉</h2>
        <p style="color: #666; line-height: 1.6;">Please verify your email with the OTP code below.</p>
        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea;">
          <p style="color: #999; margin: 0 0 10px 0; font-size: 14px;">Your OTP Code</p>
          <p style="color: #667eea; font-size: 48px; font-weight: bold; margin: 0; letter-spacing: 8px;">${otp}</p>
          <p style="color: #999; margin: 10px 0 0 0; font-size: 12px;">This code expires in 10 minutes</p>
        </div>
        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #856404; margin: 0; font-size: 12px;">🔒 Never share this code with anyone.</p>
        </div>
      </div>
      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">© 2024 Bhromon. All rights reserved.</p>
      </div>
    </div>
  `;
}

function getWelcomeEmail(firstName) {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; border-radius: 8px; color: white; text-align: center;">
        <h1 style="margin: 0; font-size: 32px;">🌍 Bhromon</h1>
        <p style="margin: 10px 0; font-size: 16px;">Travel. Connect. Explore.</p>
      </div>
      <div style="background: #f8f9fa; padding: 40px 20px; margin-top: 20px; border-radius: 8px;">
        <h2 style="color: #333; margin-top: 0;">Your account is now verified, ${firstName}! 🎉</h2>
        <p style="color: #666; line-height: 1.6;">Thank you for joining our travel community. Start exploring!</p>
        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; border-left: 4px solid #667eea;">
          <h3 style="color: #333; margin-top: 0;">What You Can Do Now:</h3>
          <ul style="color: #666; line-height: 1.8;">
            <li>📍 Explore travel destinations</li>
            <li>👥 Connect with fellow travelers</li>
            <li>✍️ Share your travel experiences</li>
            <li>🆘 Access emergency services</li>
          </ul>
        </div>
      </div>
      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">© 2024 Bhromon. All rights reserved.</p>
      </div>
    </div>
  `;
}

// ========================
// ENDPOINT: USER REGISTRATION
// ========================
router.post('/register/user', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    if (password.length < 8) {
      return res.status(400).json({ success: false, message: 'Password must be at least 8 characters' });
    }

    console.log(` Starting user registration for: ${email}`);

    // CREATE USER VIA SUPABASE ADMIN API (email_confirm: true to bypass email verification)
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email.trim(),
      password: password.trim(),
      email_confirm: true, //  Skip Supabase email verification - we handle OTP ourselves
      user_metadata: { full_name: fullName.trim() },
    });

    if (authError) {
      if (authError.message.includes('already exists')) {
        console.log(`User already exists: ${email}`);
        // Get existing user
        const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
        const existingUser = existingUsers?.users?.find(u => u.email === email.trim());
        if (!existingUser) {
          return res.status(400).json({ success: false, message: 'User already registered. Please login.' });
        }
        // Check if OTP already verified
        const { data: profile } = await supabaseAdmin
          .from('profiles')
          .select('otp_verified')
          .eq('id', existingUser.id)
          .single();

        if (profile?.otp_verified) {
          return res.status(400).json({ success: false, message: 'This email is already registered. Please login.' });
        }

        // Re-send OTP for unverified user
        const otp = generateOTP();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

        await supabaseAdmin.from('user_otp').insert({
          user_id: existingUser.id,
          otp_code: otp,
          expires_at: expiresAt,
        });

        await sendEmail(
          email.trim(),
          'Your Bhromon Verification Code',
          getRegistrationOTPEmail(fullName.trim(), otp)
        );

        return res.status(200).json({
          success: true,
          message: 'OTP resent to your email.',
          userId: existingUser.id,
          requiresOtp: true,
        });
      } else {
        return res.status(400).json({ success: false, message: `Auth error: ${authError.message}` });
      }
    }

    const userId = authUser?.user?.id;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Failed to get user ID' });
    }

    console.log(` User auth created: ${userId}`);

    // CHECK IF PROFILE EXISTS
    const { data: profileExists } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .single();

    if (profileExists) {
      await supabaseAdmin.from('profiles').update({
        full_name: fullName.trim(),
        username: email.trim().split('@')[0],
        user_type: 'user',
        otp_verified: false,
      }).eq('id', userId);
    } else {
      const { error: profileError } = await supabaseAdmin.from('profiles').insert({
        id: userId,
        full_name: fullName.trim(),
        username: email.trim().split('@')[0],
        user_type: 'user',
        otp_verified: false, //  Not verified yet
      });

      if (profileError) {
        return res.status(500).json({ success: false, message: `Profile error: ${profileError.message}` });
      }
    }

    console.log(` User profile created`);

    //  Generate OTP for user verification
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('user_otp').insert({
      user_id: userId,
      otp_code: otp,
      expires_at: expiresAt,
    });

    if (otpError) {
      console.error(` OTP creation error: ${otpError.message}`);
      return res.status(500).json({ success: false, message: `OTP error: ${otpError.message}` });
    }

    console.log(` User OTP generated: ${otp}`);

    // Send OTP email
    try {
      await sendEmail(
        email.trim(),
        'Verify Your Bhromon Account - OTP Code',
        getRegistrationOTPEmail(fullName.trim(), otp)
      );
    } catch (emailError) {
      console.warn(`OTP email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'Registration successful! OTP has been sent to your email.',
      userId: userId,
      requiresOtp: true, //  Tell Flutter to show OTP screen
    });

  } catch (error) {
    console.error(` User registration error: ${error.message}`);
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: VERIFY USER OTP  NEW
// ========================
router.post('/verify-user-otp', async (req, res) => {
  try {
    const { userId, otpCode } = req.body;

    if (!userId || !otpCode) {
      return res.status(400).json({ success: false, message: 'Missing userId or otpCode' });
    }

    console.log(` Verifying OTP for user: ${userId}`);

    // Get latest unused OTP
    const { data: otpRecord, error: otpError } = await supabaseAdmin
      .from('user_otp')
      .select()
      .eq('user_id', userId)
      .eq('is_used', false)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (otpError || !otpRecord) {
      return res.status(400).json({ success: false, message: 'No valid OTP found. Please request a new one.' });
    }

    if (otpRecord.otp_code !== otpCode.trim()) {
      return res.status(400).json({ success: false, message: 'Invalid OTP code. Please try again.' });
    }

    if (new Date() > new Date(otpRecord.expires_at)) {
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }

    console.log(` OTP validated`);

    // Mark OTP as used
    await supabaseAdmin.from('user_otp').update({
      is_used: true,
      used_at: new Date().toISOString(),
    }).eq('id', otpRecord.id);

    //  Mark user as OTP verified in profiles
    await supabaseAdmin.from('profiles').update({
      otp_verified: true,
      otp_verified_at: new Date().toISOString(),
    }).eq('id', userId);

    console.log(` User OTP verified successfully`);

    // Get user info for welcome email
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .single();

    // Send welcome email
    try {
      const { data: userAuth } = await supabaseAdmin.auth.admin.getUserById(userId);
      if (userAuth?.user?.email) {
        const firstName = profile?.full_name?.split(' ')[0] || 'Traveler';
        await sendEmail(
          userAuth.user.email,
          'Welcome to Bhromon - Start Your Travel Adventure! 🌍',
          getWelcomeEmail(firstName)
        );
      }
    } catch (emailError) {
      console.warn(`Welcome email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'Email verified successfully! Welcome to Bhromon.',
      userId: userId,
    });

  } catch (error) {
    console.error(` User OTP verification error: ${error.message}`);
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: RESEND USER OTP  NEW
// ========================
router.post('/resend-user-otp', async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'Missing userId' });
    }

    console.log(` Resending OTP for user: ${userId}`);

    // Get user info
    const { data: userAuth } = await supabaseAdmin.auth.admin.getUserById(userId);
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .single();

    if (!userAuth?.user?.email) {
      return res.status(400).json({ success: false, message: 'User not found' });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('user_otp').insert({
      user_id: userId,
      otp_code: otp,
      expires_at: expiresAt,
    });

    if (otpError) {
      return res.status(500).json({ success: false, message: `OTP error: ${otpError.message}` });
    }

    console.log(` New OTP generated: ${otp}`);

    try {
      await sendEmail(
        userAuth.user.email,
        'Your New Bhromon OTP Code',
        getRegistrationOTPEmail(profile?.full_name || 'User', otp)
      );
      console.log(` Resend OTP email sent`);
    } catch (emailError) {
      console.warn(`Resend OTP email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'New OTP sent to your email.',
      otpExpires: expiresAt,
    });

  } catch (error) {
    console.error(` Resend user OTP error: ${error.message}`);
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: AGENCY REGISTRATION
// ========================
router.post('/register/agency', async (req, res) => {
  try {
    const {
      agencyName, ownerFullName, ownerEmail, ownerPhone, password,
      officeAddress, officePhone, businessLicenseNumber, taxId,
      websiteUrl, bankAccountHolder, bankAccountNumber, bankName, branchName,
    } = req.body;

    if (!agencyName || !ownerFullName || !ownerEmail || !ownerPhone || !password || !officeAddress) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    console.log(` Starting agency registration for: ${ownerEmail}`);

    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: ownerEmail.trim(),
      password: password.trim(),
      email_confirm: true,
      user_metadata: { full_name: ownerFullName.trim() },
    });

    if (authError && !authError.message.includes('already exists')) {
      return res.status(400).json({ success: false, message: `Auth error: ${authError.message}` });
    }

    const userId = authUser?.user?.id;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Failed to get user ID' });
    }

    const { data: profileExists } = await supabaseAdmin
      .from('profiles').select('id').eq('id', userId).single();

    if (profileExists) {
      await supabaseAdmin.from('profiles').update({
        full_name: ownerFullName.trim(),
        username: ownerEmail.trim().split('@')[0],
        user_type: 'agency',
      }).eq('id', userId);
    } else {
      const { error: profileError } = await supabaseAdmin.from('profiles').insert({
        id: userId,
        full_name: ownerFullName.trim(),
        username: ownerEmail.trim().split('@')[0],
        user_type: 'agency',
      });
      if (profileError) {
        return res.status(500).json({ success: false, message: `Profile error: ${profileError.message}` });
      }
    }

    const { data: agencyExists } = await supabaseAdmin
      .from('travel_agencies').select('id').eq('user_id', userId).single();

    let agencyId;

    if (agencyExists) {
      const { data: updatedAgency, error: updateError } = await supabaseAdmin
        .from('travel_agencies').update({
          agency_name: agencyName.trim(), owner_full_name: ownerFullName.trim(),
          owner_email: ownerEmail.trim(), owner_phone: ownerPhone.trim(),
          office_address: officeAddress.trim(), office_phone: officePhone,
          business_license_number: businessLicenseNumber, tax_id: taxId,
          website_url: websiteUrl, bank_account_holder: bankAccountHolder,
          bank_account_number: bankAccountNumber, bank_name: bankName,
          branch_name: branchName, verification_status: 'approved',
          verified_at: new Date().toISOString(),
        }).eq('user_id', userId).select('id').single();

      if (updateError) {
        return res.status(500).json({ success: false, message: `Agency error: ${updateError.message}` });
      }
      agencyId = updatedAgency.id;
    } else {
      const { data: agencyData, error: agencyError } = await supabaseAdmin
        .from('travel_agencies').insert({
          user_id: userId, agency_name: agencyName.trim(),
          owner_full_name: ownerFullName.trim(), owner_email: ownerEmail.trim(),
          owner_phone: ownerPhone.trim(), office_address: officeAddress.trim(),
          office_phone: officePhone, business_license_number: businessLicenseNumber,
          tax_id: taxId, website_url: websiteUrl, bank_account_holder: bankAccountHolder,
          bank_account_number: bankAccountNumber, bank_name: bankName,
          branch_name: branchName, verification_status: 'approved',
          verified_at: new Date().toISOString(), otp_verified: false,
        }).select('id').single();

      if (agencyError) {
        return res.status(500).json({ success: false, message: `Agency error: ${agencyError.message}` });
      }
      agencyId = agencyData.id;
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('agency_otp').insert({
      agency_id: agencyId, otp_code: otp, expires_at: expiresAt,
    });

    if (otpError) {
      return res.status(500).json({ success: false, message: `OTP error: ${otpError.message}` });
    }

    try {
      await sendEmail(
        ownerEmail.trim(),
        'Verify Your Bhromon Agency Account - OTP Code',
        getRegistrationOTPEmail(agencyName.trim(), otp)
      );
    } catch (emailError) {
      console.warn(`OTP email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'Agency registered successfully! OTP has been sent to your email.',
      userId: userId, agencyId: agencyId, otpExpires: expiresAt,
    });

  } catch (error) {
    console.error(` Agency registration error: ${error.message}`);
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: VERIFY AGENCY OTP
// ========================
router.post('/verify-otp', async (req, res) => {
  try {
    const { agencyId, otpCode } = req.body;

    if (!agencyId || !otpCode) {
      return res.status(400).json({ success: false, message: 'Missing agencyId or otpCode' });
    }

    const { data: otpRecord, error: otpError } = await supabaseAdmin
      .from('agency_otp').select()
      .eq('agency_id', agencyId).eq('is_used', false)
      .order('created_at', { ascending: false }).limit(1).single();

    if (otpError || !otpRecord) {
      return res.status(400).json({ success: false, message: 'No valid OTP found' });
    }

    if (otpRecord.otp_code !== otpCode.trim()) {
      return res.status(400).json({ success: false, message: 'Invalid OTP code' });
    }

    if (new Date() > new Date(otpRecord.expires_at)) {
      return res.status(400).json({ success: false, message: 'OTP has expired' });
    }

    await supabaseAdmin.from('agency_otp').update({
      is_used: true, used_at: new Date().toISOString(),
    }).eq('id', otpRecord.id);

    await supabaseAdmin.from('travel_agencies').update({
      otp_verified: true, otp_verified_at: new Date().toISOString(),
    }).eq('id', agencyId);

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully! Your agency is now activated.',
      agencyId: agencyId,
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: RESEND AGENCY OTP
// ========================
router.post('/resend-otp', async (req, res) => {
  try {
    const { agencyId } = req.body;

    if (!agencyId) {
      return res.status(400).json({ success: false, message: 'Missing agencyId' });
    }

    const { data: agency, error: agencyError } = await supabaseAdmin
      .from('travel_agencies').select('agency_name, owner_email, id')
      .eq('id', agencyId).single();

    if (agencyError || !agency) {
      return res.status(400).json({ success: false, message: 'Agency not found' });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('agency_otp').insert({
      agency_id: agencyId, otp_code: otp, expires_at: expiresAt,
    });

    if (otpError) {
      return res.status(500).json({ success: false, message: `OTP error: ${otpError.message}` });
    }

    try {
      await sendEmail(agency.owner_email, 'Your New Bhromon OTP Code',
        getRegistrationOTPEmail(agency.agency_name, otp));
    } catch (emailError) {
      console.warn(`Resend OTP email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true, message: 'New OTP sent to your email.', otpExpires: expiresAt,
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: `Unexpected error: ${error.message}` });
  }
});

// ========================
// ENDPOINT: REQUEST PASSWORD RESET
// ========================
router.post('/request-password-reset', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email required' });

    await supabaseAdmin.auth.resetPasswordForEmail(email.trim());
    return res.status(200).json({ success: true, message: 'Password reset email sent.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ========================
// ENDPOINT: CHANGE PASSWORD
// ========================
router.post('/change-password', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({ success: false, message: 'No token provided' });

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }

    const { currentPassword, newPassword, confirmPassword } = req.body;

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ success: false, message: 'Passwords do not match' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    await supabaseAdmin.auth.admin.updateUserById(user.id, { password: newPassword });

    return res.status(200).json({ success: true, message: 'Password changed successfully.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

export default router;