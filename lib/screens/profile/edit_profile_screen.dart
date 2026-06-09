// screens/profile/edit_profile_screen.dart
import 'dart:io';
import 'dart:typed_data';
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

  // Store as XFile so we avoid File/_Namespace issues on all platforms
  XFile? _selectedXFile;
  String _currentAvatarUrl = '';

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialData?['full_name'] ?? '';
    _usernameController.text = widget.initialData?['username'] ?? '';
    _bioController.text = widget.initialData?['bio'] ?? '';
    _currentAvatarUrl = widget.initialData?['avatar_url']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Image Picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked != null && mounted) {
        setState(() => _selectedXFile = picked);
        debugPrint('📷 Image picked: ${picked.path}');
      }
    } catch (e) {
      debugPrint('❌ Image pick error: $e');
      if (mounted) {
        _showSnack(
            'Could not open gallery. Check app permissions.', Colors.orange);
      }
    }
  }

  // ── Upload Avatar ──────────────────────────────────────────────────────────
  Future<String?> _uploadAvatar() async {
    if (_selectedXFile == null) return null;
    setState(() => _isUploadingPhoto = true);

    try {
      final user = supabase.auth.currentUser!;

      // Read as bytes — works on Android, iOS, and Web (no _Namespace issue)
      final Uint8List bytes = await _selectedXFile!.readAsBytes();

      // Determine extension from file path
      final String ext = _selectedXFile!.path.split('.').last.toLowerCase();
      final String mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      // Use a fixed path per user so it always overwrites
      final String storagePath = '${user.id}/avatar.$ext';

      debugPrint('📤 Uploading ${bytes.length} bytes to avatars/$storagePath');

      // uploadBinary with Uint8List — most compatible across Supabase versions
      await supabase.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      // Get public URL and add cache-buster so image refreshes immediately
      final String publicUrl =
          supabase.storage.from('avatars').getPublicUrl(storagePath);
      final String finalUrl =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('✅ Upload success. URL: $finalUrl');
      return finalUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        _showSnack('Photo upload failed: $e', Colors.redAccent);
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _showSnack('Name cannot be empty', Colors.orange);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      // Check username uniqueness
      if (username.isNotEmpty &&
          username != (widget.initialData?['username'] ?? '')) {
        final existing = await supabase
            .from('profiles')
            .select('id')
            .eq('username', username)
            .neq('id', userId)
            .maybeSingle();

        if (existing != null) {
          _showSnack('Username "@$username" is already taken.', Colors.orange);
          return;
        }
      }

      // Upload new avatar if selected
      final String? newAvatarUrl = await _uploadAvatar();

      final updateData = <String, dynamic>{
        'full_name': name,
        'username': username.isEmpty ? null : username,
        'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newAvatarUrl != null) {
        updateData['avatar_url'] = newAvatarUrl;
        if (mounted) setState(() => _currentAvatarUrl = newAvatarUrl);
      }

      debugPrint('🔄 Updating profile: $updateData');

      await supabase.from('profiles').update(updateData).eq('id', userId);

      debugPrint('✅ Profile update done');

      if (mounted) {
        Navigator.pop(context, true);
        _showSnack('Profile updated successfully!', Colors.green);
      }
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase DB error [${e.code}]: ${e.message}');
      final msg = e.code == '23505'
          ? 'Username already taken.'
          : e.code == '42501'
              ? 'Permission denied. Log out and back in.'
              : 'DB error: ${e.message}';
      if (mounted) _showSnack(msg, Colors.redAccent);
    } catch (e) {
      debugPrint('❌ General error: $e');
      if (mounted) _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  ImageProvider? _avatarProvider() {
    if (_selectedXFile != null) return FileImage(File(_selectedXFile!.path));
    if (_currentAvatarUrl.isNotEmpty) return NetworkImage(_currentAvatarUrl);
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (widget.initialData?['full_name'] ?? 'U');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Edit Profile',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 19)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar picker ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        accentColor.withOpacity(0.5),
                        accentColor,
                      ]),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: cardColor,
                      child: _isUploadingPhoto
                          ? CircularProgressIndicator(
                              color: accentColor, strokeWidth: 2)
                          : CircleAvatar(
                              radius: 53,
                              backgroundImage: _avatarProvider(),
                              backgroundColor: accentColor.withOpacity(0.12),
                              child: _avatarProvider() == null
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'U',
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
                              blurRadius: 10)
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library_outlined,
                  size: 15, color: accentColor),
              label: Text('Change Photo',
                  style: TextStyle(
                      color: accentColor, fontWeight: FontWeight.w600)),
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
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isUpdating ? null : _updateProfile,
                child: _isUpdating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
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
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey[400],
                fontSize: 14),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            filled: true,
            fillColor: cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[200]!),
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
