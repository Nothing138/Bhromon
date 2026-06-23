// screens/agency/feed/agency_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/event_service.dart';
import '../../../services/post_service.dart' hide FeedItem;
import '../../../models/event_model.dart';
import '../../../models/post_model.dart';
import 'create_post_screen.dart';
import 'package:intl/intl.dart';

class AgencyFeedScreenPremium extends StatefulWidget {
  const AgencyFeedScreenPremium({super.key});

  @override
  State<AgencyFeedScreenPremium> createState() =>
      _AgencyFeedScreenPremiumState();
}

class _AgencyFeedScreenPremiumState extends State<AgencyFeedScreenPremium> {
  List<FeedItem> _feedItems = [];
  bool _isLoading = false;
  int _selectedLikeIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);

    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final postService = Provider.of<PostService>(context, listen: false);

      // Load events
      await eventService.fetchAllEvents();

      // Load posts
      //await postService.fetchAllPosts();

      // Combine and sort by date
      //_feedItems =
      //    _combineFeedItems(eventService.allEvents, postService.allPosts);

      setState(() {});
    } catch (e) {
      print('❌ Error loading feed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<FeedItem> _combineFeedItems(
    List<AgencyEvent> events,
    List<Post> posts,
  ) {
    final items = <FeedItem>[];

    // Add events
    for (var event in events) {
      items.add(FeedItem(
        id: event.id,
        type: 'event',
        data: event,
      ));
    }

    // Add posts
    for (var post in posts) {
      items.add(FeedItem(
        id: post.id,
        type: 'post',
        data: post,
      ));
    }

    // Sort by timestamp (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Feed',
          style: TextStyle(
            color: themeProvider.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFeed,
              color: themeProvider.accentColor,
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                itemCount: _feedItems.length + 1,
                itemBuilder: (context, index) {
                  // First item: Create post card
                  if (index == 0) {
                    return _buildCreatePostCard(themeProvider, isDark, context);
                  }

                  final feedItem = _feedItems[index - 1];

                  if (feedItem.type == 'event') {
                    return _buildEventCard(
                      feedItem.data as AgencyEvent,
                      themeProvider,
                      isDark,
                      context,
                    );
                  } else {
                    return _buildPostCard(
                      feedItem.data as Post,
                      themeProvider,
                      isDark,
                      context,
                    );
                  }
                },
              ),
            ),
    );
  }

  // ================== CREATE POST CARD ==================
  Widget _buildCreatePostCard(
    ThemeProvider themeProvider,
    bool isDark,
    BuildContext context,
  ) {
    final authService = Provider.of<AuthService>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        ),
        child: Row(
          children: [
            // Agency avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.location_city,
                color: themeProvider.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Share an event or update, ${authService.currentAgency?.agencyName?.split(' ').first ?? 'Agency'}...',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== EVENT CARD (Facebook Style) ==================
  Widget _buildEventCard(
    AgencyEvent event,
    ThemeProvider themeProvider,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header with agency profile
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: themeProvider.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.agencyName ?? 'Travel Agency',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(event.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white54 : Colors.grey[600]),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ✅ Event image
          if (event.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200]),
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.expand(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),

          // ✅ Event details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                if (event.description != null)
                  Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 10),

                // Event details row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: themeProvider.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatEventDate(event.eventDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: themeProvider.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location ?? 'Location TBA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),

                // Price
                if (event.price > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '💰 TK ${event.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ✅ Action buttons (Like, Comment, Call, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildFacebookButton(
                  icon: Icons.favorite_outline,
                  label: 'Like',
                  onTap: () => _toggleLike(event.id),
                  color: themeProvider.accentColor,
                ),
                _buildFacebookButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
                _buildFacebookButton(
                  icon: Icons.call,
                  label: 'Call',
                  onTap: () {},
                  color: Colors.green[600]!,
                ),
                _buildFacebookButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== POST CARD (Facebook Style) ==================
  Widget _buildPostCard(
    Post post,
    ThemeProvider themeProvider,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header with user profile
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // User avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    image: post.userAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(post.userAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: post.userAvatar == null
                      ? Icon(
                          Icons.person,
                          color: themeProvider.accentColor,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userFullName ?? post.userName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(post.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white54 : Colors.grey[600]),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ✅ Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              post.content,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          // Location if available
          if (post.location != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: themeProvider.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    post.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Post image
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                ),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.expand(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Like and comment count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite,
                        size: 14, color: Colors.red.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount} likes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${post.commentsCount} comments',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Divider(height: 1),
          ),

          // ✅ Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildFacebookButton(
                  icon: post.isLikedByCurrentUser
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  label: 'Like',
                  onTap: () => _toggleLike(post.id),
                  color: post.isLikedByCurrentUser
                      ? Colors.red
                      : themeProvider.accentColor,
                ),
                _buildFacebookButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
                _buildFacebookButton(
                  icon: Icons.call,
                  label: 'Call',
                  onTap: () {},
                  color: Colors.green[600]!,
                ),
                _buildFacebookButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== Facebook Button ==================
  Widget _buildFacebookButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== Helper Functions ==================
  void _toggleLike(String itemId) {
    // Will call backend API
    print('❤️ Toggled like for: $itemId');
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  String _formatEventDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
