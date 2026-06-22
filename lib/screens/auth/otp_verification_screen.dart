// screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../main_wrapper.dart';
import '../agency/agency_main_wrapper.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 30;
  late Timer _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _canResend = false;
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown == 0) {
            _canResend = true;
            _resendTimer.cancel();
          }
        });
      }
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode = _getOtpCode();

    if (otpCode.length != 6 || otpCode.contains(' ')) {
      _showErrorDialog('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      print('🔄 Verifying OTP: $otpCode');
      await authService.verifyOtp(otpCode: otpCode);

      if (!mounted) return;

      print('✅ OTP verified successfully');

      // ✅ Show success dialog then navigate to login screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✅ Verification Successful!'),
          content: const Text(
            'Your email has been verified successfully.\n\n'
            'You can now log in with your credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // ✅ Navigate to Login Screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ OTP verification error: $e');
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      print('🔄 Resending OTP...');
      await authService.resendOtp();

      if (!mounted) return;

      print('✅ OTP resent successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has been resent to your email'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }

      _startResendTimer();
    } catch (e) {
      print('❌ Resend OTP error: $e');
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractErrorMessage(String error) {
    return error
        .replaceAll('Exception: ', '')
        .replaceAll('OTP verification error: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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
    final authService = Provider.of<AuthService>(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent going back
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Header Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 40,
                  color: themeProvider.accentColor,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.accentColor,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'We\'ve sent a 6-digit code to your registered email address. Please enter it below to verify your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),

              // Agency Email Display
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: themeProvider.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Code sent to: ${authService.currentAgency?.ownerEmail ?? "your email"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 50,
                    height: 60,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
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
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Verify Button
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
                        onPressed: _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Resend OTP
              Column(
                children: [
                  const Text(
                    'Didn\'t receive the code?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_canResend)
                    TextButton(
                      onPressed: _isLoading ? null : _handleResendOtp,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: themeProvider.accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
