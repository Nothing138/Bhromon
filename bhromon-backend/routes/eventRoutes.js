import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

// ========================
// LAZY SUPABASE INITIALIZATION
// ========================
let supabase = null;

function getSupabaseClient() {
  if (!supabase) {
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required in .env file');
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
// AUTH MIDDLEWARE
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
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// GET ALL EVENTS FOR CURRENT AGENCY
// ═══════════════════════════════════════════════════════════════════════════
router.get('/agency/events', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const userId = req.user.id;

    // Get agency_id from travel_agencies table
    const { data: agencyData, error: agencyError } = await client
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (agencyError || !agencyData) {
      return res.status(404).json({ error: 'Agency not found' });
    }

    const agencyId = agencyData.id;

    // Fetch all events for this agency
    const { data: events, error } = await client
      .from('agency_events')
      .select('*')
      .eq('agency_id', agencyId)
      .order('event_date', { ascending: true });

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({
      success: true,
      data: events || []
    });
  } catch (error) {
    console.error('Error fetching agency events:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET SINGLE EVENT BY ID
// ═══════════════════════════════════════════════════════════════════════════
router.get('/events/:eventId', async (req, res) => {
  try {
    const client = getSupabaseClient();
    const { eventId } = req.params;

    const { data: event, error } = await client
      .from('agency_events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (error) {
      return res.status(404).json({
        success: false,
        error: 'Event not found'
      });
    }

    res.json({
      success: true,
      data: event
    });
  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CREATE NEW EVENT
// ═══════════════════════════════════════════════════════════════════════════
router.post('/agency/events', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const userId = req.user.id;
    const {
      title,
      description,
      location,
      eventDate,
      price,
      capacity,
      category,
      imageUrl,
    } = req.body;

    // Validate required fields
    if (!title || !description || !location || !eventDate || !capacity) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Get agency_id
    const { data: agencyData, error: agencyError } = await client
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (agencyError || !agencyData) {
      return res.status(404).json({
        success: false,
        error: 'Agency not found'
      });
    }

    const agencyId = agencyData.id;

    // Insert event
    const { data: event, error } = await client
      .from('agency_events')
      .insert({
        agency_id: agencyId,
        title,
        description,
        location,
        event_date: new Date(eventDate).toISOString(),
        price: parseFloat(price) || 0,
        capacity: parseInt(capacity),
        category: category || 'general',
        image_url: imageUrl || null,
        status: 'active',
        booked_count: 0,
      })
      .select();

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      data: event[0],
    });
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UPDATE EVENT
// ═══════════════════════════════════════════════════════════════════════════
router.put('/events/:eventId', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const { eventId } = req.params;
    const {
      title,
      description,
      location,
      eventDate,
      price,
      capacity,
      category,
      imageUrl,
    } = req.body;

    const updateData = {};
    if (title) updateData.title = title;
    if (description) updateData.description = description;
    if (location) updateData.location = location;
    if (eventDate) updateData.event_date = new Date(eventDate).toISOString();
    if (price !== undefined) updateData.price = parseFloat(price);
    if (capacity) updateData.capacity = parseInt(capacity);
    if (category) updateData.category = category;
    if (imageUrl !== undefined) updateData.image_url = imageUrl;
    updateData.updated_at = new Date().toISOString();

    const { data: event, error } = await client
      .from('agency_events')
      .update(updateData)
      .eq('id', eventId)
      .select();

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'Event updated successfully',
      data: event[0],
    });
  } catch (error) {
    console.error('Error updating event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// DELETE EVENT
// ═══════════════════════════════════════════════════════════════════════════
router.delete('/events/:eventId', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const { eventId } = req.params;

    const { error } = await client
      .from('agency_events')
      .delete()
      .eq('id', eventId);

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'Event deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CANCEL EVENT (change status)
// ═══════════════════════════════════════════════════════════════════════════
router.patch('/events/:eventId/cancel', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const { eventId } = req.params;

    const { data: event, error } = await client
      .from('agency_events')
      .update({
        status: 'cancelled',
        updated_at: new Date().toISOString()
      })
      .eq('id', eventId)
      .select();

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'Event cancelled successfully',
      data: event[0],
    });
  } catch (error) {
    console.error('Error cancelling event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// COMPLETE EVENT
// ═══════════════════════════════════════════════════════════════════════════
router.patch('/events/:eventId/complete', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const { eventId } = req.params;

    const { data: event, error } = await client
      .from('agency_events')
      .update({
        status: 'completed',
        updated_at: new Date().toISOString()
      })
      .eq('id', eventId)
      .select();

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'Event marked as completed',
      data: event[0],
    });
  } catch (error) {
    console.error('Error completing event:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET UPCOMING EVENTS FOR AGENCY
// ═══════════════════════════════════════════════════════════════════════════
router.get('/agency/events/upcoming', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const userId = req.user.id;
    const now = new Date().toISOString();

    // Get agency_id
    const { data: agencyData, error: agencyError } = await client
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (agencyError || !agencyData) {
      return res.status(404).json({
        success: false,
        error: 'Agency not found'
      });
    }

    const agencyId = agencyData.id;

    // Fetch upcoming events
    const { data: events, error } = await client
      .from('agency_events')
      .select('*')
      .eq('agency_id', agencyId)
      .eq('status', 'active')
      .gt('event_date', now)
      .order('event_date', { ascending: true });

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      data: events || []
    });
  } catch (error) {
    console.error('Error fetching upcoming events:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET PAST EVENTS FOR AGENCY
// ═══════════════════════════════════════════════════════════════════════════
router.get('/agency/events/past', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const userId = req.user.id;
    const now = new Date().toISOString();

    // Get agency_id
    const { data: agencyData, error: agencyError } = await client
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (agencyError || !agencyData) {
      return res.status(404).json({
        success: false,
        error: 'Agency not found'
      });
    }

    const agencyId = agencyData.id;

    // Fetch past events
    const { data: events, error } = await client
      .from('agency_events')
      .select('*')
      .eq('agency_id', agencyId)
      .or(`event_date.lt.${now},status.neq.active`)
      .order('event_date', { ascending: false });

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    res.json({
      success: true,
      data: events || []
    });
  } catch (error) {
    console.error('Error fetching past events:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET EVENT STATISTICS
// ═══════════════════════════════════════════════════════════════════════════
router.get('/agency/events/stats', auth, async (req, res) => {
  try {
    const client = getSupabaseClient();
    const userId = req.user.id;

    // Get agency_id
    const { data: agencyData, error: agencyError } = await client
      .from('travel_agencies')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (agencyError || !agencyData) {
      return res.status(404).json({
        success: false,
        error: 'Agency not found'
      });
    }

    const agencyId = agencyData.id;

    // Get all events for this agency
    const { data: events, error } = await client
      .from('agency_events')
      .select('*')
      .eq('agency_id', agencyId);

    if (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    const now = new Date();
    const stats = {
      total_events: events.length,
      active_events: events.filter((e) => e.status === 'active').length,
      upcoming_events: events.filter(
        (e) => new Date(e.event_date) > now && e.status === 'active'
      ).length,
      completed_events: events.filter((e) => e.status === 'completed').length,
      cancelled_events: events.filter((e) => e.status === 'cancelled').length,
      total_capacity: events.reduce((sum, e) => sum + (e.capacity || 0), 0),
      total_bookings: events.reduce((sum, e) => sum + (e.booked_count || 0), 0),
      total_revenue: events.reduce((sum, e) => sum + ((e.price || 0) * (e.booked_count || 0)), 0),
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching event stats:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;