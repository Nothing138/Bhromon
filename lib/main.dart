// main.dart
// main.dart - CORRECTED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';
import 'services/event_service.dart';
import 'services/agency_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/agency/agency_main_wrapper.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Supabase Initialize
  await Supabase.initialize(
    url: 'https://jlgdgltubmuqfaxnkkdc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsZ2RnbHR1Ym11cWZheG5ra2RjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTIxNjU2MiwiZXhwIjoyMDkwNzkyNTYyfQ.jnBUv0GKrWNqGdmNYVmR9oYUmkFJ5ZZPnPLjwi59U9M',
  );

  // Initialize ThemeProvider before running app
  final themeProvider = ThemeProvider();
  await themeProvider.initializeTheme();

  runApp(
    MultiProvider(
      providers: [
        // Theme Provider with initialized values
        ChangeNotifierProvider.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider(
          create: (context) => EventService(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AgencyService(),
        ),
      ],
      child: const BhromonApp(),
    ),
  );
}

class BhromonApp extends StatelessWidget {
  const BhromonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Bhromon',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // --- Light Theme (DEFAULT) ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.accentColor,
          primary: themeProvider.accentColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(themeProvider.accentColor),
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(themeProvider.accentColor),
        ),
      ),

      // ========================================
      //  CORRECTED: SplashScreen as initial
      // ========================================
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), //  Initial route
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainWrapper(),
        '/agency': (context) => const AgencyMainWrapper(),
      },
    );
  }
}
