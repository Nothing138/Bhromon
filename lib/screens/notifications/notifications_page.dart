// screens/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New place added near you',
      'subtitle': 'Ratargul Swamp Forest is now on Bhromon.',
      'icon': Icons.add_location_alt_outlined,
      'time': '2m ago',
      'isNew': true,
      'colorHex': 0xFF3B6D11,
      'bgHex': 0xFF1A3A20,
    },
    {
      'title': 'Trip reminder',
      'subtitle': 'Your Sajek trip starts tomorrow. Stay ready!',
      'icon': Icons.luggage_outlined,
      'time': '1h ago',
      'isNew': true,
      'colorHex': 0xFFBA7517,
      'bgHex': 0xFF3A2A10,
    },
    {
      'title': 'Someone liked your post',
      'subtitle': 'A traveler reacted to your Cox\'s Bazar adventure.',
      'icon': Icons.favorite_border_rounded,
      'time': '3h ago',
      'isNew': false,
      'colorHex': 0xFFE24B4A,
      'bgHex': 0xFF3A1010,
    },
    {
      'title': 'New group looking for members',
      'subtitle': '3 travelers are planning a trip to Sundarbans.',
      'icon': Icons.group_outlined,
      'time': '5h ago',
      'isNew': false,
      'colorHex': 0xFF185FA5,
      'bgHex': 0xFF0F1E3A,
    },
    {
      'title': 'Flash deal on gear',
      'subtitle': 'Get 30% off on trekking boots today only.',
      'icon': Icons.local_offer_outlined,
      'time': '8h ago',
      'isNew': false,
      'colorHex': 0xFF534AB7,
      'bgHex': 0xFF1E1A3A,
    },
    {
      'title': 'AI itinerary ready',
      'subtitle': 'Your custom Bandarban plan has been generated.',
      'icon': Icons.auto_awesome_outlined,
      'time': '1d ago',
      'isNew': false,
      'colorHex': 0xFF0F6E56,
      'bgHex': 0xFF0A2820,
    },
    {
      'title': 'Weather alert',
      'subtitle': 'Heavy rain expected in Chittagong this weekend.',
      'icon': Icons.cloud_outlined,
      'time': '1d ago',
      'isNew': false,
      'colorHex': 0xFF4A5478,
      'bgHex': 0xFF141E34,
    },
    {
      'title': 'Comment on your post',
      'subtitle': 'Someone commented: "Amazing shot! Where exactly?"',
      'icon': Icons.chat_bubble_outline_rounded,
      'time': '2d ago',
      'isNew': false,
      'colorHex': 0xFF185FA5,
      'bgHex': 0xFF0A1A34,
    },
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['isNew'] = false;
      }
    });
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

    final newCount = _notifications.where((n) => n['isNew'] == true).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded, color: accentColor, size: 18),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          if (newCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$newCount new',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          // Today section
          if (_notifications.any((n) => n['isNew'] == true)) ...[
            _buildSectionLabel('New', textSecondary),
            const SizedBox(height: 8),
            ..._notifications
                .where((n) => n['isNew'] == true)
                .map(
                  (n) => _buildNotifItem(
                    n,
                    isDark,
                    surface,
                    surfaceBorder,
                    textPrimary,
                    textSecondary,
                  ),
                ),
            const SizedBox(height: 20),
          ],
          _buildSectionLabel('Earlier', textSecondary),
          const SizedBox(height: 8),
          ..._notifications
              .where((n) => n['isNew'] == false)
              .map(
                (n) => _buildNotifItem(
                  n,
                  isDark,
                  surface,
                  surfaceBorder,
                  textPrimary,
                  textSecondary,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color textSecondary) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNotifItem(
    Map<String, dynamic> notif,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isNew = notif['isNew'] as bool;
    final iconColor = Color(notif['colorHex'] as int);
    final iconBg = isDark
        ? Color(notif['bgHex'] as int)
        : iconColor.withOpacity(0.08);

    return GestureDetector(
      onTap: () {
        if (isNew) {
          setState(() => notif['isNew'] = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew ? iconColor.withOpacity(0.15) : surfaceBorder,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notif['icon'] as IconData,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] as String,
                            style: TextStyle(
                              fontWeight: isNew
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: isNew
                                  ? textPrimary
                                  : textPrimary.withOpacity(0.7),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif['time'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['subtitle'] as String,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
