// screens/agency/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ FOR kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../providers/theme_provider.dart';
import '../../../models/travel_agency_model.dart';
import '../../../services/agency_service.dart';

class EditProfileScreen extends StatefulWidget {
  final TravelAgency agency;

  const EditProfileScreen({
    super.key,
    required this.agency,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _agencyNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _agencyNameController =
        TextEditingController(text: widget.agency.agencyName);
    _ownerNameController =
        TextEditingController(text: widget.agency.ownerFullName);
    _emailController = TextEditingController(text: widget.agency.ownerEmail);
    _phoneController = TextEditingController(text: widget.agency.ownerPhone);
    _addressController =
        TextEditingController(text: widget.agency.officeAddress ?? '');
    _websiteController =
        TextEditingController(text: widget.agency.websiteUrl ?? '');
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
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

  Future<void> _saveProfile() async {
    if (_agencyNameController.text.isEmpty ||
        _ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final agencyService = Provider.of<AgencyService>(context, listen: false);

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await agencyService.uploadAgencyImage(_selectedImage!);
        if (imageUrl == null) {
          // Image upload failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${agencyService.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update profile
      final success = await agencyService.updateAgencyProfile(
        agencyName: _agencyNameController.text.trim(),
        ownerFullName: _ownerNameController.text.trim(),
        ownerEmail: _emailController.text.trim(),
        ownerPhone: _phoneController.text.trim(),
        officeAddress: _addressController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        imageUrl: imageUrl,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${agencyService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ✅ HELPER FUNCTION FOR PLATFORM-SPECIFIC IMAGE DISPLAY
  Widget _buildProfileImage(
      BuildContext context, bool isDark, Color accentColor) {
    // ✅ Web doesn't support Image.file(), use Icon instead
    if (kIsWeb) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(
            color: accentColor,
            width: 3,
          ),
        ),
        child: Icon(
          Icons.location_city,
          size: 60,
          color: accentColor,
        ),
      );
    }

    // ✅ Mobile: Show selected image or default icon
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: accentColor,
          width: 3,
        ),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(57),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              Icons.location_city,
              size: 60,
              color: accentColor,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: Column(
                children: [
                  // ✅ USE HELPER FUNCTION FOR PLATFORM-SPECIFIC IMAGE
                  _buildProfileImage(context, isDark, accentColor),
                  const SizedBox(height: 16),
                  // Upload Button
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? accentColor.withValues(alpha: 0.5)
                            : accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            kIsWeb ? 'Web Preview Only' : 'Change Photo',
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Section
            Text(
              'AGENCY INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            // Agency Name
            _buildTextField(
              label: 'Agency Name *',
              controller: _agencyNameController,
              isDark: isDark,
              icon: Icons.business,
            ),
            const SizedBox(height: 16),

            // Owner Name
            _buildTextField(
              label: 'Owner Full Name *',
              controller: _ownerNameController,
              isDark: isDark,
              icon: Icons.person,
            ),
            const SizedBox(height: 24),

            // Contact Information
            Text(
              'CONTACT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              label: 'Email *',
              controller: _emailController,
              isDark: isDark,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildTextField(
              label: 'Phone *',
              controller: _phoneController,
              isDark: isDark,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Business Information
            Text(
              'BUSINESS INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            // Address
            _buildTextField(
              label: 'Office Address',
              controller: _addressController,
              isDark: isDark,
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Website
            _buildTextField(
              label: 'Website URL',
              controller: _websiteController,
              isDark: isDark,
              icon: Icons.language,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black : Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white54 : Colors.grey[600],
              size: 20,
            ),
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white30 : Colors.grey[400]!,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
