// services/post_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final supabase = Supabase.instance.client;

  // 1. Chobi upload kora (Web & Mobile Compatible)
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'post_images/$fileName';

      // Bytes read kora holo jeno Web-e error na hoy
      final imageBytes = await imageFile.readAsBytes();

      await supabase.storage
          .from('travel_posts')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('travel_posts').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      print("Image Upload Error: $e");
      return null;
    }
  }

  // 2. Database-e save kora (Anonymous support shoho)
  Future<void> createPost({
    required String content,
    required String? imageUrl,
    required String location,
    required bool isLookingForGroup,
    required bool isAnonymous, // Notun parameter add kora hoyeche
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('posts').insert({
        'user_id': user.id,
        'content': content,
        'image_url': imageUrl,
        'location_name': location,
        'is_looking_for_group': isLookingForGroup,
        'is_anonymous': isAnonymous, // Database column-e value-ti jabe
      });
    } catch (e) {
      print("Post Creation Error: $e");
      rethrow; // Error thakle seta jeno handle kora jay
    }
  }
}
