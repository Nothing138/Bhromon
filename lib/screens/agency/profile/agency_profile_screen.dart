// screens/agency/profile/agency_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'appearance_settings_screen.dart';

class AgencyProfileScreen extends StatefulWidget {
  const AgencyProfileScreen({super.key});

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final authService = Provider.of<AuthService>(context);
    final agency = authService.currentAgency;
    final accentColor = themeProvider.accentColor;

    if (agency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Agency not found')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: accentColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 50,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Agency Name
                  Text(
                    agency.agencyName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Owner Name
                  Text(
                    agency.ownerFullName,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Verification Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          agency.verificationStatus == 'approved'
                              ? '✓ Verified'
                              : '⏳ ${agency.verificationStatus}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Settings & Preferences Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS & PREFERENCES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Edit Profile
                  _buildSettingsCard(
                    icon: Icons.person_outline,
                    iconColor: Colors.amber,
                    title: 'Edit Profile',
                    subtitle: 'Name, bio & photo',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(agency: agency),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Appearance
                  _buildSettingsCard(
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    title: 'Appearance',
                    subtitle: 'Theme & dark mode',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppearanceSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Notifications
                  _buildSettingsCard(
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.orange,
                    title: 'Notifications',
                    subtitle: 'Alerts & messages',
                    isDark: isDark,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications settings coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Privacy & Security
                  _buildSettingsCard(
                    icon: Icons.lock_outline,
                    iconColor: Colors.teal,
                    title: 'Privacy & Security',
                    subtitle: 'Password & account',
                    isDark: isDark,
                    onTap: () {
                      _showChangePasswordDialog(context, themeProvider);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Business Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUSINESS INFORMATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoContainer(
                    label: 'Email',
                    value: agency.ownerEmail,
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoContainer(
                    label: 'Phone',
                    value: agency.ownerPhone,
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoContainer(
                    label: 'Office Address',
                    value: agency.officeAddress ?? 'Not provided',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoContainer(
                    label: 'License Number',
                    value: agency.businessLicenseNumber ?? 'Not provided',
                    icon: Icons.card_membership_outlined,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Show Change Password Dialog
  void _showChangePasswordDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // ✅ IMPORTANT: Get AuthService BEFORE opening dialog
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(
        isDark: isDark,
        themeProvider: themeProvider,
        currentPasswordController: currentPasswordController,
        newPasswordController: newPasswordController,
        confirmPasswordController: confirmPasswordController,
        authService: authService,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

// ============================================
// ✅ SEPARATE STATEFUL WIDGET FOR DIALOG
// ============================================
class _ChangePasswordDialog extends StatefulWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final AuthService authService;

  const _ChangePasswordDialog({
    required this.isDark,
    required this.themeProvider,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.authService,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    widget.currentPasswordController.dispose();
    widget.newPasswordController.dispose();
    widget.confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    setState(() => _isLoading = true);

    try {
      await widget.authService.changePassword(
        currentPassword: widget.currentPasswordController.text.trim(),
        newPassword: widget.newPasswordController.text.trim(),
        confirmPassword: widget.confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Password changed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      if (errorMessage.contains('Current password')) {
        errorMessage = 'Current password is incorrect';
      } else if (errorMessage.contains('not match')) {
        errorMessage = 'New passwords do not match';
      } else if (errorMessage.contains('at least 6')) {
        errorMessage = 'Password must be at least 6 characters';
      } else if (errorMessage.contains('No active session')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (errorMessage.contains('Invalid or expired token')) {
        errorMessage = 'Your session has expired. Please login again.';
      } else {
        errorMessage = errorMessage
            .replaceAll('Exception: ', '')
            .replaceAll('Change password error: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        'Change Password',
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Current Password
            TextField(
              controller: widget.currentPasswordController,
              enabled: !_isLoading,
              obscureText: !_showCurrentPassword,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.grey[600],
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                        () => _showCurrentPassword = !_showCurrentPassword);
                  },
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.themeProvider.accentColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor:
                    widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ New Password
            TextField(
              controller: widget.newPasswordController,
              enabled: !_isLoading,
              obscureText: !_showNewPassword,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.grey[600],
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _showNewPassword = !_showNewPassword);
                  },
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.themeProvider.accentColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor:
                    widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Confirm Password
            TextField(
              controller: widget.confirmPasswordController,
              enabled: !_isLoading,
              obscureText: !_showConfirmPassword,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.grey[600],
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                        () => _showConfirmPassword = !_showConfirmPassword);
                  },
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white10 : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.themeProvider.accentColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor:
                    widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password must be at least 6 characters and both passwords must match.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeProvider.accentColor,
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : const Text(
                  'Update Password',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
