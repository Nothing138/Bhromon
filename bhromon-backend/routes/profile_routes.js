// routes/profile_routes.js
import express from 'express';
import { createClient } from '@supabase/supabase-js';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = express.Router();

// ========================
// SUPABASE CLIENT
// ========================
let supabase = null;

function getSupabaseClient() {
  if (!supabase) {
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
    }
    supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );
  }
  return supabase;
}

// ========================
// MIDDLEWARE
// ========================
const auth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ success: false, error: 'No token provided' });
    }

    const client = getSupabaseClient();
    const { data: { user }, error } = await client.auth.getUser(token);
    
    if (error || !user) {
      return res.status(401).json({ success: false, error: 'Invalid token' });
    }

    req.user = user;
    req.supabase = client;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: error.message });
  }
};

// ========================
// FILE UPLOAD SETUP
// ========================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(process.cwd(), 'uploads', 'profiles');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, and WebP allowed'));
    }
  },
});

// ═══════════════════════════════════════════════════════════════════════════
// GET AGENCY PROFILE
// ═══════════════════════════════════════════════════════════════════════════
router.get('/agency/profile', auth, async (req, res) => {
  try {
    const client = req.supabase;
    const userId = req.user.id;

    const { data: agency, error } = await client
      .from('travel_agencies')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      console.error('Error fetching agency:', error);
      return res.status(404).json({
        success: false,
        error: 'Agency not found',
      });
    }

    res.json({
      success: true,
      data: agency,
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UPDATE AGENCY PROFILE
// ═══════════════════════════════════════════════════════════════════════════
router.put('/agency/profile', auth, async (req, res) => {
  try {
    const client = req.supabase;
    const userId = req.user.id;
    const {
      agencyName,
      ownerFullName,
      ownerEmail,
      ownerPhone,
      officeAddress,
      websiteUrl,
    } = req.body;

    // Validate required fields
    if (!agencyName || !ownerFullName) {
      return res.status(400).json({
        success: false,
        error: 'Agency name and owner name are required',
      });
    }

    // Update agency
    const { data: agency, error } = await client
      .from('travel_agencies')
      .update({
        agency_name: agencyName.trim(),
        owner_full_name: ownerFullName.trim(),
        owner_email: ownerEmail.trim(),
        owner_phone: ownerPhone.trim(),
        office_address: officeAddress?.trim() || null,
        website_url: websiteUrl?.trim() || null,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .select();

    if (error) {
      console.error('Update error:', error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }

    if (!agency || agency.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Agency not found',
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: agency[0],
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UPLOAD PROFILE IMAGE
// ═══════════════════════════════════════════════════════════════════════════
router.post(
  '/agency/profile/upload-image',
  auth,
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          error: 'No image file provided',
        });
      }

      const client = req.supabase;
      const userId = req.user.id;
      const filePath = `uploads/profiles/${req.file.filename}`;

      // Read file and upload to Supabase Storage
      const fileBuffer = fs.readFileSync(req.file.path);

      const { data, error: uploadError } = await client.storage
        .from('agency-profiles') // Make sure this bucket exists
        .upload(filePath, fileBuffer, {
          cacheControl: '3600',
          upsert: false,
        });

      if (uploadError) {
        console.error('Upload error:', uploadError);
        // Delete local file
        fs.unlinkSync(req.file.path);
        return res.status(500).json({
          success: false,
          error: uploadError.message,
        });
      }

      // Get public URL
      const { data: { publicUrl } } = client.storage
        .from('agency-profiles')
        .getPublicUrl(filePath);

      // Update agency with image URL
      const { data: agency, error: updateError } = await client
        .from('travel_agencies')
        .update({
          business_license_url: publicUrl,
          updated_at: new Date().toISOString(),
        })
        .eq('user_id', userId)
        .select();

      if (updateError) {
        console.error('Update error:', updateError);
      }

      // Delete local file after upload
      fs.unlinkSync(req.file.path);

      res.json({
        success: true,
        message: 'Image uploaded successfully',
        imageUrl: publicUrl,
        data: agency?.[0] || null,
      });
    } catch (error) {
      console.error('Error:', error);
      
      // Delete local file if upload fails
      if (req.file?.path && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }

      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════
// GET USER PROFILE
// ═══════════════════════════════════════════════════════════════════════════
router.get('/user/profile', auth, async (req, res) => {
  try {
    const client = req.supabase;
    const userId = req.user.id;

    const { data: profile, error } = await client
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Error fetching profile:', error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }

    // If profile doesn't exist, return basic user info
    if (!profile) {
      return res.json({
        success: true,
        data: {
          id: userId,
          username: null,
          full_name: null,
          avatar_url: null,
          bio: null,
          phone_number: null,
        },
      });
    }

    res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UPDATE USER PROFILE
// ═══════════════════════════════════════════════════════════════════════════
router.put('/user/profile', auth, async (req, res) => {
  try {
    const client = req.supabase;
    const userId = req.user.id;
    const { username, fullName, bio, phoneNumber } = req.body;

    const { data: profile, error } = await client
      .from('profiles')
      .upsert({
        id: userId,
        username: username?.trim() || null,
        full_name: fullName?.trim() || null,
        bio: bio?.trim() || null,
        phone_number: phoneNumber?.trim() || null,
        updated_at: new Date().toISOString(),
      })
      .select();

    if (error) {
      console.error('Update error:', error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: profile[0],
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

export default router;
