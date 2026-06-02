// screens/profile/privacy_security_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final supabase = Supabase.instance.client;
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isChangingPassword = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.isEmpty) {
      _snack('New password cannot be empty', Colors.orange);
      return;
    }
    if (newPass.length < 8) {
      _snack('Password must be at least 8 characters', Colors.orange);
      return;
    }
    if (newPass != confirmPass) {
      _snack('Passwords do not match', Colors.redAccent);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPass));
      _newPassController.clear();
      _confirmPassController.clear();
      _snack('Password updated successfully! ✓', Colors.green);
    } on AuthException catch (e) {
      _snack(e.message, Colors.redAccent);
    } catch (e) {
      _snack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Step 1 — first dialog
    final step1 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (step1 != true) return;

    // Step 2 — type DELETE
    final step2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setS) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Type DELETE to confirm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: TextField(
                controller: ctrl,
                onChanged: (_) => setS(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctrl.text == 'DELETE'
                        ? Colors.red
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: ctrl.text == 'DELETE'
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (step2 != true) return;

    try {
      final userId = supabase.auth.currentUser!.id;
      // নিজের data delete করো (RLS allow করলে)
      try {
        await supabase.from('bookings').delete().eq('user_id', userId);
      } catch (_) {}
      try {
        await supabase.from('favorites').delete().eq('user_id', userId);
      } catch (_) {}
      try {
        await supabase.from('posts').delete().eq('user_id', userId);
      } catch (_) {}
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      _snack('Failed: $e', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    const green = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Change Password ──
            _label('CHANGE PASSWORD', isDark),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _card(cardColor, isDark),
              child: Column(
                children: [
                  _passField(
                    controller: _newPassController,
                    label: 'New Password',
                    hint: 'Minimum 8 characters',
                    isVisible: _showNewPass,
                    onToggle: () =>
                        setState(() => _showNewPass = !_showNewPass),
                    accentColor: green,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _passField(
                    controller: _confirmPassController,
                    label: 'Confirm New Password',
                    hint: 'Re-enter password',
                    isVisible: _showConfirmPass,
                    onToggle: () =>
                        setState(() => _showConfirmPass = !_showConfirmPass),
                    accentColor: green,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isChangingPassword ? null : _changePassword,
                      icon: _isChangingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        _isChangingPassword ? 'Updating...' : 'Update Password',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Privacy Info ──
            _label('PRIVACY', isDark),
            const SizedBox(height: 10),
            Container(
              decoration: _card(cardColor, isDark),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'Profile Visibility',
                    subtitle: 'Only friends can see your profile',
                    color: accentColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white10 : Colors.grey[100],
                  ),
                  _infoTile(
                    icon: Icons.location_off_outlined,
                    title: 'Location Sharing',
                    subtitle: 'Shared only during active SOS alerts',
                    color: accentColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Danger Zone ──
            _label('DANGER ZONE', isDark),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Permanently remove all your data',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onTap: _confirmDeleteAccount,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      color: isDark ? Colors.white38 : Colors.grey[400],
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  );

  BoxDecoration _card(Color cardColor, bool isDark) => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.25)
            : Colors.black.withOpacity(0.04),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _passField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required Color accentColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey[400],
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: accentColor,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white38 : Colors.grey[400],
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 1.8),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
