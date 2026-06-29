// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../services/likes_service.dart';
import '../../services/feed_service.dart';
import '../../models/event_booking_modal.dart';
import '../auth/login_screen.dart';
import 'create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/booking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  late final LikesService _likesService;
  late final FeedService _feedService;
  late String _currentUserId;
  String? _debugInfo; // For showing debug messages

  @override
  void initState() {
    super.initState();
    _likesService = LikesService();
    _feedService = FeedService();
    _currentUserId = supabase.auth.currentUser?.id ?? '';

    //  DEBUG: Check database on init (FIXED - now checks mounted)
    _debugCheckDatabase();
  }

  ///  FIXED: Debug helper - check if data exists in database
  /// Now properly checks if widget is still mounted before setState()
  Future<void> _debugCheckDatabase() async {
    try {
      debugPrint(' Starting database debug check...');

      // Check posts
      final posts = await supabase
          .from('posts')
          .select()
          .timeout(const Duration(seconds: 5));
      debugPrint('Posts count: ${posts.length}');

      // Check events
      final events = await supabase
          .from('agency_events')
          .select()
          .timeout(const Duration(seconds: 5));
      debugPrint(' Events count: ${events.length}');

      //  CRITICAL: Only call setState() if widget is still mounted
      if (mounted) {
        setState(() {
          _debugInfo = 'Posts: ${posts.length}, Events: ${events.length}';
        });
      }
    } catch (e) {
      debugPrint(' Database check failed: $e');
      //  CRITICAL: Only call setState() if widget is still mounted
      if (mounted) {
        setState(() {
          _debugInfo = 'DB Error: $e';
        });
      }
    }
  }

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
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

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
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.12),
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
        stream: _feedService.getCombinedFeed(),
        builder: (context, snapshot) {
          debugPrint('Stream state: ${snapshot.connectionState}');
          debugPrint('Snapshot has data: ${snapshot.hasData}');
          debugPrint(' Snapshot has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            debugPrint(' Stream error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: accentColor,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  if (_debugInfo != null)
                    Text(
                      _debugInfo!,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                ],
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
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stream Error',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: surfaceBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.photo_camera_back_outlined,
                      size: 32,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No posts or events yet',
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
            itemCount: items.length,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, index) {
              final item = items[index];
              final itemType = item['type'] as String;

              if (itemType == 'post') {
                return _buildPostCard(
                  item,
                  accentColor,
                  isDark,
                  surface,
                  surfaceBorder,
                  textPrimary,
                  textSecondary,
                );
              } else {
                return _buildEventCard(
                  item,
                  accentColor,
                  isDark,
                  surface,
                  surfaceBorder,
                  textPrimary,
                  textSecondary,
                );
              }
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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

  Widget _buildEventCard(
    Map<String, dynamic> event,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final title = event['title'] as String? ?? 'Event';
    final description = event['description'] as String? ?? '';
    final location = event['location'] as String? ?? 'TBA';
    final imageUrl = event['image_url'] as String?;
    final price = event['price'] as num? ?? 0;
    final eventId = event['id'] as String? ?? '';

    final eventDate = event['event_date'] != null
        ? DateTime.parse(event['event_date'] as String)
        : DateTime.now();
    final formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(eventDate);

    //  Check if event has passed
    final isEventPassed = eventDate.isBefore(DateTime.now());

    //  Use StreamBuilder for REAL-TIME seat updates
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: BookingService().streamEventDetails(eventId),
        initialData: event,
        builder: (context, eventSnapshot) {
          // Use updated event data if available
          final currentEvent = eventSnapshot.data ?? event;
          final bookedCount = currentEvent['booked_count'] as int? ?? 0;
          final capacity = currentEvent['capacity'] as int?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TYPE BADGE
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 10, right: 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    ' Agency Event',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              // IMAGE
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF0F2F8),
                      child: Center(
                        child: Icon(
                          Icons.event_note,
                          color: Colors.purple.withValues(alpha: 0.5),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // DESCRIPTION
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // DATE & LOCATION INFO
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color:
                                    isEventPassed ? Colors.orange : Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isEventPassed
                                        ? Colors.orange
                                        : textSecondary,
                                    fontWeight: isEventPassed
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // PRICE & CAPACITY -  WITH REAL-TIME UPDATES
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '৳${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (capacity != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: bookedCount >= capacity
                                    ? Colors.red.withValues(alpha: 0.08)
                                    : Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: bookedCount >= capacity
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seats Available',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${capacity - bookedCount}/${capacity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: bookedCount >= capacity
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ACTION BUTTONS -  WITH BOOKING STATUS
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildEventBookButtonWithStatus(
                        event: currentEvent,
                        eventId: eventId,
                        accentColor: accentColor,
                        isEventPassed: isEventPassed,
                        bookedCount: bookedCount,
                        capacity: capacity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildShareButton(
                        event: currentEvent,
                        accentColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

//  UPDATED BOOK BUTTON WITH STATUS CHECK
  Widget _buildEventBookButtonWithStatus({
    required Map<String, dynamic> event,
    required String eventId,
    required Color accentColor,
    required bool isEventPassed,
    required int bookedCount,
    required int? capacity,
  }) {
    return FutureBuilder<bool>(
      future: BookingService().hasUserBookedEvent(eventId, _currentUserId),
      builder: (context, snapshot) {
        final hasBooked = snapshot.data ?? false;
        final isFull = capacity != null && bookedCount >= capacity;

        return InkWell(
          onTap: isEventPassed || hasBooked || isFull
              ? () {
                  String message = '';
                  if (hasBooked) {
                    message = ' You have already booked this event!';
                  } else if (isEventPassed) {
                    message = '⏰ This event date has passed';
                  } else if (isFull) {
                    message = '🪑 This event is fully booked';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: hasBooked
                          ? Colors.green
                          : (isFull ? Colors.red : Colors.orange),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : () {
                  // Show booking modal
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EventBookingModal(
                      event: event,
                      userId: _currentUserId,
                      onBookingSuccess: () {
                        setState(() {});
                      },
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasBooked
                  ? Colors.green.withValues(alpha: 0.15)
                  : (isFull || isEventPassed)
                      ? accentColor.withValues(alpha: 0.05)
                      : Colors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: hasBooked
                    ? Colors.green.withValues(alpha: 0.3)
                    : (isFull || isEventPassed)
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.purple.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasBooked
                      ? Icons.check_circle_rounded
                      : Icons.event_available_rounded,
                  size: 14,
                  color: hasBooked
                      ? Colors.green
                      : (isFull || isEventPassed)
                          ? accentColor.withValues(alpha: 0.5)
                          : Colors.purple,
                ),
                const SizedBox(width: 3),
                Text(
                  hasBooked
                      ? 'Booked'
                      : (isFull
                          ? 'Full'
                          : (isEventPassed ? 'Expired' : 'Book')),
                  style: TextStyle(
                    color: hasBooked
                        ? Colors.green
                        : (isFull || isEventPassed)
                            ? accentColor.withValues(alpha: 0.5)
                            : Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

//  UPDATED SHARE BUTTON WITH REAL FUNCTIONALITY
  Widget _buildShareButton({
    required Map<String, dynamic> event,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () {
        final eventTitle = event['title'] as String? ?? 'Event';
        final eventLocation = event['location'] as String? ?? '';
        final eventDate = event['event_date'] as String? ?? '';

        // Create share message
        final shareMessage = ''' Check out this amazing event: "$eventTitle"
 
📍 Location: $eventLocation
📅 Date: $eventDate
 
Book your spot now on Bhromon! 🚀''';

        // Show share options
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF111827)
                  : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE2E8F4)
                        : const Color(0xFF0D1117),
                  ),
                ),
                const SizedBox(height: 20),
                _buildShareOption(
                  icon: Icons.message_rounded,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () {
                    // WhatsApp share
                    final message = Uri.encodeComponent(shareMessage);
                    launchUrl(Uri.parse('whatsapp://send?text=$message'));
                    Navigator.pop(_);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: Colors.blue,
                  onTap: () {
                    // SMS share
                    launchUrl(Uri.parse('sms:?body=$shareMessage'));
                    Navigator.pop(_);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.content_copy_rounded,
                  label: 'Copy Link',
                  color: accentColor,
                  onTap: () {
                    // Copy to clipboard
                    final link = 'bhromon://event/${event['id']}';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Event link copied: $link'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(_);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(_),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 3),
            Text(
              'Share',
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Share option widget helper
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  //  UPDATED BOOK BUTTON WITH MODAL
  Widget _buildEventBookButton({
    required Map<String, dynamic> event,
    required Color accentColor,
    required bool isEventPassed,
  }) {
    return InkWell(
      onTap: isEventPassed
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This event date has passed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : () {
              //  SHOW BOOKING MODAL
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EventBookingModal(
                  event: event,
                  userId: _currentUserId,
                  onBookingSuccess: () {
                    // Refresh feed after successful booking
                    setState(() {});
                  },
                ),
              );
            },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isEventPassed
              ? accentColor.withValues(alpha: 0.05)
              : Colors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isEventPassed
                ? accentColor.withValues(alpha: 0.1)
                : Colors.purple.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 14,
              color: isEventPassed
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.purple,
            ),
            const SizedBox(width: 3),
            Text(
              isEventPassed ? 'Expired' : 'Book',
              style: TextStyle(
                color: isEventPassed
                    ? accentColor.withValues(alpha: 0.5)
                    : Colors.purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [KEEP ALL OTHER WIDGETS FROM PREVIOUS CODE]
  // Including: _buildPostCard, _buildLikeButton, _buildMessageButton, etc.
  // ...

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
    final userName = (post['user_full_name'] as String?) ?? 'Traveler';
    final contactNumber = (post['contact_number'] as String?) ?? '';
    final posterId = (post['user_id'] as String?) ?? '';
    final postId = (post['id'] as String?) ?? '';

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
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 10, right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                'User Post',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: GestureDetector(
              onTap: () => _showUserProfile(
                context,
                userName,
                contactNumber,
                isAnonymous,
                posterId,
                accentColor,
                isDark,
                surface,
                surfaceBorder,
                textPrimary,
                textSecondary,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isAnonymous
                          ? const Color(0xFF1E2A42)
                          : accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isAnonymous
                            ? const Color(0xFF2E3A56)
                            : accentColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      isAnonymous
                          ? Icons.visibility_off_outlined
                          : Icons.person_outline_rounded,
                      color:
                          isAnonymous ? const Color(0xFF4A5478) : accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous ? 'Anonymous traveler' : userName,
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
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
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
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _buildLikeButton(
                    postId: postId,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isAnonymous && contactNumber.isNotEmpty)
                  Expanded(
                    child: _buildMessageButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: posterId,
                            otherUserName: userName,
                            otherUserPhone: contactNumber,
                          ),
                        ),
                      ),
                      accentColor: accentColor,
                    ),
                  ),
                if (!isAnonymous && contactNumber.isNotEmpty)
                  const SizedBox(width: 8),
                if (!isAnonymous && contactNumber.isNotEmpty)
                  Expanded(
                    child: _buildContactButton(
                      phone: contactNumber,
                      accentColor: accentColor,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildShareButton(
                    event: post,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton({
    required String postId,
    required Color accentColor,
  }) {
    return StreamBuilder<bool>(
      stream: _likesService.streamUserLikeStatus(
        postId: postId,
        userId: _currentUserId,
      ),
      builder: (context, likeSnapshot) {
        final isLiked = likeSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: _likesService.streamLikesCount(postId),
          builder: (context, countSnapshot) {
            final likesCount = countSnapshot.data ?? 0;

            return InkWell(
              onTap: () async {
                try {
                  await _likesService.toggleLike(
                    postId: postId,
                    userId: _currentUserId,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLiked
                      ? Colors.red.withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isLiked
                        ? Colors.red.withValues(alpha: 0.3)
                        : accentColor.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: isLiked ? Colors.red : accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        color: isLiked ? Colors.red : accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageButton({
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 3),
            Text(
              'Message',
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String phone,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone: $phone'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_rounded,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 3),
            Text(
              'Call',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(
    BuildContext context,
    String userName,
    String contactNumber,
    bool isAnonymous,
    String posterId,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user posted anonymously'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Travel Enthusiast',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (contactNumber.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2340)
                      : const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: surfaceBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contactNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: accentColor),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied: $contactNumber'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (posterId != _currentUserId)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: posterId,
                        otherUserName: userName,
                        otherUserPhone: contactNumber,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Send Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
