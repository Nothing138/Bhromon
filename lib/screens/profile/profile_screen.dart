// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../../providers/theme_provider.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'past_trips_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<dynamic> _pastTrips = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // প্রোফাইল ডাটা ফেচিং
        final profile = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        // বুকিং হিস্ট্রি ফেচিং
        final trips = await supabase
            .from('bookings')
            .select('*, places(*)')
            .eq('user_id', user.id)
            .order('booking_date', ascending: false);

        if (mounted) {
          setState(() {
            _profileData = profile;
            _pastTrips = trips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Data loading error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // ডাইনামিক ব্যাকগ্রাউন্ড
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(accentColor, isDark, textColor),
                    const SizedBox(height: 35),

                    _buildSectionTitle("History", isDark),
                    _buildSettingsTile(
                      Icons.history_rounded,
                      "Past Trips",
                      "${_pastTrips.length} bookings total",
                      accentColor,
                      isDark,
                      textColor,
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("Settings & Preference", isDark),
                    _buildSettingsList(accentColor, isDark, textColor),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Color accentColor, bool isDark, Color textColor) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundImage: NetworkImage(
                  _profileData?['avatar_url'] ??
                      'https://ui-avatars.com/api/?name=${_profileData?['full_name'] ?? 'User'}&background=random',
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: GestureDetector(
                onTap: _navigateToEditProfile,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _profileData?['full_name'] ?? 'Traveler Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _profileData?['bio'] ?? 'Adventure is out there! 🌍',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(Color accentColor, bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.person_outline,
            "Edit Profile",
            "Update your details",
            accentColor,
            isDark,
            textColor,
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
          _buildSettingsTile(
            Icons.palette_outlined,
            "Appearance",
            "Theme, Dark Mode",
            accentColor,
            isDark,
            textColor,
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
          _buildSettingsTile(
            Icons.notifications_none,
            "Notifications",
            "Alerts & Messages",
            accentColor,
            isDark,
            textColor,
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
          _buildSettingsTile(
            Icons.security,
            "Privacy & Safety",
            "Password, Security",
            accentColor,
            isDark,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    Color accentColor,
    bool isDark,
    Color textColor,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accentColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white24 : Colors.grey[400],
      ),
      onTap: () {
        if (title == "Edit Profile") {
          _navigateToEditProfile();
        } else if (title == "Appearance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppearanceScreen()),
          );
        } else if (title == "Past Trips") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PastTripsScreen(trips: _pastTrips),
            ),
          );
        }
      },
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(initialData: _profileData),
      ),
    );
    if (result == true) _loadAllData();
  }
}
