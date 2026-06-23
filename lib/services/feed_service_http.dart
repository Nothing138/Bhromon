// services/feed_service_http.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedServiceHttp {
  static const String baseUrl = 'http://localhost:3000/api';

  final String authToken; // Pass JWT token from auth

  FeedServiceHttp({required this.authToken});

  Future<List<Map<String, dynamic>>> getCombinedFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feed/combined?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load feed');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<bool> toggleLike(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/likes/toggle'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'postId': postId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] ?? false;
      } else {
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/actions/message'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
          'messageType': 'text',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<void> sharePost(String postId, List<String> shareWithUserIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/actions/share'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'postId': postId,
          'shareWithUserIds': shareWithUserIds,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to share post');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}
