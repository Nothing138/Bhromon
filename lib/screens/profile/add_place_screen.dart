// screens/profile/add_place_screen.dart
// ✅ Add Place Screen - Image upload সহ সম্পূর্ণ feature (Mobile + Web Compatible)

import 'dart:typed_data'; // 👈 Uint8List ব্যবহারের জন্য যুক্ত করা হয়েছে
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  XFile?
      _selectedImageFile; // 👈 File এর পরিবর্তে cross-platform XFile ব্যবহার করা হয়েছে
  Uint8List?
      _imageBytes; // 👈 ওয়েব ও মোবাইলে ইমেজ শো এবং আপলোডের জন্য বাইটস রাখা হয়েছে
  int _selectedRating = 0;
  bool _isPublic = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Nature',
    'Beach',
    'Mountain',
    'Adventure',
    'City',
    'Restaurant',
    'Hotel',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked != null) {
        final bytes =
            await picked.readAsBytes(); // 👈 ইমেজটিকে বাইটে কনভার্ট করা হচ্ছে
        setState(() {
          _selectedImageFile = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(String placeName) async {
    if (_imageBytes == null || _selectedImageFile == null) return null;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // XFile থেকে ফাইলের নাম ও এক্সটেনশন নেওয়া হচ্ছে (মোবাইল ও ওয়েব দুইটার জন্যই নিরাপদ)
      final ext = _selectedImageFile!.name.split('.').last.toLowerCase();
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      // 👈 upload এর পরিবর্তে uploadBinary ব্যবহার করা হয়েছে যা Uint8List সাপোর্ট করে
      await supabase.storage.from('place_images').uploadBinary(
            fileName,
            _imageBytes!,
            fileOptions: const FileOptions(upsert: false),
          );

      final url = supabase.storage.from('place_images').getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<bool> _placesNameExists(String name) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final existing = await supabase
          .from('user_added_places')
          .select('id')
          .eq('user_id', user.id)
          .ilike('name', name.trim());

      return existing.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking place: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Duplicate name check
      final exists = await _placesNameExists(_nameController.text);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have a place with this name'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await _uploadImage(_nameController.text);
      }

      // Insert place
      await supabase.from('user_added_places').insert({
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'image_url': imageUrl,
        'rating': _selectedRating > 0 ? _selectedRating : null,
        'notes': _notesController.text.trim(),
        'is_public': _isPublic,
        'visited_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding place: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Add New Place',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              _buildImagePicker(cardColor, accentColor, isDark, textColor),
              const SizedBox(height: 24),

              // Place name
              _buildTextField(
                controller: _nameController,
                label: 'Place Name *',
                hint: 'e.g., Sundarbans',
                icon: Icons.location_on,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Place name required';
                  if (val!.length < 2) return 'Name too short';
                  return null;
                },
                textColor: textColor,
                cardColor: cardColor,
                accentColor: accentColor,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Location
              _buildTextField(
                controller: _locationController,
                label: 'Location/Address',
                hint: 'e.g., Khulna, Bangladesh',
                icon: Icons.map,
                textColor: textColor,
                cardColor: cardColor,
                accentColor: accentColor,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Category
              _buildCategoryDropdown(cardColor, textColor, accentColor, isDark),
              const SizedBox(height: 16),

              // Rating
              _buildRatingPicker(textColor, accentColor),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Tell about this place...',
                icon: Icons.description,
                maxLines: 3,
                textColor: textColor,
                cardColor: cardColor,
                accentColor: accentColor,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'Personal Notes',
                hint: 'Your memories, tips, etc...',
                icon: Icons.note,
                maxLines: 2,
                textColor: textColor,
                cardColor: cardColor,
                accentColor: accentColor,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Public toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Make this place public',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                      activeColor: accentColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: accentColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Place',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    Color cardColor,
    Color accentColor,
    bool isDark,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: _imageBytes == null // 👈 কন্ডিশন চেক এখন bytes দিয়ে করা হচ্ছে
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 48,
                      color: accentColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add photo',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional',
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _imageBytes!, // 👈 Image.file এর বদলে Image.memory ব্যবহার করায় ওয়েব ও মোবাইল দুইটাই সাপোর্ট করবে
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImageFile = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color cardColor,
    required Color accentColor,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          validator: validator,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: accentColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(
    Color cardColor,
    Color textColor,
    Color accentColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: Text('Select category',
              style: TextStyle(color: textColor.withOpacity(0.5))),
          items: _categories
              .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: TextStyle(color: textColor)),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            prefixIcon: Icon(Icons.category, color: accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingPicker(Color textColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            5,
            (index) => GestureDetector(
              onTap: () => setState(() => _selectedRating = index + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_outline,
                  size: 32,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
