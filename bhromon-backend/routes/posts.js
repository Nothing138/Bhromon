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

// ========================
// ENDPOINT: CREATE POST (with all fields)
// ========================
router.post('/create', async (req, res) => {
  try {
    const {
      userId,
      agencyId,
      content,
      imageUrl,
      location,
      contactNumber,
      isLookingForGroup = false,
      isAnonymous = false,
      postType = 'text',
    } = req.body;

    if (!userId || !content) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId and content',
      });
    }

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required',
      });
    }

    console.log(`🔄 Creating post for user: ${userId}`);

    // Get user profile
    const { data: userProfile } = await supabaseAdmin
      .from('profiles')
      .select('full_name, username, avatar_url')
      .eq('id', userId)
      .single();

    // Create post with all fields
    const { data: newPost, error: postError } = await supabaseAdmin
      .from('posts')
      .insert({
        user_id: userId,
        agency_id: agencyId || null,
        content,
        image_url: imageUrl || null,
        location_name: location || null,
        contact_number: contactNumber,
        is_looking_for_group: isLookingForGroup,
        is_anonymous: isAnonymous,
        post_type: postType,
        user_full_name: isAnonymous ? null : userProfile?.full_name,
        user_name: isAnonymous ? null : userProfile?.username,
        user_avatar: isAnonymous ? null : userProfile?.avatar_url,
        likes_count: 0,
        comments_count: 0,
      })
      .select()
      .single();

    if (postError) {
      console.error(`❌ Post creation error: ${postError.message}`);
      return res.status(500).json({
        success: false,
        message: `Post error: ${postError.message}`,
      });
    }

    console.log(`✅ Post created: ${newPost.id}`);

    return res.status(200).json({
      success: true,
      message: 'Post created successfully!',
      post: newPost,
    });
  } catch (error) {
    console.error(`❌ Create post error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: GET ALL POSTS (with user details)
// ========================
router.get('/all', async (req, res) => {
  try {
    console.log('🔄 Fetching all posts...');

    const { data: posts, error: postsError } = await supabaseAdmin
      .from('posts')
      .select(
        `
        *,
        user:user_id(id, username, full_name, avatar_url),
        likes:post_likes(count),
        comments:post_comments(count)
      `
      )
      .order('created_at', { ascending: false })
      .limit(100);

    if (postsError) {
      console.error(`❌ Fetch error: ${postsError.message}`);
      return res.status(500).json({
        success: false,
        message: `Fetch error: ${postsError.message}`,
      });
    }

    console.log(`✅ Fetched ${posts.length} posts`);

    return res.status(200).json({
      success: true,
      posts,
      count: posts.length,
    });
  } catch (error) {
    console.error(`❌ Get posts error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: TOGGLE LIKE (Like/Unlike)
// ========================
router.post('/toggle-like', async (req, res) => {
  try {
    const { postId, userId } = req.body;

    if (!postId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Missing postId or userId',
      });
    }

    console.log(`🔄 Toggling like for post: ${postId}`);

    // Check if already liked
    const { data: existingLike } = await supabaseAdmin
      .from('post_likes')
      .select()
      .eq('post_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

    let isLiked = false;

    if (existingLike) {
      // Unlike
      await supabaseAdmin
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);

      console.log(`❤️ Post unliked: ${postId}`);
      isLiked = false;
    } else {
      // Like
      await supabaseAdmin.from('post_likes').insert({
        post_id: postId,
        user_id: userId,
        created_at: new Date().toISOString(),
      });

      console.log(`❤️ Post liked: ${postId}`);
      isLiked = true;
    }

    // Get updated like count
    const { data: likesData } = await supabaseAdmin
      .from('post_likes')
      .select('id', { count: 'exact' })
      .eq('post_id', postId);

    const likesCount = likesData?.length || 0;

    // Update post likes count
    await supabaseAdmin
      .from('posts')
      .update({ likes_count: likesCount })
      .eq('id', postId);

    return res.status(200).json({
      success: true,
      message: isLiked ? 'Post liked' : 'Post unliked',
      isLiked,
      likesCount,
    });
  } catch (error) {
    console.error(`❌ Toggle like error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: ADD COMMENT
// ========================
router.post('/add-comment', async (req, res) => {
  try {
    const { postId, userId, content } = req.body;

    if (!postId || !userId || !content) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    console.log(`🔄 Adding comment to post: ${postId}`);

    // Get user profile
    const { data: userProfile } = await supabaseAdmin
      .from('profiles')
      .select('full_name, username')
      .eq('id', userId)
      .single();

    // Create comment
    const { data: newComment, error: commentError } = await supabaseAdmin
      .from('post_comments')
      .insert({
        post_id: postId,
        user_id: userId,
        content,
        user_full_name: userProfile?.full_name,
        user_name: userProfile?.username,
      })
      .select()
      .single();

    if (commentError) {
      console.error(`❌ Comment creation error: ${commentError.message}`);
      return res.status(500).json({
        success: false,
        message: `Comment error: ${commentError.message}`,
      });
    }

    // Get updated comment count
    const { data: commentsData } = await supabaseAdmin
      .from('post_comments')
      .select('id', { count: 'exact' })
      .eq('post_id', postId);

    const commentsCount = commentsData?.length || 0;

    // Update post comments count
    await supabaseAdmin
      .from('posts')
      .update({ comments_count: commentsCount })
      .eq('id', postId);

    console.log(`✅ Comment added: ${newComment.id}`);

    return res.status(200).json({
      success: true,
      message: 'Comment added successfully!',
      comment: newComment,
      commentsCount,
    });
  } catch (error) {
    console.error(`❌ Add comment error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: GET COMMENTS
// ========================
router.get('/:postId/comments', async (req, res) => {
  try {
    const { postId } = req.params;

    console.log(`🔄 Fetching comments for post: ${postId}`);

    const { data: comments, error: commentsError } = await supabaseAdmin
      .from('post_comments')
      .select('*')
      .eq('post_id', postId)
      .order('created_at', { ascending: false });

    if (commentsError) {
      console.error(`❌ Fetch comments error: ${commentsError.message}`);
      return res.status(500).json({
        success: false,
        message: `Fetch error: ${commentsError.message}`,
      });
    }

    console.log(`✅ Fetched ${comments.length} comments`);

    return res.status(200).json({
      success: true,
      comments,
      count: comments.length,
    });
  } catch (error) {
    console.error(`❌ Get comments error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: SHARE POST (Send to contacts)
// ========================
router.post('/share', async (req, res) => {
  try {
    const { postId, userId, shareToUserIds = [] } = req.body;

    if (!postId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    console.log(`🔄 Sharing post: ${postId}`);

    // Get post details
    const { data: post } = await supabaseAdmin
      .from('posts')
      .select('*')
      .eq('id', postId)
      .single();

    // Create share record
    const { error: shareError } = await supabaseAdmin
      .from('post_shares')
      .insert({
        post_id: postId,
        shared_by_user_id: userId,
        shared_to_user_ids: shareToUserIds,
        created_at: new Date().toISOString(),
      });

    if (shareError) {
      console.error(`❌ Share error: ${shareError.message}`);
      return res.status(500).json({
        success: false,
        message: `Share error: ${shareError.message}`,
      });
    }

    console.log(`✅ Post shared successfully`);

    return res.status(200).json({
      success: true,
      message: 'Post shared successfully!',
      postId,
      sharedWith: shareToUserIds.length,
    });
  } catch (error) {
    console.error(`❌ Share post error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: CALL REQUEST (Send call invitation)
// ========================
router.post('/call-request', async (req, res) => {
  try {
    const { postId, fromUserId, toAgencyId, phoneNumber } = req.body;

    if (!postId || !fromUserId || !toAgencyId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    console.log(`📞 Call request for post: ${postId}`);

    // Get caller info
    const { data: callerProfile } = await supabaseAdmin
      .from('profiles')
      .select('full_name, username')
      .eq('id', fromUserId)
      .single();

    // Get agency info
    const { data: agencyData } = await supabaseAdmin
      .from('travel_agencies')
      .select('owner_email, owner_phone, agency_name')
      .eq('id', toAgencyId)
      .single();

    // Create call log
    const { data: callLog, error: callError } = await supabaseAdmin
      .from('call_logs')
      .insert({
        post_id: postId,
        from_user_id: fromUserId,
        to_agency_id: toAgencyId,
        status: 'initiated',
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (callError) {
      console.error(`❌ Call log error: ${callError.message}`);
      return res.status(500).json({
        success: false,
        message: `Call error: ${callError.message}`,
      });
    }

    // Send email notification to agency
    if (agencyData?.owner_email) {
      try {
        await transporter.sendMail({
          from: `"Bhromon" <${process.env.GMAIL_USER}>`,
          to: agencyData.owner_email,
          subject: `📞 Call Request from ${callerProfile?.full_name}`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2>${callerProfile?.full_name} is interested in your event!</h2>
              <p>They want to call you about one of your posts.</p>
              <p><strong>Caller:</strong> ${callerProfile?.full_name}</p>
              <p><strong>Your Agency:</strong> ${agencyData?.agency_name}</p>
              <p style="color: #666; margin-top: 20px;">Please respond to their inquiry.</p>
            </div>
          `,
        });
        console.log(`✅ Email sent to agency: ${agencyData.owner_email}`);
      } catch (emailError) {
        console.warn(`⚠️ Email send failed (non-critical): ${emailError.message}`);
      }
    }

    console.log(`✅ Call request created: ${callLog.id}`);

    return res.status(200).json({
      success: true,
      message: 'Call request sent successfully!',
      callLogId: callLog.id,
      agencyEmail: agencyData?.owner_email,
    });
  } catch (error) {
    console.error(`❌ Call request error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

// ========================
// ENDPOINT: DELETE POST
// ========================
router.delete('/:postId', async (req, res) => {
  try {
    const { postId } = req.params;
    const { userId } = req.body;

    if (!postId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    console.log(`🔄 Deleting post: ${postId}`);

    // Verify ownership
    const { data: post } = await supabaseAdmin
      .from('posts')
      .select('user_id')
      .eq('id', postId)
      .single();

    if (post.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized: You can only delete your own posts',
      });
    }

    // Delete likes
    await supabaseAdmin.from('post_likes').delete().eq('post_id', postId);

    // Delete comments
    await supabaseAdmin
      .from('post_comments')
      .delete()
      .eq('post_id', postId);

    // Delete shares
    await supabaseAdmin.from('post_shares').delete().eq('post_id', postId);

    // Delete post
    await supabaseAdmin.from('posts').delete().eq('id', postId);

    console.log(`✅ Post deleted: ${postId}`);

    return res.status(200).json({
      success: true,
      message: 'Post deleted successfully!',
    });
  } catch (error) {
    console.error(`❌ Delete post error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: `Unexpected error: ${error.message}`,
    });
  }
});

export default router;