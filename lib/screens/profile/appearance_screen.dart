// screens/profile/appearance_screen.dart
// screens/profile/appearance_screen.dart (USER VERSION)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Appearance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================
            // THEME MODE SECTION
            // ========================
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                "THEME MODE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(15),
                border: isDark ? null : Border.all(color: Colors.grey[200]!),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: themeProvider.accentColor,
                  size: 24,
                ),
                title: Text(
                  isDark ? "Dark Mode" : "Light Mode",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  isDark
                      ? "Currently in dark mode"
                      : "Currently in light mode (default)",
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                activeThumbColor: themeProvider.accentColor,
                inactiveThumbColor: Colors.grey,
                value: themeProvider.isDarkMode,
                onChanged: (val) async {
                  await themeProvider.toggleTheme(val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? '🌙 Dark Mode Enabled'
                              : '☀️ Light Mode Enabled',
                        ),
                        backgroundColor: themeProvider.accentColor,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // ========================
            // ACCENT COLORS SECTION
            // ========================
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(
                "ACCENT COLORS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(15),
                border: isDark ? null : Border.all(color: Colors.grey[200]!),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.color_lens_rounded,
                        color: themeProvider.accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Color Palette",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "Select your brand color",
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFFF4B400),
                        "Gold",
                      ),
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFF00B4D8),
                        "Sky Blue",
                      ),
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFFE91E63),
                        "Pink",
                      ),
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFF4CAF50),
                        "Green",
                      ),
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFF9C27B0),
                        "Purple",
                      ),
                      _colorOption(
                        context,
                        themeProvider,
                        const Color(0xFFFF5722),
                        "Orange",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ========================
            // RESET BUTTON
            // ========================
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _showResetDialog(context, themeProvider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: themeProvider.accentColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Reset to Default",
                    style: TextStyle(
                      color: themeProvider.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(
    BuildContext context,
    ThemeProvider provider,
    Color color,
    String label,
  ) {
    bool isSelected = provider.accentColor.value == color.value;

    return GestureDetector(
      onTap: () async {
        await provider.updateAccentColor(color);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Color changed to $label'),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 24, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    ThemeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Theme"),
        content: const Text(
          "Reset to light mode and gold color?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await provider.resetToDefaults();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("✓ Theme reset to defaults"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Reset",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
