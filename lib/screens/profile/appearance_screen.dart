// screens/profile/appearance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // বর্তমান থিমের টেক্সট কালার
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // ডার্ক মোডে আপনার পছন্দের গাঢ় নীল শেডটি ব্যবহার করা হয়েছে
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: isDark ? null : Border.all(color: Colors.grey[200]!),
            ),
            child: SwitchListTile(
              secondary: Icon(
                Icons.dark_mode_rounded,
                color: themeProvider.accentColor,
              ),
              title: Text(
                "Dark Mode",
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "Easier on the eyes in low light",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
              activeThumbColor: themeProvider.accentColor,
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
          ),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: isDark ? null : Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              leading: Icon(
                Icons.color_lens_rounded,
                color: themeProvider.accentColor,
              ),
              title: Text(
                "Color Palette",
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text("Select your brand color"),
              trailing: SizedBox(
                width: 150, // Wrap এর জন্য জায়গা নির্দিষ্ট করা হয়েছে
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _colorOption(
                      context,
                      themeProvider,
                      const Color(0xFFF4B400),
                    ), // Gold
                    _colorOption(
                      context,
                      themeProvider,
                      const Color(0xFF00B4D8),
                    ), // Sky Blue
                    _colorOption(
                      context,
                      themeProvider,
                      const Color(0xFFE91E63),
                    ), // Pink/Red
                    _colorOption(
                      context,
                      themeProvider,
                      const Color(0xFF4CAF50),
                    ), // Green
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(
    BuildContext context,
    ThemeProvider provider,
    Color color,
  ) {
    bool isSelected = provider.accentColor.value == color.value;
    return GestureDetector(
      onTap: () => provider.updateAccentColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
