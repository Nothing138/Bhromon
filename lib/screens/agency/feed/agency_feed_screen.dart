// screens/agency/feed/agency_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/feed_service_simple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AgencyFeedScreen extends StatefulWidget {
  const AgencyFeedScreen({super.key});

  @override
  State<AgencyFeedScreen> createState() => _AgencyFeedScreenFixedState();
}

class _AgencyFeedScreenFixedState extends State<AgencyFeedScreen> {
  late FeedServiceSimple feedService;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    feedService = FeedServiceSimple();

    // Debug: Check if data exists
    debugPrint(' Checking database...');
    feedService.checkDataExists();
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
      //  Use FutureBuilder instead of StreamBuilder
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: feedService.getCombinedFeed(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  strokeWidth: 3,
                ),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            debugPrint(' Feed Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    'Error loading feed',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, color: textSecondary, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    'No posts or events yet',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Check back soon!',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Success - Show feed
          final feedItems = snapshot.data!;
          debugPrint(' Rendering ${feedItems.length} feed items');

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
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
            ),
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
    // Safe getters with defaults
    final getStr = (dynamic v, String def) => (v ?? def).toString();
    final getNum = (dynamic v, num def) {
      try {
        return num.parse(v?.toString() ?? def.toString());
      } catch (_) {
        return def;
      }
    };

    final title = isEvent
        ? getStr(item['title'], 'Unknown Event')
        : getStr(item['user_full_name'], 'Unknown User');
    final content =
        isEvent ? getStr(item['description'], '') : getStr(item['content'], '');
    final imageUrl = item['image_url'];
    final contactNumber =
        getStr(item['owner_phone'] ?? item['contact_number'], '');
    final location = getStr(item['location'] ?? item['location_name'], '');
    final eventDate = isEvent ? getStr(item['event_date'], '') : '';
    final price = getNum(item['price'], 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEvent ? Icons.event_rounded : Icons.person_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contactNumber.isEmpty
                            ? (isEvent ? '📍 Event' : '✈️ Post')
                            : '📞 $contactNumber',
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

          // Image
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl.toString(),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ),

          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            const SizedBox(height: 12),

          // Content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                content,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (content.isNotEmpty) const SizedBox(height: 12),

          // Event details
          if (isEvent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: accentColor, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            eventDate,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (price > 0)
                          Text(
                            '৳${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: accentColor, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (isEvent) const SizedBox(height: 12),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Like',
                    onTap: () {},
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildButton(
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    onTap: () {
                      if (contactNumber.isNotEmpty) {
                        launchUrl(Uri(scheme: 'tel', path: contactNumber));
                      }
                    },
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildButton(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    onTap: () {},
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => Share.share('Check this out!'),
                    accentColor: accentColor,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 16),
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
