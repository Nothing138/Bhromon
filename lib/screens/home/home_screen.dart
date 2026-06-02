// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'create_post_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  final Stream<List<Map<String, dynamic>>> _postStream = Supabase
      .instance
      .client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

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
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F4)
        : const Color(0xFF0D1117);
    final textSecondary = isDark
        ? const Color(0xFF4A5478)
        : const Color(0xFF8892A4);

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
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.12),
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
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accentColor.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.photo_camera_back_outlined,
                      size: 32,
                      color: accentColor.withOpacity(0.6),
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
          border: Border.all(color: accentColor.withOpacity(0.3), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isAnonymous
                        ? const Color(0xFF1E2A42)
                        : accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isAnonymous
                          ? const Color(0xFF2E3A56)
                          : accentColor.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    isAnonymous
                        ? Icons.visibility_off_outlined
                        : Icons.person_outline_rounded,
                    color: isAnonymous ? const Color(0xFF4A5478) : accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAnonymous ? 'Anonymous traveler' : 'Traveler',
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
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
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

          // Content
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

          // Image
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

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                _buildActionButton(
                  Icons.favorite_border_rounded,
                  'Like',
                  accentColor,
                  isDark,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  Icons.chat_bubble_outline_rounded,
                  'Comment',
                  accentColor,
                  isDark,
                ),
                const Spacer(),
                Icon(Icons.ios_share_outlined, size: 18, color: textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color accentColor,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: accentColor.withOpacity(0.12), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
