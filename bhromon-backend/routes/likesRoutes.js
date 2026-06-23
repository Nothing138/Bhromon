import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

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
// TOGGLE LIKE/UNLIKE
// ═══════════════════════════════════════════════════════════════════════════
router.post('/toggle', auth, async (req, res) => {
  try {
    const { postId } = req.body;
    const userId = req.user.id;

    if (!postId) {
      return res.status(400).json({
        success: false,
        error: 'postId is required'
      });
    }

    // Check if already liked
    const { data: existing, error: checkError } = await supabase
      .from('post_likes')
      .select('id')
      .eq('post_id', postId)
      .eq('user_id', userId)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      throw checkError;
    }

    if (existing) {
      // Unlike
      const { error: deleteError } = await supabase
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);

      if (deleteError) throw deleteError;

      return res.json({
        success: true,
        liked: false,
        message: 'Post unliked'
      });
    } else {
      // Like
      const { error: insertError } = await supabase
        .from('post_likes')
        .insert({
          post_id: postId,
          user_id: userId,
          created_at: new Date().toISOString()
        });

      if (insertError) throw insertError;

      return res.json({
        success: true,
        liked: true,
        message: 'Post liked'
      });
    }
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CHECK IF USER LIKED POST
// ═══════════════════════════════════════════════════════════════════════════
router.get('/check/:postId', auth, async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.id;

    const { data, error } = await supabase
      .from('post_likes')
      .select('id')
      .eq('post_id', postId)
      .eq('user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    res.json({
      success: true,
      liked: data !== null
    });
  } catch (error) {
    console.error('Error checking like:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET LIKES COUNT
// ═══════════════════════════════════════════════════════════════════════════
router.get('/count/:postId', async (req, res) => {
  try {
    const { postId } = req.params;

    const { data, error } = await supabase
      .from('post_likes')
      .select('id', { count: 'exact' })
      .eq('post_id', postId);

    if (error) throw error;

    res.json({
      success: true,
      count: data.length || 0
    });
  } catch (error) {
    console.error('Error getting likes count:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET USERS WHO LIKED POST
// ═══════════════════════════════════════════════════════════════════════════
router.get('/list/:postId', async (req, res) => {
  try {
    const { postId } = req.params;

    const { data, error } = await supabase
      .from('post_likes')
      .select(`
        id,
        user_id,
        created_at,
        user:user_id(
          id,
          full_name,
          username,
          avatar_url
        )
      `)
      .eq('post_id', postId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: data || [],
      count: data?.length || 0
    });
  } catch (error) {
    console.error('Error getting likes list:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// DELETE LIKE (Admin)
// ═══════════════════════════════════════════════════════════════════════════
router.delete('/:postId/:userId', auth, async (req, res) => {
  try {
    const { postId, userId } = req.params;
    
    // Verify admin or owner
    if (req.user.id !== userId && !req.user.isAdmin) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    const { error } = await supabase
      .from('post_likes')
      .delete()
      .eq('post_id', postId)
      .eq('user_id', userId);

    if (error) throw error;

    res.json({
      success: true,
      message: 'Like deleted'
    });
  } catch (error) {
    console.error('Error deleting like:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CLEAR ALL LIKES FOR POST (Admin)
// ═══════════════════════════════════════════════════════════════════════════
router.delete('/clear/:postId', auth, async (req, res) => {
  try {
    const { postId } = req.params;
    
    if (!req.user.isAdmin) {
      return res.status(403).json({
        success: false,
        error: 'Admin access required'
      });
    }

    const { error } = await supabase
      .from('post_likes')
      .delete()
      .eq('post_id', postId);

    if (error) throw error;

    res.json({
      success: true,
      message: 'All likes cleared for post'
    });
  } catch (error) {
    console.error('Error clearing likes:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;