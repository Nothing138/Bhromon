// screens/agency/agency_main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/event_service.dart';
import 'feed/agency_feed_screen.dart';
import 'messages/agency_messages_screen.dart';
import 'events/agency_events_screen.dart';
import 'profile/agency_profile_screen.dart';

class AgencyMainWrapper extends StatefulWidget {
  const AgencyMainWrapper({super.key});

  @override
  State<AgencyMainWrapper> createState() => _AgencyMainWrapperState();
}

class _AgencyMainWrapperState extends State<AgencyMainWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load events on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventService>(context, listen: false).fetchAllEvents();
    });
  }

  final List<Widget> _pages = [
    const AgencyFeedScreenPremium(), // 0 - Feed
    const AgencyMessagesScreen(), // 1 - Messages
    const AgencyEventsScreen(), // 2 - Events
    const AgencyProfileScreen(), // 3 - Profile
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_filled,
                  label: 'Feed',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.message_outlined,
                  activeIcon: Icons.message_rounded,
                  label: 'Messages',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event_rounded,
                  label: 'Events',
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
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
              ? accentColor.withValues(alpha: 0.12)
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
}
