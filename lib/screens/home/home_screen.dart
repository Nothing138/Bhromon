// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
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
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // থিম প্রোভাইডার কল করা হয়েছে
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // ব্যাকগ্রাউন্ড থিম অনুযায়ী পরিবর্তন হবে
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Bhromon Feed",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: accentColor, // ডাইনামিক কালার
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.person_pin_rounded, size: 28),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    "No posts yet. Be the first to post!",
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final post = posts[index];
              final imageUrl = post['image_url'] as String?;
              final content = post['content'] as String? ?? "";
              final location = post['location_name'] as String? ?? "Unknown";
              final isLookingForGroup =
                  post['is_looking_for_group'] as bool? ?? false;
              final isAnonymous = post['is_anonymous'] as bool? ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isAnonymous
                            ? Colors.blueGrey[100]
                            : accentColor.withOpacity(0.1),
                        child: Icon(
                          isAnonymous ? Icons.visibility_off : Icons.person,
                          color: isAnonymous ? Colors.blueGrey : accentColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        isAnonymous ? "Anonymous Traveler" : "Traveler",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: isLookingForGroup
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Group Sync",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),

                    // Content Text
                    if (content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),

                    // Image Section
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            imageUrl,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 280,
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : null,
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            Icons.favorite_border,
                            "Like",
                            isDark,
                          ),
                          _buildActionButton(
                            Icons.chat_bubble_outline,
                            "Chat",
                            isDark,
                          ),
                          Icon(
                            Icons.share_outlined,
                            size: 20,
                            color: isDark ? Colors.grey[500] : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        label: const Text(
          "Post Adventure",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        backgroundColor: accentColor,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isDark) {
    final textColor = isDark ? Colors.grey[400] : Colors.grey[700];
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
