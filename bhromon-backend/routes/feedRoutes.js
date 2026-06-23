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
// GET COMBINED FEED (Posts + Events)
// ═══════════════════════════════════════════════════════════════════════════
router.get('/combined', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    // Fetch posts
    const { data: posts, error: postsError } = await supabase
      .from('posts')
      .select(`
        id,
        user_id,
        content,
        image_url,
        location_name,
        created_at,
        user_name,
        user_full_name,
        user_avatar_url,
        likes_count,
        comments_count
      `)
      .order('created_at', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (postsError) throw postsError;

    // Fetch events
    const { data: events, error: eventsError } = await supabase
      .from('agency_events')
      .select(`
        id,
        agency_id,
        title,
        description,
        location,
        event_date,
        price,
        category,
        created_at
      `)
      .order('event_date', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (eventsError) throw eventsError;

    // Transform and combine
    const postsWithType = (posts || []).map(p => ({
      ...p,
      type: 'post'
    }));

    const eventsWithType = (events || []).map(e => ({
      ...e,
      type: 'event'
    }));

    // Combine and sort by date
    const combined = [...postsWithType, ...eventsWithType].sort((a, b) => {
      const dateA = new Date(a.created_at || a.event_date);
      const dateB = new Date(b.created_at || b.event_date);
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
// GET FEED - Posts Only
// ═══════════════════════════════════════════════════════════════════════════
router.get('/posts', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const { data, error } = await supabase
      .from('posts')
      .select('*')
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
// GET FEED - Events Only
// ═══════════════════════════════════════════════════════════════════════════
router.get('/events', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const { data, error } = await supabase
      .from('agency_events')
      .select('*')
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