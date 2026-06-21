// screens/profile/profile_screen.dart
// screens/profile/profile_screen.dart (UPDATED)
// ✅ Updated with Past Shopping এবং My Places sections

// ⚠️ এই file টি পুরোটা replace করবেন আপনার profile_screen.dart দিয়ে

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/theme_provider.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'past_trips_screen.dart';
import 'past_shopping_screen.dart'; // ← নতুন
import 'my_places_screen.dart'; // ← নতুন
import 'privacy_security_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _profileData;
  List<dynamic> _pastTrips = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadAllData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final authMeta = user.userMetadata;
      final authName = authMeta?['full_name'] ??
          authMeta?['name'] ??
          user.email?.split('@').first ??
          'Traveler';

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic> merged = {};
      if (profile != null) {
        merged = Map<String, dynamic>.from(profile);
        if (merged['full_name'] == null ||
            merged['full_name'].toString().trim().isEmpty) {
          merged['full_name'] = authName;
        }
      } else {
        merged = {
          'id': user.id,
          'full_name': authName,
          'username': user.email?.split('@').first ?? '',
          'bio': '',
          'avatar_url': '',
        };
      }

      List<dynamic> trips = [];
      try {
        trips = await supabase
            .from('bookings')
            .select('*, places(*)')
            .eq('user_id', user.id)
            .order('booking_date', ascending: false);
      } catch (e) {
        debugPrint('Bookings fetch error: $e');
      }

      if (mounted) {
        setState(() {
          _profileData = merged;
          _pastTrips = trips;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      debugPrint('Data loading error: $e');
      final user = supabase.auth.currentUser;
      if (mounted) {
        final authMeta = user?.userMetadata;
        setState(() {
          _profileData = {
            'id': user?.id ?? '',
            'full_name': authMeta?['full_name'] ??
                authMeta?['name'] ??
                user?.email?.split('@').first ??
                'Traveler',
            'username': user?.email?.split('@').first ?? '',
            'bio': '',
            'avatar_url': '',
          };
          _isLoading = false;
        });
        _animController.forward();
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final user = supabase.auth.currentUser!;
      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$ext';

      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase
          .from('profiles')
          .update({'avatar_url': url}).eq('id', user.id);

      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 19,
                ),
              ),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2.5,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                color: accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileCard(
                        accentColor,
                        isDark,
                        textColor,
                        cardColor,
                      ),
                      const SizedBox(height: 24),
                      _buildStatsRow(accentColor, isDark, textColor, cardColor),
                      const SizedBox(height: 28),

                      // ✅ HISTORY SECTION (নতুন)
                      _buildSectionLabel('HISTORY', isDark),
                      const SizedBox(height: 10),
                      _buildMenuCard(
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                        items: [
                          _MenuItem(
                            icon: Icons.map_outlined,
                            label: 'Past Trips',
                            subtitle: '${_pastTrips.length} bookings',
                            color: const Color(0xFF06B6D4),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PastTripsScreen(trips: _pastTrips),
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Past Shopping',
                            subtitle: 'Purchase history',
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PastShoppingScreen(),
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.location_on_outlined,
                            label: 'My Places',
                            subtitle: 'Places you added',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyPlacesScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel('SETTINGS & PREFERENCES', isDark),
                      const SizedBox(height: 10),
                      _buildMenuCard(
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                        items: [
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit Profile',
                            subtitle: 'Name, bio & photo',
                            color: accentColor,
                            onTap: _navigateToEditProfile,
                          ),
                          _MenuItem(
                            icon: Icons.palette_outlined,
                            label: 'Appearance',
                            subtitle: 'Theme & dark mode',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppearanceScreen(),
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            subtitle: 'Alerts & messages',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.shield_outlined,
                            label: 'Privacy & Security',
                            subtitle: 'Password & account',
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacySecurityScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard(
    Color accentColor,
    bool isDark,
    Color textColor,
    Color cardColor,
  ) {
    final avatarUrl = _profileData?['avatar_url']?.toString() ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final displayName = _profileData?['full_name']?.toString() ?? 'Traveler';
    final bio = (_profileData?['bio']?.toString().isNotEmpty == true)
        ? _profileData!['bio'].toString()
        : 'Adventure is out there! 🌍';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.5), accentColor],
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: cardColor,
                  child: _isUploadingPhoto
                      ? CircularProgressIndicator(
                          color: accentColor,
                          strokeWidth: 2,
                        )
                      : CircleAvatar(
                          radius: 49,
                          backgroundImage:
                              hasAvatar ? NetworkImage(avatarUrl) : null,
                          backgroundColor: accentColor.withValues(alpha: 0.13),
                          child: !hasAvatar
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'T',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                )
                              : null,
                        ),
                ),
              ),
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[500],
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: Icon(Icons.edit_outlined, size: 15, color: accentColor),
            label: Text(
              'Edit Profile',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    Color accentColor,
    bool isDark,
    Color textColor,
    Color cardColor,
  ) {
    final confirmed =
        _pastTrips.where((t) => t['status'] == 'confirmed').length;
    final upcoming = _pastTrips.where((t) => t['status'] == 'upcoming').length;
    return Row(
      children: [
        _statCard(
          cardColor,
          isDark,
          textColor,
          '${_pastTrips.length}',
          'Trips',
          Icons.flight_takeoff_rounded,
          accentColor,
        ),
        const SizedBox(width: 12),
        _statCard(
          cardColor,
          isDark,
          textColor,
          '$confirmed',
          'Confirmed',
          Icons.check_circle_outline_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        _statCard(
          cardColor,
          isDark,
          textColor,
          '$upcoming',
          'Upcoming',
          Icons.upcoming_outlined,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _statCard(
    Color cardColor,
    bool isDark,
    Color textColor,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );

  Widget _buildMenuCard({
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                    size: 18,
                  ),
                ),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 70,
                  color: isDark ? Colors.white10 : Colors.grey[100],
                ),
            ],
          );
        }),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialData: _profileData),
      ),
    );
    if (result == true) _loadAllData();
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
