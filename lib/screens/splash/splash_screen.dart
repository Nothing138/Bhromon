// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../main_wrapper.dart';
import '../agency/agency_main_wrapper.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _redirect();
  }

  void _initializeAnimations() {
    // ==========================================
    // ICON ANIMATION (Scale + Fade)
    // ==========================================
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeIn),
    );

    // ==========================================
    // TEXT ANIMATION (Slide + Fade)
    // ==========================================
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // ==========================================
    // LOADER ANIMATION (Continuous rotation)
    // ==========================================
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Start animations with stagger
    _iconController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.checkAuthStatus();

      if (!mounted) return;

      if (authService.isAuthenticated) {
        if (authService.isAgency) {
          // ✅ Agency user — পুরো stack clear করে AgencyMainWrapper এ যাও
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/agency',
            (route) => false,
          );
        } else if (authService.isUser) {
          // ✅ Regular user — পুরো stack clear করে MainWrapper এ যাও
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
          );
        } else {
          // Fallback
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } else {
        // Not authenticated
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Redirect error: $e');
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    // Background colors
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final gradientColor1 =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final gradientColor2 = isDark
        ? accentColor.withValues(alpha: 0.1)
        : accentColor.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColor1,
              gradientColor2,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==========================================
                // ANIMATED ICON WITH SCALE + FADE
                // ==========================================
                FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: 80,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // ANIMATED TITLE TEXT (Slide + Fade)
                // ==========================================
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'Bhromon',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 3.5,
                        shadows: [
                          Shadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==========================================
                // ANIMATED SUBTITLE
                // ==========================================
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Your Ultimate Travel Partner',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // ==========================================
                // CUSTOM ANIMATED LOADER
                // ==========================================
                _buildCustomLoader(accentColor, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CUSTOM CIRCULAR LOADER WITH GLOW
  // ==========================================
  Widget _buildCustomLoader(Color accentColor, bool isDark) {
    return AnimatedBuilder(
      animation: _loaderController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating circle (glow effect)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha:
                          0.3 + (0.2 * (1 - (_loaderController.value % 1.0))),
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Rotating border
            Transform.rotate(
              angle: _loaderController.value * 6.28,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Rotating progress indicator
            Transform.rotate(
              angle: _loaderController.value * 6.28,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border(
                    top: BorderSide(
                      color: accentColor,
                      width: 3,
                    ),
                    right: BorderSide(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 3,
                    ),
                    bottom: BorderSide(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 3,
                    ),
                    left: BorderSide(
                      color: accentColor.withValues(alpha: 0.1),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            // Center dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
