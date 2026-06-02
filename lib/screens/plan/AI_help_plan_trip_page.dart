// screens/plan/AI_help_plan_trip_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'ai_suggestion_screen.dart';

class AITripPage extends StatefulWidget {
  const AITripPage({super.key});

  @override
  State<AITripPage> createState() => _AITripPageState();
}

class _AITripPageState extends State<AITripPage> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedDate;
  int _days = 3;
  bool _isLoading = false;
  String _selectedStyle = 'Adventure';
  bool _useAI = true;

  final List<Map<String, dynamic>> _travelStyles = [
    {'label': 'Adventure', 'icon': Icons.terrain_outlined},
    {'label': 'Relax', 'icon': Icons.spa_outlined},
    {'label': 'Budget', 'icon': Icons.savings_outlined},
    {'label': 'Luxury', 'icon': Icons.diamond_outlined},
    {'label': 'Family', 'icon': Icons.family_restroom_outlined},
    {'label': 'Solo', 'icon': Icons.person_outline_rounded},
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(Color accentColor) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Theme.of(context).brightness,
            primary: accentColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTrip() async {
    final destination = _destinationController.text.trim();
    final budgetText = _budgetController.text.trim();

    if (destination.isEmpty || budgetText.isEmpty || _selectedDate == null) {
      _showSnackBar('Please fill in all fields', Colors.redAccent);
      return;
    }

    final int? budget = int.tryParse(budgetText);
    if (budget == null) {
      _showSnackBar('Enter a valid budget amount', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('trips').insert({
        'user_id': user!.id,
        'destination': destination,
        'budget': budget,
        'start_date': _selectedDate!.toIso8601String(),
        'duration_days': _days,
        'travel_style': _selectedStyle,
        'use_ai': _useAI,
      });

      if (mounted) {
        if (_useAI) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AISuggestionScreen(
                destination: destination,
                budget: budget,
                days: _days,
                style: _selectedStyle,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
          _showSnackBar('Trip plan created successfully', Colors.green);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F4)
        : const Color(0xFF0D1117);
    final textSecondary = isDark
        ? const Color(0xFF4A5478)
        : const Color(0xFF8892A4);

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
            'Plan a new trip',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill in your trip details and let AI craft a perfect itinerary for you.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7A9F)
                            : const Color(0xFF4A5478),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildLabel('Destination', Icons.map_outlined, accentColor),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _destinationController,
              hint: 'e.g. Sajek, Cox\'s Bazar, Sylhet...',
              icon: Icons.location_on_outlined,
              accentColor: accentColor,
              isDark: isDark,
              surface: surface,
              surfaceBorder: surfaceBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 22),

            _buildLabel(
              'Budget (BDT)',
              Icons.account_balance_wallet_outlined,
              accentColor,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _budgetController,
              hint: 'e.g. 5000',
              icon: Icons.currency_exchange_rounded,
              accentColor: accentColor,
              isDark: isDark,
              surface: surface,
              surfaceBorder: surfaceBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isNumber: true,
            ),
            const SizedBox(height: 22),

            _buildLabel('Start date', Icons.event_outlined, accentColor),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _pickDate(accentColor),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: surfaceBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: accentColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Select start date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? textSecondary
                            : textPrimary,
                        fontSize: 14,
                        fontWeight: _selectedDate == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            _buildLabel('Duration', Icons.timer_outlined, accentColor),
            const SizedBox(height: 10),
            _buildDurationPicker(
              accentColor,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 22),

            _buildLabel('Travel style', Icons.style_outlined, accentColor),
            const SizedBox(height: 12),
            _buildStylePicker(
              accentColor,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 22),

            // AI Toggle
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
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: accentColor.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI suggestions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generate smart itinerary with Groq AI',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useAI,
                    onChanged: (val) => setState(() => _useAI = val),
                    activeColor: accentColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isLoading ? null : _saveTrip,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _useAI
                                ? Icons.auto_awesome_outlined
                                : Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _useAI ? 'Create with AI' : 'Create plan',
                            style: const TextStyle(
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
      ),
    );
  }

  Widget _buildLabel(String label, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 15),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color surface,
    required Color surfaceBorder,
    required Color textPrimary,
    required Color textSecondary,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: textPrimary, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(11),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accentColor, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPicker(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleBtn(
            Icons.remove_rounded,
            () => setState(() {
              if (_days > 1) _days--;
            }),
            textSecondary.withOpacity(0.15),
            textSecondary,
          ),
          const SizedBox(width: 28),
          Column(
            children: [
              Text(
                '$_days',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: -1,
                ),
              ),
              Text(
                _days == 1 ? 'day' : 'days',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 28),
          _circleBtn(
            Icons.add_rounded,
            () => setState(() => _days++),
            accentColor.withOpacity(0.1),
            accentColor,
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap,
    Color bg,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildStylePicker(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _travelStyles.map((style) {
        final isSelected = _selectedStyle == style['label'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedStyle = style['label'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.1) : surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accentColor.withOpacity(0.35)
                    : surfaceBorder,
                width: isSelected ? 1 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  style['icon'] as IconData,
                  size: 15,
                  color: isSelected ? accentColor : textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  style['label'] as String,
                  style: TextStyle(
                    color: isSelected ? accentColor : textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
