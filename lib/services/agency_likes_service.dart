// services/agency_likes_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyLikesService {
  final supabase = Supabase.instance.client;

  /// ✅ Toggle Like/Unlike
  Future<bool> toggleLike(String postId) async {
    try {
      debugPrint('🔄 Toggling like for post: $postId');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ User not authenticated');
        throw Exception('Please login to like posts');
      }

      debugPrint('👤 User ID: $userId');

      // Check if already liked
      final existing = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        debugPrint('❤️ Unlike করছি...');
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        debugPrint('✅ Unlike করা হয়েছে');
        return false;
      } else {
        // Like
        debugPrint('🤍 Like করছি...');
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ Like করা হয়েছে');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Like toggle error: $e');
      rethrow;
    }
  }

  /// ✅ Check if user liked this post
  Future<bool> isPostLikedByUser(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ Check like error: $e');
      return false;
    }
  }

  /// ✅ Get likes count
  Future<int> getLikesCount(String postId) async {
    try {
      final result =
          await supabase.from('post_likes').select().eq('post_id', postId);

      return (result as List).length;
    } catch (e) {
      debugPrint('❌ Get likes count error: $e');
      return 0;
    }
  }

  /// ✅ Stream likes count (real-time updates)
  Stream<int> streamLikesCount(String postId) {
    return supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => (rows as List).length)
        .handleError((e) {
          debugPrint('❌ Stream likes error: $e');
          return 0;
        });
  }

  /// ✅ Stream user like status (real-time)
  Stream<bool> streamUserLikeStatus(String postId) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(false);
    }

    return supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) {
          final likes = (rows as List).cast<Map<String, dynamic>>();
          return likes.any((like) => like['user_id'] == userId);
        })
        .handleError((e) {
          debugPrint('❌ Stream user like status error: $e');
          return false;
        });
  }
}
