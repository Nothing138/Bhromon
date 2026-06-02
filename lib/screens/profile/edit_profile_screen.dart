// screens/profile/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfileScreen({super.key, this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isUpdating = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialData?['full_name'] ?? '';
    _usernameController.text = widget.initialData?['username'] ?? '';
    _bioController.text = widget.initialData?['bio'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploadingPhoto = true);
    try {
      final user = supabase.auth.currentUser!;
      final ext = _selectedImage!.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$ext';
      await supabase.storage
          .from('avatars')
          .upload(
            fileName,
            _selectedImage!,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Photo upload error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isUpdating = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final newAvatarUrl = await _uploadAvatar();

      final updateData = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newAvatarUrl != null) updateData['avatar_url'] = newAvatarUrl;

      await supabase.from('profiles').update(updateData).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final avatarUrl = widget.initialData?['avatar_url']?.toString() ?? '';
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (widget.initialData?['full_name'] ?? 'T');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar picker
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.5), accentColor],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: cardColor,
                      child: _isUploadingPhoto
                          ? CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 2,
                            )
                          : CircleAvatar(
                              radius: 53,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (avatarUrl.isNotEmpty
                                            ? NetworkImage(avatarUrl)
                                            : null)
                                        as ImageProvider?,
                              backgroundColor: accentColor.withOpacity(0.12),
                              child:
                                  (_selectedImage == null && avatarUrl.isEmpty)
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'T',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    )
                                  : null,
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                Icons.photo_library_outlined,
                size: 15,
                color: accentColor,
              ),
              label: Text(
                'Change Photo',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildField(
              label: 'Full Name',
              controller: _nameController,
              accentColor: accentColor,
              isDark: isDark,
              icon: Icons.person_outline_rounded,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Username',
              controller: _usernameController,
              accentColor: accentColor,
              isDark: isDark,
              icon: Icons.alternate_email_rounded,
              hint: 'e.g. johndoe',
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Bio',
              controller: _bioController,
              accentColor: accentColor,
              isDark: isDark,
              icon: Icons.notes_rounded,
              hint: 'Tell something about yourself...',
              maxLines: 4,
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isUpdating ? null : _updateProfile,
                child: _isUpdating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required Color accentColor,
    required bool isDark,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 1.8),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
