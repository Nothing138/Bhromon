// services/feed_service.dart
// services/feed_service.dart - FIXED VERSION with Auto-Reconnect
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

class FeedService {
  final supabase = Supabase.instance.client;

  // Connection management
  static final _instance = FeedService._internal();
  final _connectionSubject = BehaviorSubject<bool>.seeded(true);

  // Retry logic
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  factory FeedService() {
    return _instance;
  }

  FeedService._internal();

  Stream<bool> get connectionStatus => _connectionSubject.stream;

  /// Combined stream of Posts + Events sorted by date - with AUTO-RECONNECT
  Stream<List<Map<String, dynamic>>> getCombinedFeed() {
    return _getCombinedFeedWithRetry(0);
  }

  Stream<List<Map<String, dynamic>>> _getCombinedFeedWithRetry(int attempt) {
    try {
      debugPrint(
          '✅ FeedService: Starting getCombinedFeed() - Attempt ${attempt + 1}');

      // ═══════════════════════════════════════════════════════════════
      // POSTS STREAM - with error handling & retry
      // ═══════════════════════════════════════════════════════════════
      final postsStream = supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .handleError((error) {
            debugPrint('❌ Posts Stream Error (Attempt $attempt): $error');
            _connectionSubject.add(false);

            // Auto-reconnect after delay
            if (attempt < _maxRetries) {
              return Future.delayed(_retryDelay).then((_) {
                _connectionSubject.add(true);
                return _getCombinedFeedWithRetry(attempt + 1);
              });
            }

            return <Map<String, dynamic>>[];
          })
          .map<List<Map<String, dynamic>>>((postsList) {
            try {
              _connectionSubject.add(true);
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
      // EVENTS STREAM - with error handling & retry
      // ═══════════════════════════════════════════════════════════════
      final eventsStream = supabase
          .from('agency_events')
          .stream(primaryKey: ['id'])
          .order('event_date', ascending: false)
          .handleError((error) {
            debugPrint('❌ Events Stream Error (Attempt $attempt): $error');
            _connectionSubject.add(false);

            // Auto-reconnect after delay
            if (attempt < _maxRetries) {
              return Future.delayed(_retryDelay).then((_) {
                _connectionSubject.add(true);
                return _getCombinedFeedWithRetry(attempt + 1);
              });
            }

            return <Map<String, dynamic>>[];
          })
          .map<List<Map<String, dynamic>>>((eventsList) {
            try {
              _connectionSubject.add(true);
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
        _connectionSubject.add(false);
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint('❌ getCombinedFeed() Fatal Error: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// FALLBACK: Get feed via HTTP (if realtime fails)
  Future<List<Map<String, dynamic>>> getCombinedFeedHTTP() async {
    try {
      debugPrint('🌐 Fetching feed via HTTP fallback...');

      // Fetch posts
      final posts = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      // Fetch events
      final events = await supabase
          .from('agency_events')
          .select()
          .order('event_date', ascending: false)
          .limit(20);

      // Combine and sort
      final List<Map<String, dynamic>> combined = [];

      // Add posts
      if (posts is List) {
        for (var p in posts) {
          combined.add({
            ...?p as Map<String, dynamic>,
            'type': 'post',
          });
        }
      }

      // Add events
      if (events is List) {
        for (var e in events) {
          combined.add({
            ...?e as Map<String, dynamic>,
            'type': 'event',
          });
        }
      }

      // Sort by date - newest first
      combined.sort((a, b) {
        try {
          final dateA = DateTime.parse(
              a['created_at']?.toString() ?? a['event_date']?.toString() ?? '');
          final dateB = DateTime.parse(
              b['created_at']?.toString() ?? b['event_date']?.toString() ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          debugPrint('⚠️ Sort Error: $e');
          return 0;
        }
      });

      debugPrint('✅ HTTP Fallback: Got ${combined.length} items');
      return combined;
    } catch (e) {
      debugPrint('❌ HTTP Fallback Error: $e');
      return [];
    }
  }

  /// DEBUG HELPER - Check if tables have data
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

  /// Reset connection (call this on app resume)
  void resetConnection() {
    debugPrint('🔄 Resetting Realtime connection...');
    _connectionSubject.add(true);
  }

  /// Dispose resources
  void dispose() {
    _connectionSubject.close();
  }
}
