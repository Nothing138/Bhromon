// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialize
  await Supabase.initialize(
    url: 'https://jlgdgltubmuqfaxnkkdc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsZ2RnbHR1Ym11cWZheG5ra2RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMTY1NjIsImV4cCI6MjA5MDc5MjU2Mn0.2FFI35fbEwErbPg4bwdxvIF1HfTcuvnXWRPLbl7z5HY',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const BhromonApp(),
    ),
  );
}

class BhromonApp extends StatelessWidget {
  const BhromonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // থিম প্রোভাইডার থেকে ডাটা নেওয়া হচ্ছে
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Bhromon',
      debugShowCheckedModeBanner: false,

      // ইউজার সিলেক্টেড থিম মোড (Light/Dark/System)
      themeMode: themeProvider.themeMode,

      // --- Light Theme ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.accentColor,
          primary: themeProvider.accentColor, // গ্লোবাল প্রাইমারি কালার
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(
          0xFFF8FAFC,
        ), // হালকা গ্রে ব্যাকগ্রাউন্ড
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        // বাটনের গ্লোবাল স্টাইল
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // --- Dark Theme ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.accentColor,
          primary: themeProvider.accentColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(
          0xFF0F172A,
        ), // আপনার সিগনেচার ডার্ক ব্লু
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // রাউট ম্যানেজমেন্ট
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainWrapper(),
      },
    );
  }
}
