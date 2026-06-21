// screens/home/home_screen.dart
// ✅ COMPLETELY FIXED: Service init + User profile + All buttons
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/likes_service.dart';
import '../auth/login_screen.dart';
import 'create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  late final LikesService _likesService; // ✅ Fixed: Use late final
  late String _currentUserId;

  final Stream<List<Map<String, dynamic>>> _postStream = Supabase
      .instance.client
      .from('posts')
      .stream(primaryKey: ['id']).order('created_at', ascending: false);

  @override
  void initState() {
    super.initState();
    _likesService = LikesService(); // ✅ Initialize in initState
    _currentUserId = supabase.auth.currentUser?.id ?? '';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to log out of Bhromon?',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
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
        elevation: 0,
        backgroundColor: bg,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceBorder, width: 0.5),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Icon(Icons.travel_explore_outlined, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bhromon Feed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _handleLogout(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Something went wrong',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.photo_camera_back_outlined,
                      size: 32,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Be the first to share your adventure!',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, index) => _buildPostCard(
              posts[index],
              accentColor,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Post adventure',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final imageUrl = post['image_url'] as String?;
    final content = post['content'] as String? ?? '';
    final location = post['location_name'] as String? ?? 'Unknown location';
    final isLookingForGroup = post['is_looking_for_group'] as bool? ?? false;
    final isAnonymous = post['is_anonymous'] as bool? ?? false;
    final userName = (post['user_full_name'] as String?) ?? 'Traveler';
    final contactNumber = (post['contact_number'] as String?) ?? '';
    final posterId = (post['user_id'] as String?) ?? '';
    final postId = (post['id'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ HEADER SECTION WITH CLICKABLE PROFILE ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: GestureDetector(
              onTap: () => _showUserProfile(
                context,
                userName,
                contactNumber,
                isAnonymous,
                posterId,
                accentColor,
                isDark,
                surface,
                surfaceBorder,
                textPrimary,
                textSecondary,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isAnonymous
                          ? const Color(0xFF1E2A42)
                          : accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isAnonymous
                            ? const Color(0xFF2E3A56)
                            : accentColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      isAnonymous
                          ? Icons.visibility_off_outlined
                          : Icons.person_outline_rounded,
                      color:
                          isAnonymous ? const Color(0xFF4A5478) : accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ CLICKABLE USER NAME
                        Text(
                          isAnonymous ? 'Anonymous traveler' : userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isLookingForGroup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Text(
                        'Group sync',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ═══ CONTENT SECTION ═══
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFB0B8D0)
                      : const Color(0xFF334155),
                ),
              ),
            ),

          // ═══ IMAGE SECTION ═══
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 240,
                    color: isDark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF0F2F8),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: isDark
                      ? const Color(0xFF111827)
                      : const Color(0xFFF0F2F8),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: textSecondary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // ═══ ACTIONS SECTION WITH ALL BUTTONS ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // ✅ LIKE BUTTON
                    Expanded(
                      child: _buildLikeButton(
                        postId: postId,
                        accentColor: accentColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ✅ MESSAGE BUTTON
                    if (!isAnonymous &&
                        contactNumber.isNotEmpty &&
                        posterId != _currentUserId)
                      Expanded(
                        child: _buildMessageButton(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: posterId,
                                otherUserName: userName,
                                otherUserPhone: contactNumber,
                              ),
                            ),
                          ),
                          accentColor: accentColor,
                          isDark: isDark,
                        ),
                      ),

                    // ✅ CONTACT BUTTON
                    if (!isAnonymous &&
                        contactNumber.isNotEmpty &&
                        posterId != _currentUserId)
                      Expanded(
                        child: _buildContactButton(
                          phone: contactNumber,
                          accentColor: accentColor,
                          isDark: isDark,
                        ),
                      ),

                    // ✅ SHARE BUTTON
                    Expanded(
                      child: _buildShareButton(
                        accentColor: accentColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ LIKE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLikeButton({
    required String postId,
    required Color accentColor,
    required bool isDark,
  }) {
    return StreamBuilder<bool>(
      stream: _likesService.streamUserLikeStatus(
        postId: postId,
        userId: _currentUserId,
      ),
      builder: (context, likeSnapshot) {
        final isLiked = likeSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: _likesService.streamLikesCount(postId),
          builder: (context, countSnapshot) {
            final likesCount = countSnapshot.data ?? 0;

            return InkWell(
              onTap: () async {
                try {
                  await _likesService.toggleLike(
                    postId: postId,
                    userId: _currentUserId,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLiked
                      ? Colors.red.withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isLiked
                        ? Colors.red.withValues(alpha: 0.3)
                        : accentColor.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: isLiked ? Colors.red : accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        color: isLiked ? Colors.red : accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ MESSAGE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMessageButton({
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 3),
            Text(
              'Message',
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ CONTACT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildContactButton({
    required String phone,
    required Color accentColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone: $phone'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_rounded,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 3),
            Text(
              'Call',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ SHARE BUTTON (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShareButton({
    required Color accentColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share functionality coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 3),
            Text(
              'Share',
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ USER PROFILE SHEET (NEW FEATURE)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showUserProfile(
    BuildContext context,
    String userName,
    String contactNumber,
    bool isAnonymous,
    String posterId,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user posted anonymously'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              userName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Travel Enthusiast',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Contact Info
            if (contactNumber.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2340)
                      : const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: surfaceBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contactNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: accentColor),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied: $contactNumber'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Message Button
            if (posterId != _currentUserId)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: posterId,
                        otherUserName: userName,
                        otherUserPhone: contactNumber,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Send Message',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
