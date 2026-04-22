// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jlgdgltubmuqfaxnkkdc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsZ2RnbHR1Ym11cWZheG5ra2RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMTY1NjIsImV4cCI6MjA5MDc5MjU2Mn0.2FFI35fbEwErbPg4bwdxvIF1HfTcuvnXWRPLbl7z5HY',
  );

  runApp(const BhromonApp());
}

class BhromonApp extends StatelessWidget {
  const BhromonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhromon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // App shuru hobe Splash Screen diye
    );
  }
}
