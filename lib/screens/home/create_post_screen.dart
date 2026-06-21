// screens/home/create_post_screen.dart
// ✅ FULLY FIXED FOR WEB + MOBILE
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  final _contactController = TextEditingController();
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
    // Validation
    if (_contentController.text.isEmpty) {
      _showSnackBar('Please write something first!', Colors.redAccent);
      return;
    }

    if (_contactController.text.isEmpty) {
      _showSnackBar('Please provide your contact number', Colors.redAccent);
      return;
    }

    // Validate phone number (basic validation)
    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(_contactController.text)) {
      _showSnackBar('Please enter a valid phone number', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    String? imageUrl;

    try {
      if (_selectedImage != null) {
        imageUrl = await PostService().uploadImage(_selectedImage!);
      }

      await PostService().createPost(
        content: _contentController.text,
        imageUrl: imageUrl,
        location: _locationController.text,
        contactNumber: _contactController.text,
        isLookingForGroup: _isGroupTour,
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        _showSnackBar('Post created successfully!', Colors.green);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create post: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surface,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_rounded, color: textPrimary),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'Create Post',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _submitPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'POST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isAnonymous
                          ? Colors.grey.withValues(alpha: 0.2)
                          : accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isAnonymous
                          ? Icons.visibility_off_rounded
                          : Icons.person_outline_rounded,
                      color: _isAnonymous ? Colors.grey : accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAnonymous ? 'Anonymous Traveler' : 'Public Identity',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isAnonymous
                            ? 'Your name won\'t be visible'
                            : 'Your profile will be shown',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Input
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your travel experience...',
                  hintStyle: TextStyle(color: textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Image Preview - ✅ WEB COMPATIBLE
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      // ✅ Conditional image loading for web/mobile
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: Colors.grey.withValues(alpha: 0.2),
                                child: const Center(
                                  child: Text('Image preview unavailable'),
                                ),
                              ),
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              height: 220,
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
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Contact Number Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your contact number (required)',
                        hintStyle: TextStyle(color: textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Where are you? (optional)',
                        hintStyle: TextStyle(color: textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Options
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  // Group Tour Toggle
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isGroupTour
                                ? accentColor.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.group_add_outlined,
                            color: _isGroupTour ? accentColor : Colors.grey,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Looking for Group?',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Find travel buddies for this trip',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isGroupTour,
                          onChanged: (value) =>
                              setState(() => _isGroupTour = value),
                          activeThumbColor: accentColor,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: surfaceBorder,
                    height: 1,
                    indent: 52,
                  ),
                  // Anonymous Toggle
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isAnonymous
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.privacy_tip_outlined,
                            color: _isAnonymous ? Colors.blue : Colors.grey,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Post Anonymously',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your name won\'t be visible',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          onChanged: (value) =>
                              setState(() => _isAnonymous = value),
                          activeThumbColor: accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Photo Button
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedImage == null ? 'Select Photo' : 'Change Photo',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
