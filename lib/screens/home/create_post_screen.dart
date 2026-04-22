// screens/home/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
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
  bool _isAnonymous = false; // Anonymous toggle er jonno variable

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
      isAnonymous: _isAnonymous, // Ei field-ta service-e pathiye dite hobe
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
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
            // User Profile Section (Dynamic name display logic thakbe)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isAnonymous ? Colors.grey : Colors.teal,
                  child: Icon(
                    _isAnonymous ? Icons.visibility_off : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isAnonymous ? "Anonymous Traveler" : "Public Identity",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Share your travel experience...",
                border: InputBorder.none,
              ),
            ),

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    _selectedImage!.path,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const Divider(),

            // Location Input
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.redAccent),
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
              title: const Text("Looking for Group?"),
              secondary: const Icon(Icons.group_add, color: Colors.blue),
              value: _isGroupTour,
              onChanged: (val) => setState(() => _isGroupTour = val),
            ),

            // Anonymous Post Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Post Anonymously"),
              secondary: const Icon(Icons.security, color: Colors.blueGrey),
              value: _isAnonymous,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Select Photo"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
