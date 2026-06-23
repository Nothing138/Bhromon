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
// LOG CALL
// ═══════════════════════════════════════════════════════════════════════════
router.post('/call', auth, async (req, res) => {
  try {
    const { agencyId, postId, duration } = req.body;
    const userId = req.user.id;

    if (!agencyId) {
      return res.status(400).json({
        success: false,
        error: 'agencyId is required'
      });
    }

    const { data, error } = await supabase
      .from('call_logs')
      .insert({
        from_user_id: userId,
        to_agency_id: agencyId,
        post_id: postId || null,
        status: 'initiated',
        call_duration_seconds: duration || 0,
        created_at: new Date().toISOString()
      })
      .select();

    if (error) throw error;

    res.json({
      success: true,
      data: data,
      message: 'Call initiated'
    });
  } catch (error) {
    console.error('Error logging call:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UPDATE CALL STATUS
// ═══════════════════════════════════════════════════════════════════════════
router.put('/call/:callId', auth, async (req, res) => {
  try {
    const { callId } = req.params;
    const { status, duration } = req.body;

    if (!['initiated', 'accepted', 'rejected', 'missed', 'completed'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status'
      });
    }

    const { data, error } = await supabase
      .from('call_logs')
      .update({
        status,
        call_duration_seconds: duration || 0,
        ended_at: new Date().toISOString()
      })
      .eq('id', callId)
      .select();

    if (error) throw error;

    res.json({
      success: true,
      data: data,
      message: 'Call status updated'
    });
  } catch (error) {
    console.error('Error updating call:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET CALL LOGS
// ═══════════════════════════════════════════════════════════════════════════
router.get('/calls/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    const { data, error } = await supabase
      .from('call_logs')
      .select(`
        *,
        agency:to_agency_id(agency_name, owner_phone)
      `)
      .eq('from_user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (error) throw error;

    res.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Error getting call logs:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// SEND MESSAGE
// ═══════════════════════════════════════════════════════════════════════════
router.post('/message', auth, async (req, res) => {
  try {
    const { receiverId, content, messageType = 'text' } = req.body;
    const senderId = req.user.id;

    if (!receiverId || !content) {
      return res.status(400).json({
        success: false,
        error: 'receiverId and content are required'
      });
    }

    // Create message
    const { data: messageData, error: messageError } = await supabase
      .from('messages')
      .insert({
        sender_id: senderId,
        receiver_id: receiverId,
        content,
        message_type: messageType,
        read_status: false,
        created_at: new Date().toISOString()
      })
      .select();

    if (messageError) throw messageError;

    // Update or create conversation metadata
    const { data: existingConversation } = await supabase
      .from('conversation_metadata')
      .select('id')
      .or(`and(user_1_id.eq.${senderId},user_2_id.eq.${receiverId}),and(user_1_id.eq.${receiverId},user_2_id.eq.${senderId})`)
      .single();

    if (existingConversation) {
      // Update existing
      await supabase
        .from('conversation_metadata')
        .update({
          last_message: content,
          last_message_time: new Date().toISOString(),
          message_count: (existingConversation.message_count || 0) + 1
        })
        .eq('id', existingConversation.id);
    } else {
      // Create new
      await supabase
        .from('conversation_metadata')
        .insert({
          user_1_id: senderId,
          user_2_id: receiverId,
          last_message: content,
          last_message_time: new Date().toISOString(),
          message_count: 1,
          created_at: new Date().toISOString()
        });
    }

    res.json({
      success: true,
      data: messageData,
      message: 'Message sent'
    });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET MESSAGES (Conversation)
// ═══════════════════════════════════════════════════════════════════════════
router.get('/messages/:conversationWith', auth, async (req, res) => {
  try {
    const { conversationWith } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const userId = req.user.id;

    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .or(`and(sender_id.eq.${userId},receiver_id.eq.${conversationWith}),and(sender_id.eq.${conversationWith},receiver_id.eq.${userId})`)
      .order('created_at', { ascending: false })
      .limit(limit)
      .offset(offset);

    if (error) throw error;

    res.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Error getting messages:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// MARK MESSAGE AS READ
// ═══════════════════════════════════════════════════════════════════════════
router.put('/message/read/:messageId', auth, async (req, res) => {
  try {
    const { messageId } = req.params;

    const { data, error } = await supabase
      .from('messages')
      .update({
        read_status: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', messageId)
      .select();

    if (error) throw error;

    res.json({
      success: true,
      data: data,
      message: 'Message marked as read'
    });
  } catch (error) {
    console.error('Error marking message as read:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// SHARE POST
// ═══════════════════════════════════════════════════════════════════════════
router.post('/share', auth, async (req, res) => {
  try {
    const { postId, shareWithUserIds = [] } = req.body;
    const userId = req.user.id;

    if (!postId) {
      return res.status(400).json({
        success: false,
        error: 'postId is required'
      });
    }

    // Get post details
    const { data: post, error: postError } = await supabase
      .from('posts')
      .select('*')
      .eq('id', postId)
      .single();

    if (postError) throw postError;

    // Record share
    const { data, error } = await supabase
      .from('post_shares')
      .insert({
        post_id: postId,
        shared_by_user_id: userId,
        shared_to_user_ids: shareWithUserIds,
        created_at: new Date().toISOString()
      })
      .select();

    if (error) throw error;

    // If sharing with specific users, send notifications/messages
    if (shareWithUserIds.length > 0) {
      const shareText = `Check out this: ${post.content}`;
      
      for (const recipientId of shareWithUserIds) {
        await supabase.from('messages').insert({
          sender_id: userId,
          receiver_id: recipientId,
          content: `📤 Shared: ${shareText}`,
          message_type: 'share',
          read_status: false,
          created_at: new Date().toISOString()
        });
      }
    }

    res.json({
      success: true,
      data: data,
      message: 'Post shared successfully'
    });
  } catch (error) {
    console.error('Error sharing post:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET SHARES FOR POST
// ═══════════════════════════════════════════════════════════════════════════
router.get('/shares/:postId', async (req, res) => {
  try {
    const { postId } = req.params;

    const { data, error } = await supabase
      .from('post_shares')
      .select(`
        *,
        shared_by:shared_by_user_id(full_name, username, avatar_url)
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
    console.error('Error getting shares:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;