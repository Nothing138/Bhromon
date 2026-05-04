// screens/plan/plan_trip_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'ai_suggestion_screen.dart';

class PlanTripPage extends StatefulWidget {
  const PlanTripPage({super.key});

  @override
  State<PlanTripPage> createState() => _PlanTripPageState();
}

class _PlanTripPageState extends State<PlanTripPage> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedDate;
  int _days = 3;
  bool _isLoading = false;

  // AI এবং নতুন ডিটেইলস এর জন্য ভেরিয়েবল
  String _selectedStyle = "Adventure";
  bool _useAI = false;

  final List<String> _travelStyles = [
    "Adventure",
    "Relax",
    "Budget",
    "Luxury",
    "Family",
    "Solo",
  ];

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
      _showSnackBar("Please fill all fields", Colors.red);
      return;
    }

    final int budget = int.parse(budgetText);

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      // ডাটাবেসে সেভ করা হচ্ছে
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
          // যদি AI টগল অন থাকে, তবে সরাসরি সাজেশন স্ক্রিনে নিয়ে যাবে
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AISuggestionScreen(
                destination: destination,
                budget: budget,
                days: _days,
                style: _selectedStyle,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
          _showSnackBar("Trip Plan Created Successfully!", Colors.green);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Plan New Trip",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              "Where to?",
              "e.g. Sajek",
              _destinationController,
              Icons.map,
              accentColor,
              isDark,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Budget (BDT)",
              "e.g. 5000",
              _budgetController,
              Icons.wallet,
              accentColor,
              isDark,
              isNumber: true,
            ),
            const SizedBox(height: 20),

            // Date Picker
            ListTile(
              onTap: () => _pickDate(accentColor),
              tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: isDark
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey[200]!),
              ),
              leading: Icon(Icons.calendar_today, color: accentColor),
              title: Text(
                _selectedDate == null
                    ? "Select Start Date"
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "Duration",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _buildDurationPicker(accentColor, isDark),

            const SizedBox(height: 30),
            Text(
              "Travel Style",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _travelStyles.map((style) {
                bool isSelected = _selectedStyle == style;
                return ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedStyle = style),
                  selectedColor: accentColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),

            const SizedBox(height: 30),
            // AI Toggle Switch
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: isDark ? null : Border.all(color: Colors.grey[200]!),
              ),
              child: SwitchListTile(
                title: const Text(
                  "Get AI Suggestions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Generate a custom itinerary with Gemini AI",
                ),
                value: _useAI,
                onChanged: (val) => setState(() => _useAI = val),
                secondary: Icon(Icons.auto_awesome, color: accentColor),
                activeColor: accentColor,
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _saveTrip,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CREATE PLAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController ctrl,
    IconData icon,
    Color accentColor,
    bool isDark, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: accentColor),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400]),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white54 : Colors.grey[500],
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDurationPicker(Color accentColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => setState(() => _days > 1 ? _days-- : null),
          icon: Icon(
            Icons.remove_circle,
            color: isDark ? Colors.white54 : Colors.grey,
            size: 32,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$_days Days",
            style: TextStyle(
              fontSize: 22,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _days++),
          icon: Icon(Icons.add_circle, color: accentColor, size: 32),
        ),
      ],
    );
  }
}
