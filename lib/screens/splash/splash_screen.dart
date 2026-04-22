// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Logo dekhanor jonno chotto ekta delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Supabase theke current session check kora
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User login thakle shorasori Home Screen-e
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Login na thakle Login Screen-e
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ekta shundor Travel Icon
            const Icon(Icons.travel_explore, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Bhromon',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
