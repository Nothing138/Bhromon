// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // লোগোর জন্য একটি সিম্পল ফেড-ইন অ্যানিমেশন
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    // লোগো দেখানোর জন্য এবং অ্যানিমেশন শেষ করার জন্য ৩ সেকেন্ড অপেক্ষা
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // থিম ডাটা সংগ্রহ (সিস্টেম ডিফল্ট বা লাস্ট সেভ করা থিম অনুযায়ী)
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      // ডার্ক মোডে আপনার অ্যাপের সিগনেচার ডার্ক ব্লু
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ট্রাভেল আইকনটি এখন ডাইনামিক অ্যাকসেন্ট কালার নেবে
              Icon(Icons.travel_explore_rounded, size: 120, color: accentColor),
              const SizedBox(height: 10),
              Text(
                'Bhromon',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your Ultimate Travel Partner',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              CircularProgressIndicator(color: accentColor, strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }
}
