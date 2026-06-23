// screens/agency/feed/agency_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/feed_service.dart';
import '../../../services/likes_service.dart';
import '../../chat/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AgencyFeedScreen extends StatefulWidget {
  const AgencyFeedScreen({super.key});

  @override
  State<AgencyFeedScreen> createState() => _AgencyFeedScreenState();
}

class _AgencyFeedScreenState extends State<AgencyFeedScreen> {
  final feedService = FeedService();
  final likesService = LikesService();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    feedService.debugFeedData();
  }

  Future<void> _initiateCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _initiateChat(
      String userId, String userName, String userType) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to message')),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: userId,
            otherUserName: userName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  Future<void> _sharePost(Map<String, dynamic> item) async {
    final type = item['type'] ?? 'post';
    final title = item['title'] ?? item['content'] ?? 'Check this out';

    final shareText = type == 'event'
        ? '📍 $title\n\nCheck out this amazing event on Bhromon!'
        : '✈️ $title\n\nSharing this awesome travel post!';

    try {
      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Agency Feed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: surfaceBorder,
            height: 0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: feedService.getCombinedFeed(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  strokeWidth: 2.5,
                ),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load feed',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feed_outlined,
                    color: textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts or events yet',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final feedItems = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: feedItems.length,
            itemBuilder: (context, index) {
              final item = feedItems[index];
              final isEvent = item['type'] == 'event';

              return _buildFeedItem(
                item: item,
                isEvent: isEvent,
                accentColor: accentColor,
                isDark: isDark,
                surface: surface,
                surfaceBorder: surfaceBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedItem({
    required Map<String, dynamic> item,
    required bool isEvent,
    required Color accentColor,
    required bool isDark,
    required Color surface,
    required Color surfaceBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    final title = item['title'] ?? item['user_name'] ?? 'Unknown';
    final content = item['content'] ?? item['description'] ?? '';
    const maxLines = 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon/Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEvent ? Icons.event_rounded : Icons.location_on_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEvent ? '📍 Event' : '✈️ Post',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── CONTENT ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              content,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // ── EVENT DETAILS (if event) ──
          if (isEvent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['event_date']?.toString() ?? 'No date',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item['price'] != null)
                      Text(
                        '₹${item['price']}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (isEvent) const SizedBox(height: 12),

          // ── ACTION BUTTONS ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Like Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Like',
                    onTap: () async {
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login to like')),
                        );
                        return;
                      }
                      await likesService.toggleLike(
                        postId: item['id'] ?? '',
                        userId: userId,
                      );
                      setState(() {});
                    },
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),

                // Call Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    onTap: () {
                      // Get agency phone from item
                      final agencyPhone =
                          item['owner_phone'] ?? item['office_phone'] ?? '';
                      if (agencyPhone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number not available')),
                        );
                        return;
                      }
                      _initiateCall(agencyPhone);
                    },
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),

                // Message Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    onTap: () {
                      final userId = item['user_id'] ?? '';
                      final agencyName =
                          item['agency_name'] ?? item['user_name'] ?? 'Agency';
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unable to message this item')),
                        );
                        return;
                      }
                      _initiateChat(userId, agencyName, 'agency');
                    },
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),

                // Share Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => _sharePost(item),
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
    required Color textSecondary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: textSecondary.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
