// agency/feed/agency_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/event_service.dart';
import '../../../models/event_model.dart';
import 'create_post_screen.dart';

class AgencyFeedScreen extends StatefulWidget {
  const AgencyFeedScreen({super.key});

  @override
  State<AgencyFeedScreen> createState() => _AgencyFeedScreenState();
}

class _AgencyFeedScreenState extends State<AgencyFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Load events when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventService>(context, listen: false).fetchAllEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final eventService = Provider.of<EventService>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Feed',
          style: TextStyle(
            color: themeProvider.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: eventService.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: eventService.allEvents.length + 1,
              itemBuilder: (context, index) {
                // First item: Create post card
                if (index == 0) {
                  return _buildCreatePostCard(themeProvider, isDark, context);
                }

                final event = eventService.allEvents[index - 1];
                return _buildEventCard(event, themeProvider, isDark, context);
              },
            ),
    );
  }

  Widget _buildCreatePostCard(
      ThemeProvider themeProvider, bool isDark, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.location_city,
                color: themeProvider.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Share an event or update...',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    AgencyEvent event,
    ThemeProvider themeProvider,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with agency info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: themeProvider.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.agencyName ?? 'Travel Agency',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(event.createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Event image
          if (event.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
              ),
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.expand(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),

          // Event details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (event.description != null)
                  Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),
                // Event info row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: themeProvider.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatEventDate(event.eventDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (event.location != null) ...[
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: themeProvider.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                if (event.price > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '💰 TK ${event.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Like',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.phone_outlined,
                  label: 'Contact',
                  onTap: () {},
                  color: Colors.green[600]!,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                  color: themeProvider.accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatEventDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
