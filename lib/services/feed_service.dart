// services/feed_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

class FeedService {
  final supabase = Supabase.instance.client;

  /// Combined stream of Posts + Events sorted by date - with FULL ERROR HANDLING
  Stream<List<Map<String, dynamic>>> getCombinedFeed() {
    try {
      debugPrint('✅ FeedService: Starting getCombinedFeed()');

      // ═══════════════════════════════════════════════════════════════
      // POSTS STREAM - with error handling
      // ═══════════════════════════════════════════════════════════════
      final postsStream = supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .handleError((error) {
            debugPrint('❌ Posts Stream Error: $error');
            return <Map<String, dynamic>>[];
          })
          .map<List<Map<String, dynamic>>>((postsList) {
            try {
              debugPrint('📸 Posts received: ${postsList.length}');
              return postsList.cast<Map<String, dynamic>>().map((p) {
                return {
                  ...p,
                  'type': 'post',
                  'sortDate':
                      p['created_at'] ?? DateTime.now().toIso8601String(),
                };
              }).toList();
            } catch (e) {
              debugPrint('❌ Posts Map Error: $e');
              return [];
            }
          })
          .startWith(<Map<String, dynamic>>[]);

      // ═══════════════════════════════════════════════════════════════
      // EVENTS STREAM - with error handling
      // ═══════════════════════════════════════════════════════════════
      final eventsStream = supabase
          .from('agency_events')
          .stream(primaryKey: ['id'])
          .order('event_date', ascending: false)
          .handleError((error) {
            debugPrint('❌ Events Stream Error: $error');
            return <Map<String, dynamic>>[];
          })
          .map<List<Map<String, dynamic>>>((eventsList) {
            try {
              debugPrint('🎫 Events received: ${eventsList.length}');
              return eventsList.cast<Map<String, dynamic>>().map((e) {
                return {
                  ...e,
                  'type': 'event',
                  'sortDate':
                      e['event_date'] ?? DateTime.now().toIso8601String(),
                };
              }).toList();
            } catch (e) {
              debugPrint('❌ Events Map Error: $e');
              return [];
            }
          })
          .startWith(<Map<String, dynamic>>[]);

      // ═══════════════════════════════════════════════════════════════
      // COMBINE STREAMS - with smart merging + sorting
      // ═══════════════════════════════════════════════════════════════
      return Rx.combineLatest2<List<Map<String, dynamic>>,
          List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
        postsStream,
        eventsStream,
        (posts, events) {
          try {
            debugPrint(
                '🔄 Combining feeds: Posts=${posts.length}, Events=${events.length}');

            // Merge both lists
            final combined = <Map<String, dynamic>>[...posts, ...events];

            // Sort by date - newest first
            combined.sort((a, b) {
              try {
                final dateA = DateTime.parse(a['sortDate']?.toString() ??
                    DateTime.now().toIso8601String());
                final dateB = DateTime.parse(b['sortDate']?.toString() ??
                    DateTime.now().toIso8601String());
                return dateB.compareTo(dateA);
              } catch (e) {
                debugPrint('⚠️ Sort Error: $e');
                return 0;
              }
            });

            debugPrint('✅ Final feed: ${combined.length} items');
            return combined;
          } catch (e) {
            debugPrint('❌ Combine Error: $e');
            return [];
          }
        },
      ).handleError((error) {
        debugPrint('❌ CombineLatest Error: $error');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint('❌ getCombinedFeed() Fatal Error: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG HELPER - Check if tables have data
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> debugFeedData() async {
    try {
      // Check posts
      final postsCount = await supabase
          .from('posts')
          .select()
          .then((data) => (data as List).length);
      debugPrint('📸 Posts count: $postsCount');

      // Check events
      final eventsCount = await supabase
          .from('agency_events')
          .select()
          .then((data) => (data as List).length);
      debugPrint('🎫 Events count: $eventsCount');

      // Sample posts
      final samplePosts = await supabase.from('posts').select().limit(1);
      if (samplePosts.isNotEmpty) {
        debugPrint('📸 Sample post: ${samplePosts.first.keys.toList()}');
      }

      // Sample events
      final sampleEvents =
          await supabase.from('agency_events').select().limit(1);
      if (sampleEvents.isNotEmpty) {
        debugPrint('🎫 Sample event: ${sampleEvents.first.keys.toList()}');
      }
    } catch (e) {
      debugPrint('❌ Debug Error: $e');
    }
  }
}
