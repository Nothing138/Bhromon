// main.dart
// main.dart - UPDATED WITH LOGOUT FIX
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';
import 'services/event_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/agency/agency_main_wrapper.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Supabase Initialize
  await Supabase.initialize(
    url: 'https://jlgdgltubmuqfaxnkkdc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsZ2RnbHR1Ym11cWZheG5ra2RjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTIxNjU2MiwiZXhwIjoyMDkwNzkyNTYyfQ.jnBUv0GKrWNqGdmNYVmR9oYUmkFJ5ZZPnPLjwi59U9M',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
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

      // --- Light Theme ---
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
          foregroundColor: Colors.black,
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

      initialRoute: '/',
      routes: {
        '/': (context) =>
            const AuthWrapper(), // ✅ CHANGED: Use AuthWrapper instead of SplashScreen
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainWrapper(),
      },
    );
  }
}

// ✅ NEW: Auth Navigation Wrapper - Handles all routing based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // If explicitly logged out is not provided by AuthService, rely on isAuthenticated

        // Not authenticated - show login
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }

        // OTP verification required - show OTP screen
        if (authService.isOtpRequired) {
          // Navigate to OTP screen instead of splash
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/otp',
              (route) => false,
            );
          });
          return const SplashScreen();
        }

        // ✅ Authenticated: Route based on user type
        if (authService.isAgency) {
          return const AgencyMainWrapper();
        } else if (authService.isUser) {
          return const MainWrapper();
        }

        // Default splash while loading
        return const SplashScreen();
      },
    );
  }
}
