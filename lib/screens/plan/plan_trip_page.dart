// screens/plan/plan_trip_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF4B400),
            onPrimary: Colors.black,
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTrip() async {
    if (_destinationController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('trips').insert({
        'user_id': user!.id,
        'destination': _destinationController.text.trim(),
        'budget': int.parse(_budgetController.text.trim()),
        'start_date': _selectedDate!.toIso8601String(), // Correct Date Format
        'duration_days': _days,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Trip Plan Created!"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Plan New Trip"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInputField(
              "Where to?",
              "e.g. Sajek",
              _destinationController,
              Icons.map,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Budget (BDT)",
              "e.g. 5000",
              _budgetController,
              Icons.wallet,
              isNumber: true,
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: _pickDate,
              tileColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFFF4B400),
              ),
              title: Text(
                _selectedDate == null
                    ? "Select Date"
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            _buildDurationPicker(),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4B400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _saveTrip,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "CREATE PLAN",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFF4B400)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDurationPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => setState(() => _days > 1 ? _days-- : null),
          icon: const Icon(Icons.remove_circle, color: Colors.white54),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "$_days Days",
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _days++),
          icon: const Icon(Icons.add_circle, color: Color(0xFFF4B400)),
        ),
      ],
    );
  }
}
