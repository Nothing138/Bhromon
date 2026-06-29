// screens/plan/ai_suggestion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ai_service.dart';

class AISuggestionScreen extends StatefulWidget {
  final String destination;
  final int budget;
  final int days;
  final String style;

  const AISuggestionScreen({
    super.key,
    required this.destination,
    required this.budget,
    required this.days,
    required this.style,
  });

  @override
  State<AISuggestionScreen> createState() => _AISuggestionScreenState();
}

class _AISuggestionScreenState extends State<AISuggestionScreen>
    with SingleTickerProviderStateMixin {
  late Future<String> _aiResponse;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadResponse();
  }

  void _loadResponse() {
    _aiResponse = AIService.generateItinerary(
      destination: widget.destination,
      budget: widget.budget,
      days: widget.days,
      style: widget.style,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<Widget> _parseItinerary(
    String text,
    bool isDark,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final heading = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    heading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
        final bold = trimmed.replaceAll('**', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              bold,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        final bullet = trimmed.replaceFirst(RegExp(r'^[-•]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark
                          ? const Color(0xFF8B96B8)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color:
                    isDark ? const Color(0xFF6B7A9F) : const Color(0xFF334155),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded, color: accentColor, size: 18),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'AI itinerary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _aiResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_outlined,
                            color: accentColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Crafting your itinerary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyzing ${widget.destination} for ${widget.days} days...',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    LinearProgressIndicator(
                      color: accentColor,
                      backgroundColor: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_outlined,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection error',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _loadResponse()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Try again',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final responseText = snapshot.data ?? 'No suggestions found.';
          final isError =
              responseText.startsWith('') || responseText.startsWith('⏳');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips row
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip(
                      Icons.location_on_outlined,
                      widget.destination,
                      accentColor,
                    ),
                    _buildChip(
                      Icons.timer_outlined,
                      '${widget.days} days',
                      Colors.orange,
                    ),
                    _buildChip(
                      Icons.style_outlined,
                      widget.style,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Budget card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: surfaceBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total budget',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            '৳${widget.budget} BDT',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              color: accentColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI plan',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Itinerary header
                Row(
                  children: [
                    Icon(Icons.route_outlined, color: accentColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested itinerary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Response content
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: surfaceBorder, width: 0.5),
                  ),
                  child: isError
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                responseText.replaceFirst(' ', ''),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _parseItinerary(
                            responseText,
                            isDark,
                            accentColor,
                            textPrimary,
                            textSecondary,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                if (isError)
                  GestureDetector(
                    onTap: () => setState(() => _loadResponse()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Try again',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Done button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
