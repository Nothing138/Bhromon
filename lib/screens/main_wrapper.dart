// screens/main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'home/home_premium.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'map/map_page.dart';
import 'sos/sos_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePremium(), // 0 - Explore
    const HomeScreen(), // 1 - Feed
    const BDMapPage(), // 2 - Map
    const SOSPage(), // 3 - SOS
    const ProfileScreen(), // 4 - Profile
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Explore',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.rss_feed_outlined,
                  activeIcon: Icons.rss_feed_rounded,
                  label: 'Feed',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'Map',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                // SOS — special red pill button
                _buildSOSItem(isDark),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color accentColor,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white38 : Colors.grey[400]),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white38 : Colors.grey[400]),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSItem(bool isDark) {
    final isSelected = _selectedIndex == 3;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 3),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.redAccent
                    : Colors.redAccent.withOpacity(0.85),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(
                      isSelected ? 0.55 : 0.3,
                    ),
                    blurRadius: isSelected ? 14 : 8,
                    spreadRadius: isSelected ? 1 : 0,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'SOS',
              style: TextStyle(
                color: isSelected
                    ? Colors.redAccent
                    : Colors.redAccent.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
