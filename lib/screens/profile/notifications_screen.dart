// screens/profile/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification preferences
  bool _pushEnabled = true;
  bool _tripReminders = true;
  bool _bookingUpdates = true;
  bool _groupInvites = true;
  bool _sosAlerts = true;
  bool _newPlaces = false;
  bool _weeklyDigest = false;
  bool _marketingEmails = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // profiles টেবিল থেকে notification prefs লোড করো
      // যদি আলাদা কলাম না থাকে, তাহলে JSONB field ব্যবহার করো
      // এখানে default values রাখা আছে, তুমি Supabase অনুযায়ী adjust করো
      final data = await supabase
          .from('profiles')
          .select('notification_prefs')
          .eq('id', userId)
          .maybeSingle();

      if (data != null && data['notification_prefs'] != null) {
        final prefs = data['notification_prefs'] as Map<String, dynamic>;
        setState(() {
          _pushEnabled = prefs['push_enabled'] ?? true;
          _tripReminders = prefs['trip_reminders'] ?? true;
          _bookingUpdates = prefs['booking_updates'] ?? true;
          _groupInvites = prefs['group_invites'] ?? true;
          _sosAlerts = prefs['sos_alerts'] ?? true;
          _newPlaces = prefs['new_places'] ?? false;
          _weeklyDigest = prefs['weekly_digest'] ?? false;
          _marketingEmails = prefs['marketing_emails'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Load notif prefs error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({
            'notification_prefs': {
              'push_enabled': _pushEnabled,
              'trip_reminders': _tripReminders,
              'booking_updates': _bookingUpdates,
              'group_invites': _groupInvites,
              'sos_alerts': _sosAlerts,
              'new_places': _newPlaces,
              'weekly_digest': _weeklyDigest,
              'marketing_emails': _marketingEmails,
            },
          })
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification preferences saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    const amberColor = Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Master Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          amberColor.withOpacity(0.15),
                          amberColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: amberColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: amberColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: amberColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Push Notifications',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Enable all push notifications',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pushEnabled,
                          onChanged: (v) => setState(() => _pushEnabled = v),
                          activeColor: amberColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Activity ──
                  _sectionLabel('ACTIVITY', isDark),
                  const SizedBox(height: 10),
                  _buildNotifCard(
                    cardColor: cardColor,
                    isDark: isDark,
                    textColor: textColor,
                    items: [
                      _NotifItem(
                        icon: Icons.flight_takeoff_rounded,
                        title: 'Trip Reminders',
                        subtitle: 'Get reminded before your trips',
                        color: accentColor,
                        value: _tripReminders && _pushEnabled,
                        enabled: _pushEnabled,
                        onChanged: (v) => setState(() => _tripReminders = v),
                      ),
                      _NotifItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Booking Updates',
                        subtitle: 'Confirmation & status changes',
                        color: const Color(0xFF06B6D4),
                        value: _bookingUpdates && _pushEnabled,
                        enabled: _pushEnabled,
                        onChanged: (v) => setState(() => _bookingUpdates = v),
                      ),
                      _NotifItem(
                        icon: Icons.group_outlined,
                        title: 'Group Invites',
                        subtitle: 'When someone adds you to a group',
                        color: const Color(0xFF8B5CF6),
                        value: _groupInvites && _pushEnabled,
                        enabled: _pushEnabled,
                        onChanged: (v) => setState(() => _groupInvites = v),
                      ),
                    ],
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 24),

                  // ── Safety ──
                  _sectionLabel('SAFETY', isDark),
                  const SizedBox(height: 10),
                  _buildNotifCard(
                    cardColor: cardColor,
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                    items: [
                      _NotifItem(
                        icon: Icons.emergency_share_outlined,
                        title: 'SOS Alerts',
                        subtitle: 'Emergency alerts from your travel group',
                        color: Colors.redAccent,
                        value: _sosAlerts && _pushEnabled,
                        enabled: _pushEnabled,
                        onChanged: (v) => setState(() => _sosAlerts = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Discover ──
                  _sectionLabel('DISCOVER & UPDATES', isDark),
                  const SizedBox(height: 10),
                  _buildNotifCard(
                    cardColor: cardColor,
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                    items: [
                      _NotifItem(
                        icon: Icons.place_outlined,
                        title: 'New Places',
                        subtitle: 'Discover new destinations nearby',
                        color: const Color(0xFF10B981),
                        value: _newPlaces && _pushEnabled,
                        enabled: _pushEnabled,
                        onChanged: (v) => setState(() => _newPlaces = v),
                      ),
                      _NotifItem(
                        icon: Icons.email_outlined,
                        title: 'Weekly Digest',
                        subtitle: 'Your weekly travel summary',
                        color: const Color(0xFFF59E0B),
                        value: _weeklyDigest,
                        enabled: true,
                        onChanged: (v) => setState(() => _weeklyDigest = v),
                      ),
                      _NotifItem(
                        icon: Icons.campaign_outlined,
                        title: 'Promotions & Offers',
                        subtitle: 'Special deals and announcements',
                        color: Colors.grey,
                        value: _marketingEmails,
                        enabled: true,
                        onChanged: (v) => setState(() => _marketingEmails = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _savePreferences,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Text(
    label,
    style: TextStyle(
      color: isDark ? Colors.white38 : Colors.grey[400],
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  );

  Widget _buildNotifCard({
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required List<_NotifItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.04),
            blurRadius: 14,
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
                    color: item.enabled
                        ? item.color.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.enabled ? item.color : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    color: item.enabled
                        ? textColor
                        : (isDark ? Colors.white38 : Colors.grey[400]),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: Switch(
                  value: item.value,
                  onChanged: item.enabled ? item.onChanged : null,
                  activeColor: item.color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
}

class _NotifItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotifItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
}
