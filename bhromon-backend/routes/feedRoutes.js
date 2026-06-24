import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ========================
// AUTH MIDDLEWARE
// ========================
const auth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ success: false, error: 'No token provided' });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ success: false, error: 'Invalid token' });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// GET COMBINED FEED (Posts + Events) - FIXED WITH ALL DATA
// ═══════════════════════════════════════════════════════════════════════════
router.get('/combined', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    // ── POSTS WITH FULL USER DATA ──
    const { data: posts, error: postsError } = await supabase
      .from('posts')
      .select(`
        id,
        user_id,
        content,
        image_url,
        location_name,
        contact_number,
        created_at,
        likes_count,
        comments_count,
        user:user_id(
          id,
          full_name,
          username,
          avatar_url,
          phone_number
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (postsError) throw postsError;

    // ── EVENTS WITH AGENCY DATA ──
    const { data: events, error: eventsError } = await supabase
      .from('agency_events')
      .select(`
        id,
        agency_id,
        title,
        description,
        location,
        event_date,
        image_url,
        price,
        category,
        created_at,
        agency:agency_id(
          id,
          user_id,
          agency_name,
          owner_full_name,
          owner_phone,
          office_phone,
          office_address,
          website_url,
          verification_status
        )
      `)
      .order('event_date', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (eventsError) throw eventsError;

    // ── TRANSFORM POSTS ──
    const postsWithType = (posts || []).map(p => ({
      id: p.id,
      type: 'post',
      user_id: p.user_id,
      content: p.content,
      image_url: p.image_url,
      location_name: p.location_name,
      contact_number: p.contact_number,
      created_at: p.created_at,
      likes_count: p.likes_count || 0,
      comments_count: p.comments_count || 0,
      // User data
      user_name: p.user?.username || 'Unknown',
      user_full_name: p.user?.full_name || 'Unknown User',
      user_avatar: p.user?.avatar_url,
      user_phone: p.user?.phone_number,
      user_id: p.user?.id,
      sortDate: p.created_at,
    }));

    // ── TRANSFORM EVENTS ──
    const eventsWithType = (events || []).map(e => ({
      id: e.id,
      type: 'event',
      agency_id: e.agency_id,
      title: e.title,
      description: e.description,
      location: e.location,
      event_date: e.event_date,
      image_url: e.image_url,
      price: e.price,
      category: e.category,
      created_at: e.created_at,
      sortDate: e.event_date,
      // Agency data
      agency_name: e.agency?.agency_name || 'Unknown Agency',
      owner_full_name: e.agency?.owner_full_name,
      owner_phone: e.agency?.owner_phone,
      office_phone: e.agency?.office_phone,
      office_address: e.agency?.office_address,
      website_url: e.agency?.website_url,
      verification_status: e.agency?.verification_status,
      user_id: e.agency?.user_id,
    }));

    // ── COMBINE AND SORT ──
    const combined = [...postsWithType, ...eventsWithType].sort((a, b) => {
      const dateA = new Date(a.sortDate);
      const dateB = new Date(b.sortDate);
      return dateB - dateA;
    });

    res.json({
      success: true,
      data: combined,
      count: combined.length
    });
  } catch (error) {
    console.error('Error fetching combined feed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET FEED - Posts Only (WITH FULL DATA)
// ═══════════════════════════════════════════════════════════════════════════
router.get('/posts', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const { data, error } = await supabase
      .from('posts')
      .select(`
        *,
        user:user_id(
          id,
          full_name,
          username,
          avatar_url,
          phone_number
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (error) throw error;

    res.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET FEED - Events Only (WITH AGENCY DATA)
// ═══════════════════════════════════════════════════════════════════════════
router.get('/events', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const { data, error } = await supabase
      .from('agency_events')
      .select(`
        *,
        agency:agency_id(
          id,
          user_id,
          agency_name,
          owner_full_name,
          owner_phone,
          office_phone,
          office_address,
          website_url,
          verification_status
        )
      `)
      .order('event_date', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (error) throw error;

    res.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;