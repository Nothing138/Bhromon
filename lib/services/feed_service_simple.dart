// services/feed_service_simple.dart
//  SIMPLE WORKING VERSION - Copy-paste এটা!

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedServiceSimple {
  final supabase = Supabase.instance.client;

  ///  Simple combined feed - কাজ করবে ১০০%
  Future<List<Map<String, dynamic>>> getCombinedFeed() async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 FETCHING COMBINED FEED...');
      debugPrint('═══════════════════════════════════════');

      // ① POSTS fetch করো
      debugPrint('Fetching posts...');
      final postsData = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(20) as List;

      debugPrint(' Posts count: ${postsData.length}');
      if (postsData.isNotEmpty) {
        debugPrint('   Sample post: ${postsData.first}');
      }

      // ② EVENTS fetch করো
      debugPrint(' Fetching events...');
      final eventsData = await supabase
          .from('agency_events')
          .select()
          .order('event_date', ascending: false)
          .limit(20) as List;

      debugPrint(' Events count: ${eventsData.length}');
      if (eventsData.isNotEmpty) {
        debugPrint('   Sample event: ${eventsData.first}');
      }

      // ③ Combine into single list
      final combined = <Map<String, dynamic>>[];

      // Add posts with type
      for (var post in postsData) {
        if (post is Map<String, dynamic>) {
          combined.add({
            ...post,
            'type': 'post',
            'sortDate': post['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // Add events with type
      for (var event in eventsData) {
        if (event is Map<String, dynamic>) {
          combined.add({
            ...event,
            'type': 'event',
            'sortDate': event['event_date'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // ④ Sort by date (newest first)
      combined.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['sortDate'].toString());
          final dateB = DateTime.parse(b['sortDate'].toString());
          return dateB.compareTo(dateA);
        } catch (e) {
          debugPrint('Sort error: $e');
          return 0;
        }
      });

      debugPrint('═══════════════════════════════════════');
      debugPrint(' FINAL FEED: ${combined.length} items');
      debugPrint('═══════════════════════════════════════');

      return combined;
    } catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint(' ERROR: $e');
      debugPrint('═══════════════════════════════════════');
      return [];
    }
  }

  ///  Check if data exists in database
  Future<void> checkDataExists() async {
    try {
      final posts = await supabase.from('posts').select('id');
      final events = await supabase.from('agency_events').select('id');

      debugPrint('\n📊 DATA CHECK:');
      debugPrint('Posts: ${(posts as List).length} found');
      debugPrint('Events: ${(events as List).length} found');
      debugPrint('');
    } catch (e) {
      debugPrint(' Data check error: $e');
    }
  }
}
