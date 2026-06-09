// services/post_service.dart
// services/post_service.dart (UPDATED)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PostService {
  final supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD IMAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String> uploadImage(XFile imageFile) async {
    try {
      final file = await imageFile.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      await supabase.storage.from('post-images').uploadBinary(
            'posts/$fileName',
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl =
          supabase.storage.from('post-images').getPublicUrl('posts/$fileName');

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE POST - UPDATED with contact number and user full name
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? imageUrl,
    String? location,
    String? contactNumber,
    bool isLookingForGroup = false,
    bool isAnonymous = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's full name
      final userProfile = await supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', userId)
          .maybeSingle();

      final userFullName = userProfile?['full_name'] as String? ?? 'Traveler';
      final userPhoneFromProfile = userProfile?['phone_number'] as String?;

      // Use provided contact number or fallback to profile phone
      final finalContactNumber = contactNumber ?? userPhoneFromProfile ?? '';

      final response = await supabase
          .from('posts')
          .insert({
            'user_id': userId,
            'content': content,
            'image_url': imageUrl,
            'location_name': location?.isEmpty ?? true ? null : location,
            'contact_number': finalContactNumber,
            'user_full_name': userFullName,
            'is_looking_for_group': isLookingForGroup,
            'is_anonymous': isAnonymous,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET ALL POSTS (Stream)
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET POSTS BY USER
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getPostsByUser(String userId) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET POST BY ID
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final response =
          await supabase.from('posts').select().eq('id', postId).maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> updatePost(
    String postId, {
    String? content,
    String? imageUrl,
    String? location,
    String? contactNumber,
    bool? isLookingForGroup,
    bool? isAnonymous,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (content != null) updates['content'] = content;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (location != null) updates['location_name'] = location;
      if (contactNumber != null) updates['contact_number'] = contactNumber;
      if (isLookingForGroup != null) {
        updates['is_looking_for_group'] = isLookingForGroup;
      }
      if (isAnonymous != null) updates['is_anonymous'] = isAnonymous;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('posts').update(updates).eq('id', postId);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE POST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH POSTS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .or('content.ilike.%$query%,location_name.ilike.%$query%')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET POSTS BY LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getPostsByLocation(String location) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .ilike('location_name', '%$location%')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching posts by location: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET POSTS LOOKING FOR GROUP
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getGroupPostsbyLocation(
      String location) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('is_looking_for_group', true)
          .ilike('location_name', '%$location%')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching group posts: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET RECENT POSTS (with pagination)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getRecentPosts({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final offset = page * limit;
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e) {
      print('Error fetching recent posts: $e');
      return [];
    }
  }
}
