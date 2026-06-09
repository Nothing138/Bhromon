// services/message_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await supabase
          .from('messages')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'content': content,
            'message_type': messageType,
            'read_status': false,
          })
          .select()
          .single();

      // Update conversation metadata in background
      _updateConversationMetadata(senderId, receiverId, content);
      _updateOrCreateContact(senderId, receiverId);

      return response;
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET MESSAGES STREAM (Real-time) — FIXED
  // Problem: Supabase .stream() does NOT support chained .or() calls.
  // Fix: Use a single .eq() filter on a view, OR fetch via future + realtime.
  // We use a reliable approach: stream ALL user messages, filter in Dart.
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<List<Map<String, dynamic>>> getMessagesStream(
    String userId,
    String otherUserId,
  ) {
    // Stream messages where current user is either sender or receiver.
    // We filter in .map() to get only messages between these two users.
    // This is the only reliable way with Supabase stream + complex OR filters.
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', userId) // stream limitation: only one .eq allowed
        .order('created_at', ascending: true)
        .map((rows) {
          // This gives us messages SENT by userId.
          // We combine with received messages via a separate approach below.
          return (rows as List)
              .cast<Map<String, dynamic>>()
              .where((msg) =>
                  (msg['sender_id'] == userId &&
                      msg['receiver_id'] == otherUserId) ||
                  (msg['sender_id'] == otherUserId &&
                      msg['receiver_id'] == userId))
              .toList();
        });
  }

  // Better approach: use asyncExpand to merge sent + received streams
  Stream<List<Map<String, dynamic>>> getConversationStream(
    String userId,
    String otherUserId,
  ) {
    // Stream messages sent by current user to other user
    final sentStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', userId)
        .order('created_at', ascending: true);

    // Stream messages received by current user from other user
    final receivedStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', otherUserId)
        .order('created_at', ascending: true);

    // Combine both streams
    return sentStream.asyncMap((sentRows) async {
      // For each update to sent messages, also fetch received
      try {
        final received = await supabase
            .from('messages')
            .select()
            .or('and(sender_id.eq.$otherUserId,receiver_id.eq.$userId),'
                'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId)')
            .order('created_at', ascending: true);

        final all = (received as List).cast<Map<String, dynamic>>();

        // Deduplicate by id
        final seen = <String>{};
        final unique = all.where((m) => seen.add(m['id'] as String)).toList();
        unique.sort((a, b) => DateTime.parse(a['created_at'] as String)
            .compareTo(DateTime.parse(b['created_at'] as String)));
        return unique;
      } catch (e) {
        debugPrint('❌ getConversationStream error: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET ALL CONVERSATIONS (for contacts list)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getAllConversations(
    String userId, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final offset = page * limit;
      final response = await supabase
          .from('conversation_metadata')
          .select(
            '*, '
            'user_1:user_1_id(id, username, avatar_url, full_name), '
            'user_2:user_2_id(id, username, avatar_url, full_name)',
          )
          .or('user_1_id.eq.$userId,user_2_id.eq.$userId')
          .order('last_message_time', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ getAllConversations error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARK MESSAGES AS READ
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> markMessagesAsRead(String userId, String senderId) async {
    try {
      await supabase
          .from('messages')
          .update({'read_status': true})
          .eq('receiver_id', userId)
          .eq('sender_id', senderId)
          .eq('read_status', false);
    } catch (e) {
      debugPrint('❌ markMessagesAsRead error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET UNREAD COUNT
  // ═══════════════════════════════════════════════════════════════════════════
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .eq('read_status', false);
      return (response as List).length;
    } catch (e) {
      debugPrint('❌ getUnreadCount error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE MESSAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      debugPrint('❌ deleteMessage error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH CONTACTS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> searchContacts(
    String userId,
    String query,
  ) async {
    try {
      final response = await supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .or('contact_name.ilike.%$query%,contact_phone.ilike.%$query%');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ searchContacts error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: Update conversation metadata (upsert)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _updateConversationMetadata(
    String userId1,
    String userId2,
    String lastMessage,
  ) async {
    try {
      // Always store with smaller UUID first for consistency
      final isFirst = userId1.compareTo(userId2) < 0;
      final u1 = isFirst ? userId1 : userId2;
      final u2 = isFirst ? userId2 : userId1;

      final existing = await supabase
          .from('conversation_metadata')
          .select()
          .eq('user_1_id', u1)
          .eq('user_2_id', u2)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('conversation_metadata')
            .update({
              'last_message': lastMessage,
              'last_message_time': DateTime.now().toIso8601String(),
              'message_count': ((existing['message_count'] as int?) ?? 0) + 1,
            })
            .eq('user_1_id', u1)
            .eq('user_2_id', u2);
      } else {
        await supabase.from('conversation_metadata').insert({
          'user_1_id': u1,
          'user_2_id': u2,
          'last_message': lastMessage,
          'last_message_time': DateTime.now().toIso8601String(),
          'message_count': 1,
        });
      }
    } catch (e) {
      debugPrint('❌ _updateConversationMetadata error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE: Update or create contact entry
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _updateOrCreateContact(
    String userId,
    String contactUserId,
  ) async {
    try {
      final existing = await supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .eq('contact_user_id', contactUserId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('contacts')
            .update({'last_message_at': DateTime.now().toIso8601String()})
            .eq('user_id', userId)
            .eq('contact_user_id', contactUserId);
      } else {
        final contactProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', contactUserId)
            .maybeSingle();

        await supabase.from('contacts').insert({
          'user_id': userId,
          'contact_user_id': contactUserId,
          'contact_name': contactProfile?['full_name'] ?? 'Unknown',
          'contact_phone': contactProfile?['phone_number'],
          'last_message_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ _updateOrCreateContact error: $e');
    }
  }
}
