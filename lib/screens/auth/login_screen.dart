// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';
import 'otp_verification_screen.dart';
import '../main_wrapper.dart';
import '../agency/agency_main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      print('Attempting login...');
      await authService.smartLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      print('Login successful');
      print('User Type: ${authService.userType}');
      print('Is Agency: ${authService.isAgency}');
      print('Is OTP Required: ${authService.isOtpRequired}');

      // SMART ROUTING BASED ON USER TYPE
      if (authService.isOtpRequired) {
        // Agency needs OTP verification
        // OTP screen এ যাওয়ার সময় pushReplacement ঠিক আছে
        // কারণ OTP verify হলে সেখান থেকে stack clear করা হবে
        print('→ Routing to OTP Verification Screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      } else if (authService.isAgency) {
        // ✅ Agency user — পুরো stack clear করে AgencyMainWrapper এ যাও
        print('→ Routing to AgencyMainWrapper');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/agency',
          (route) => false,
        );
      } else {
        // ✅ Regular user — পুরো stack clear করে MainWrapper এ যাও
        print('→ Routing to MainWrapper');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
        );
      }
    } catch (e) {
      print('Login error: $e');
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('not approved')) {
      return 'Your agency is not approved yet. Please wait for admin approval.';
    } else if (error.contains('not confirmed')) {
      return 'Please verify your email first';
    }
    return error.replaceAll('Exception: ', '').replaceAll('Login error: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeProvider.accentColor,
                    themeProvider.accentColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bhromon',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Travel. Connect. Explore.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Login Form
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Login as User or Travel Agency',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
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
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: themeProvider.accentColor,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(
                          _showPassword
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

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PasswordResetScreen(),
                                ),
                              ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: themeProvider.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button
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
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[400],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[400],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Options
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
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
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
