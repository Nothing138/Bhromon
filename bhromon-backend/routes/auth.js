// backend/routes/auth.js - WITH NODEMAILER + GMAIL SMTP
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
// GMAIL CONFIGURATION (Nodemailer)
// ========================
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASSWORD, // App Password, not regular password
  },
});

// Test connection on startup
transporter.verify((error, success) => {
  if (error) {
    console.error('❌ Gmail SMTP connection error:', error.message);
  } else {
    console.log('✅ Gmail SMTP connection successful');
  }
});

async function sendEmail(email, subject, html) {
  try {
    console.log(`📧 Sending email to ${email}: ${subject}`);

    const mailOptions = {
      from: `"Bhromon" <${process.env.GMAIL_USER}>`,
      to: email,
      subject,
      html,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent successfully to ${email} (Message ID: ${info.messageId})`);
    return true;
  } catch (error) {
    console.error(`❌ Email send error: ${error.message}`);
    throw error;
  }
}

// ========================
// HELPER: OTP Generator
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
        
        <p style="color: #666; line-height: 1.6;">
          Your account has been successfully created and approved! To complete your registration, please verify your email with the OTP code below.
        </p>

        <div style="background: white; padding: 30px; margin: 30px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea;">
          <p style="color: #999; margin: 0 0 10px 0; font-size: 14px;">Your OTP Code</p>
          <p style="color: #667eea; font-size: 48px; font-weight: bold; margin: 0; letter-spacing: 8px;">${otp}</p>
          <p style="color: #999; margin: 10px 0 0 0; font-size: 12px;">This code expires in 10 minutes</p>
        </div>

        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #1976d2; margin: 0; font-size: 14px;">
            ✅ Your account is approved! Enter the OTP to activate.
          </p>
        </div>

        <h3 style="color: #333; margin-top: 30px; margin-bottom: 15px;">Next Steps:</h3>
        <ol style="color: #666; line-height: 1.8;">
          <li>Enter the OTP code in the app</li>
          <li>Complete your profile setup</li>
          <li>Start exploring Bhromon!</li>
        </ol>

        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="color: #856404; margin: 0; font-size: 12px;">
            🔒 Never share this code with anyone.
          </p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p style="color: #999; font-size: 12px;">
          © 2024 Bhromon. All rights reserved.
        </p>
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
        <h2 style="color: #333; margin-top: 0;">Welcome to Bhromon, ${firstName}! 🎉</h2>
        
        <p style="color: #666; line-height: 1.6;">
          Thank you for joining our travel community. Your account has been created successfully!
        </p>

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
        <p style="color: #999; font-size: 12px;">
          © 2024 Bhromon. All rights reserved.
        </p>
      </div>
    </div>
  `;
}

// ========================
// ENDPOINT: USER REGISTRATION (WITH DUPLICATE HANDLING)
// ========================
router.post('/register/user', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters',
      });
    }

    console.log(`🔄 Starting user registration for: ${email}`);

    // Check if user already exists
    const { data: existingUser, error: checkError } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', email)
      .single();

    // ✅ CREATE USER VIA SUPABASE ADMIN API
    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email: email.trim(),
        password: password.trim(),
        email_confirm: true,
        user_metadata: {
          full_name: fullName.trim(),
        },
      });

    if (authError) {
      // Check if user already exists
      if (authError.message.includes('already exists')) {
        console.log(`⚠️ User already exists: ${email}`);
        // Continue with profile creation/update
      } else {
        console.error(`❌ Auth creation error: ${authError.message}`);
        return res.status(400).json({
          success: false,
          message: `Auth error: ${authError.message}`,
        });
      }
    }

    const userId = authUser?.user?.id;
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'Failed to get user ID',
      });
    }

    console.log(`✅ User auth created/exists: ${userId}`);

    // ✅ CHECK IF PROFILE EXISTS - If yes, UPDATE; if no, INSERT
    const { data: profileExists } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .single();

    if (profileExists) {
      console.log(`⚠️ Profile already exists, updating...`);
      const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({
          full_name: fullName.trim(),
          username: email.trim().split('@')[0],
          user_type: 'user',
        })
        .eq('id', userId);

      if (updateError) {
        console.error(`❌ Profile update error: ${updateError.message}`);
        return res.status(500).json({
          success: false,
          message: `Profile error: ${updateError.message}`,
        });
      }
      console.log(`✅ User profile updated`);
    } else {
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .insert({
          id: userId,
          full_name: fullName.trim(),
          username: email.trim().split('@')[0],
          user_type: 'user',
        });

      if (profileError) {
        console.error(`❌ Profile creation error: ${profileError.message}`);
        return res.status(500).json({
          success: false,
          message: `Profile error: ${profileError.message}`,
        });
      }
      console.log(`✅ User profile created`);
    }

    // Send welcome email
    try {
      const firstName = fullName.split(' ')[0];
      await sendEmail(
        email.trim(),
        'Welcome to Bhromon - Start Your Travel Adventure! 🌍',
        getWelcomeEmail(firstName)
      );
    } catch (emailError) {
      console.warn(`⚠️ Welcome email failed (non-critical): ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'User registered successfully!',
      userId: userId,
    });
  } catch (error) {
    console.error(`❌ User registration error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: AGENCY REGISTRATION (WITH DUPLICATE HANDLING)
// ========================
router.post('/register/agency', async (req, res) => {
  try {
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

    if (!agencyName || !ownerFullName || !ownerEmail || !ownerPhone || !password || !officeAddress) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    console.log(`🔄 Starting agency registration for: ${ownerEmail}`);

    // ✅ CREATE USER VIA SUPABASE ADMIN API
    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email: ownerEmail.trim(),
        password: password.trim(),
        email_confirm: true,
        user_metadata: {
          full_name: ownerFullName.trim(),
        },
      });

    if (authError && !authError.message.includes('already exists')) {
      console.error(`❌ Auth creation error: ${authError.message}`);
      return res.status(400).json({
        success: false,
        message: `Auth error: ${authError.message}`,
      });
    }

    const userId = authUser?.user?.id;
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'Failed to get user ID',
      });
    }

    console.log(`✅ Agency auth created/exists: ${userId}`);

    // ✅ CHECK IF PROFILE EXISTS - If yes, UPDATE; if no, INSERT
    const { data: profileExists } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .single();

    if (profileExists) {
      console.log(`⚠️ Profile already exists, updating...`);
      const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({
          full_name: ownerFullName.trim(),
          username: ownerEmail.trim().split('@')[0],
          user_type: 'agency',
        })
        .eq('id', userId);

      if (updateError) {
        console.error(`❌ Profile update error: ${updateError.message}`);
        return res.status(500).json({
          success: false,
          message: `Profile error: ${updateError.message}`,
        });
      }
      console.log(`✅ Agency profile updated`);
    } else {
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .insert({
          id: userId,
          full_name: ownerFullName.trim(),
          username: ownerEmail.trim().split('@')[0],
          user_type: 'agency',
        });

      if (profileError) {
        console.error(`❌ Profile creation error: ${profileError.message}`);
        return res.status(500).json({
          success: false,
          message: `Profile error: ${profileError.message}`,
        });
      }
      console.log(`✅ Agency profile created`);
    }

    // ✅ Check if agency record already exists
    const { data: agencyExists } = await supabaseAdmin
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    let agencyId;

    if (agencyExists) {
      // Update existing agency
      console.log(`⚠️ Agency record already exists, updating...`);
      const { data: updatedAgency, error: updateError } = await supabaseAdmin
        .from('travel_agencies')
        .update({
          agency_name: agencyName.trim(),
          owner_full_name: ownerFullName.trim(),
          owner_email: ownerEmail.trim(),
          owner_phone: ownerPhone.trim(),
          office_address: officeAddress.trim(),
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
        console.error(`❌ Agency update error: ${updateError.message}`);
        return res.status(500).json({
          success: false,
          message: `Agency error: ${updateError.message}`,
        });
      }
      agencyId = updatedAgency.id;
      console.log(`✅ Agency record updated: ${agencyId}`);
    } else {
      // Create new agency
      const { data: agencyData, error: agencyError } = await supabaseAdmin
        .from('travel_agencies')
        .insert({
          user_id: userId,
          agency_name: agencyName.trim(),
          owner_full_name: ownerFullName.trim(),
          owner_email: ownerEmail.trim(),
          owner_phone: ownerPhone.trim(),
          office_address: officeAddress.trim(),
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
        console.error(`❌ Agency creation error: ${agencyError.message}`);
        return res.status(500).json({
          success: false,
          message: `Agency error: ${agencyError.message}`,
        });
      }
      agencyId = agencyData.id;
      console.log(`✅ Agency record created: ${agencyId}`);
    }

    // Generate OTP
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('agency_otp').insert({
      agency_id: agencyId,
      otp_code: otp,
      expires_at: expiresAt,
    });

    if (otpError) {
      console.error(`❌ OTP creation error: ${otpError.message}`);
      return res.status(500).json({
        success: false,
        message: `OTP error: ${otpError.message}`,
      });
    }

    console.log(`✅ OTP generated: ${otp}`);

    // Send OTP email
    try {
      await sendEmail(
        ownerEmail.trim(),
        'Verify Your Bhromon Agency Account - OTP Code',
        getRegistrationOTPEmail(agencyName.trim(), otp)
      );
      console.log(`✅ OTP email sent successfully`);
    } catch (emailError) {
      console.warn(`⚠️ OTP email failed (non-critical): ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'Agency registered successfully! OTP has been sent to your email.',
      userId: userId,
      agencyId: agencyId,
      otpExpires: expiresAt,
    });
  } catch (error) {
    console.error(`❌ Agency registration error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: VERIFY OTP
// ========================
router.post('/verify-otp', async (req, res) => {
  try {
    const { agencyId, otpCode } = req.body;

    if (!agencyId || !otpCode) {
      return res.status(400).json({
        success: false,
        message: 'Missing agencyId or otpCode',
      });
    }

    console.log(`🔄 Verifying OTP for agency: ${agencyId}`);

    const { data: otpRecord, error: otpError } = await supabaseAdmin
      .from('agency_otp')
      .select()
      .eq('agency_id', agencyId)
      .eq('is_used', false)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (otpError || !otpRecord) {
      return res.status(400).json({
        success: false,
        message: 'No valid OTP found',
      });
    }

    if (otpRecord.otp_code !== otpCode.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP code',
      });
    }

    if (new Date() > new Date(otpRecord.expires_at)) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired',
      });
    }

    console.log(`✅ OTP validated`);

    await supabaseAdmin
      .from('agency_otp')
      .update({
        is_used: true,
        used_at: new Date().toISOString(),
      })
      .eq('id', otpRecord.id);

    await supabaseAdmin
      .from('travel_agencies')
      .update({
        otp_verified: true,
        otp_verified_at: new Date().toISOString(),
      })
      .eq('id', agencyId);

    console.log(`✅ OTP verified successfully`);

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully! Your agency is now activated.',
      agencyId: agencyId,
    });
  } catch (error) {
    console.error(`❌ OTP verification error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: RESEND OTP
// ========================
router.post('/resend-otp', async (req, res) => {
  try {
    const { agencyId } = req.body;

    if (!agencyId) {
      return res.status(400).json({
        success: false,
        message: 'Missing agencyId',
      });
    }

    console.log(`🔄 Resending OTP for agency: ${agencyId}`);

    const { data: agency, error: agencyError } = await supabaseAdmin
      .from('travel_agencies')
      .select('agency_name, owner_email, id')
      .eq('id', agencyId)
      .single();

    if (agencyError || !agency) {
      return res.status(400).json({
        success: false,
        message: 'Agency not found',
      });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: otpError } = await supabaseAdmin.from('agency_otp').insert({
      agency_id: agencyId,
      otp_code: otp,
      expires_at: expiresAt,
    });

    if (otpError) {
      return res.status(500).json({
        success: false,
        message: `OTP error: ${otpError.message}`,
      });
    }

    console.log(`✅ New OTP generated: ${otp}`);

    try {
      await sendEmail(
        agency.owner_email,
        'Your New Bhromon OTP Code',
        getRegistrationOTPEmail(agency.agency_name, otp)
      );
      console.log(`✅ Resend OTP email sent`);
    } catch (emailError) {
      console.warn(`⚠️ Resend OTP email failed: ${emailError.message}`);
    }

    return res.status(200).json({
      success: true,
      message: 'New OTP sent to your email',
      otpExpires: expiresAt,
    });
  } catch (error) {
    console.error(`❌ Resend OTP error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

export default router;