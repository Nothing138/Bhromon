// screens/home/create_post_screen.dart
import 'dart:io'; // ফাইল ডিসপ্লে করার জন্য প্রয়োজন
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../../providers/theme_provider.dart';
import '../../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isGroupTour = false;
  bool _isAnonymous = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something first!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? imageUrl;

    if (_selectedImage != null) {
      imageUrl = await PostService().uploadImage(_selectedImage!);
    }

    await PostService().createPost(
      content: _contentController.text,
      imageUrl: imageUrl,
      location: _locationController.text,
      isLookingForGroup: _isGroupTour,
      isAnonymous: _isAnonymous,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // থিম এবং অ্যাকসেন্ট কালার কল করা হয়েছে
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Post",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        // অ্যাপবার এখন অ্যাকসেন্ট কালার নিবে
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _submitPost,
                  child: const Text(
                    "POST",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Section
            Row(
              children: [
                CircleAvatar(
                  // এনোনিমাস হলে গ্রে, নাহলে অ্যাকসেন্ট কালার
                  backgroundColor: _isAnonymous ? Colors.grey : accentColor,
                  child: Icon(
                    _isAnonymous ? Icons.visibility_off : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isAnonymous ? "Anonymous Traveler" : "Public Identity",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _contentController,
              maxLines: 6,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Share your travel experience...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
              ),
            ),

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(
                          _selectedImage!.path,
                        ), // local file দেখানোর জন্য Image.file ব্যবহার করা ভালো
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 30),

            // Location Input
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: accentColor),
              title: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: "Where are you?",
                  border: InputBorder.none,
                ),
              ),
            ),

            // Group Search Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: accentColor,
              title: const Text("Looking for Group?"),
              secondary: Icon(
                Icons.group_add,
                color: accentColor.withOpacity(0.8),
              ),
              value: _isGroupTour,
              onChanged: (val) => setState(() => _isGroupTour = val),
            ),

            // Anonymous Post Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: accentColor,
              title: const Text("Post Anonymously"),
              secondary: const Icon(Icons.security, color: Colors.blueGrey),
              value: _isAnonymous,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),

            const SizedBox(height: 25),

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.add_a_photo, color: accentColor),
              label: Text(
                "Select Photo",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(color: accentColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
