// services/likes_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikesService {
  final supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOGGLE LIKE/UNLIKE POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      // Check if already liked
      final existing = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false; // Now unliked
      } else {
        // Like
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true; // Now liked
      }
    } catch (e) {
      debugPrint(' toggleLike error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK IF USER LIKED POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> hasUserLiked({
    required String postId,
    required String userId,
  }) async {
    try {
      final result = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint(' hasUserLiked error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET LIKES COUNT FOR POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<int> getLikesCount(String postId) async {
    try {
      final result =
          await supabase.from('post_likes').select().eq('post_id', postId);

      return (result as List).length;
    } catch (e) {
      debugPrint(' getLikesCount error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM LIKES COUNT (Real-time updates)
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<int> streamLikesCount(String postId) {
    return supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => (rows as List).length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM USER LIKE STATUS (Real-time updates)
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<bool> streamUserLikeStatus({
    required String postId,
    required String userId,
  }) {
    return supabase
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) {
          final likes = (rows as List).cast<Map<String, dynamic>>();
          return likes.any((like) => like['user_id'] == userId);
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET USERS WHO LIKED POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getLikedByUsers(String postId) async {
    try {
      final result = await supabase
          .from('post_likes')
          .select(
            '*, user:user_id(id, full_name, username, avatar_url)',
          )
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint(' getLikedByUsers error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE LIKE (Admin function)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> deleteLike({
    required String postId,
    required String userId,
  }) async {
    try {
      await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint(' deleteLike error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR ALL LIKES FOR POST (Admin function)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> clearPostLikes(String postId) async {
    try {
      await supabase.from('post_likes').delete().eq('post_id', postId);
    } catch (e) {
      debugPrint(' clearPostLikes error: $e');
      rethrow;
    }
  }
}
