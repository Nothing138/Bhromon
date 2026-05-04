// services/post_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PostService {
  final supabase = Supabase.instance.client;

  // ১. ছবি আপলোড করা (Web & Mobile Compatible with Content Type)
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // ফাইল নেম এবং পাথ তৈরি
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path =
          '${user.id}/$fileName'; // ইউজারের নিজস্ব ফোল্ডারে সেভ করা ভালো

      final imageBytes = await imageFile.readAsBytes();

      await supabase.storage
          .from('travel_posts')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              // ইমেজ টাইপ ডিফাইন করা থাকলে ব্রাউজারে প্রিভিউ ভালো হয়
              contentType: 'image/$fileExt',
            ),
          );

      // পাবলিক ইউআরএল জেনারেট করা
      final imageUrl = supabase.storage.from('travel_posts').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      debugPrint("Image Upload Error: $e");
      return null;
    }
  }

  // ২. ডাটাবেসে পোস্ট সেভ করা
  Future<bool> createPost({
    required String content,
    required String? imageUrl,
    required String location,
    required bool isLookingForGroup,
    required bool isAnonymous,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase.from('posts').insert({
        'user_id': user.id,
        'content': content,
        'image_url': imageUrl,
        'location_name': location,
        'is_looking_for_group': isLookingForGroup,
        'is_anonymous': isAnonymous,
        'created_at': DateTime.now()
            .toIso8601String(), // টাইমস্ট্যাম্প নিশ্চিত করা
      });
      return true; // সাকসেস হলে ট্রু রিটার্ন করবে
    } catch (e) {
      debugPrint("Post Creation Error: $e");
      return false;
    }
  }

  // ৩. ফিড এর জন্য পোস্ট ফেচ করা (প্রোফাইল ডাটা সহ)
  Future<List<dynamic>> fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select('*, profiles(full_name, avatar_url)') // ফরেন কি রিলেশনশিপ
          .order('created_at', ascending: false);

      return response as List<dynamic>;
    } catch (e) {
      debugPrint("Fetch Posts Error: $e");
      return [];
    }
  }
}
