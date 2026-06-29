// screens/auth/password_reset_screen.dart
// screens/auth/password_reset_screen.dart - UPDATED WITH TOKEN-BASED RESET
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //  Step 1: Request Password Reset
  Future<void> _handleResetRequest() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your email address');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.requestPasswordReset(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _emailSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Password reset email has been sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  //  Step 2: Verify Token & Reset Password
  Future<void> _handlePasswordReset() async {
    if (_tokenController.text.isEmpty) {
      _showErrorDialog('Please enter the reset code from your email');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorDialog('Please enter a new password');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPasswordWithToken(
        email: _emailController.text.trim(),
        resetToken: _tokenController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      _showSuccessDialog(
        'Password Reset Successful',
        'Your password has been updated. You can now login with your new password.',
        () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractErrorMessage(String error) {
    if (error.contains('Token expired')) {
      return 'Reset token has expired. Please request a new reset email.';
    } else if (error.contains('Invalid token')) {
      return 'Invalid reset code. Please check your email and try again.';
    } else if (error.contains('Token not found')) {
      return 'Reset code not found. Please request a new reset email.';
    }
    return error
        .replaceAll('Exception: ', '')
        .replaceAll('Password reset error: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(' Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onConfirm,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeProvider.accentColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.lock_reset_outlined,
                  size: 40,
                  color: themeProvider.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Title
            Center(
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Subtitle
            Center(
              child: Text(
                _emailSent
                    ? 'Check your email for the reset code and enter your new password'
                    : 'Enter your email to receive a password reset code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (!_emailSent) ...[
              //  STEP 1: EMAIL VERIFICATION
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: themeProvider.accentColor,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.accentColor,
                      width: 2,
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              // Info Box
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: themeProvider.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter the email associated with your account. We\'ll send you a reset code that you can use to set a new password.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: themeProvider.accentColor,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handleResetRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Reset Code',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ] else ...[
              //  STEP 2: PASSWORD RESET WITH TOKEN
              Text(
                'Reset Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tokenController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Enter code from your email',
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: themeProvider.accentColor,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.accentColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                enabled: !_isLoading,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: themeProvider.accentColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _showNewPassword = !_showNewPassword);
                    },
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: themeProvider.accentColor,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.accentColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: themeProvider.accentColor,
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
                      color: themeProvider.accentColor,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.accentColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Info Box
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Password must be at least 6 characters and both passwords must match.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: themeProvider.accentColor,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handlePasswordReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 15),

              // Back to Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: themeProvider.accentColor,
                    side: BorderSide(
                      color: themeProvider.accentColor,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
