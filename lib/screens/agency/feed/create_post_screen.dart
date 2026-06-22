// screens/agency/feed/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/event_service.dart';
import '../../../models/event_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedCategory = 'general';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleCreateEvent() async {
    if (_titleController.text.isEmpty) {
      _showError('Please enter event title');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final eventService = Provider.of<EventService>(context, listen: false);

      if (authService.currentAgency == null) {
        throw Exception('Agency not found');
      }

      // Combine date and time
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final request = CreateEventRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        eventDate: eventDateTime,
        price: double.tryParse(_priceController.text) ?? 0,
        capacity: int.tryParse(_capacityController.text),
        category: _selectedCategory,
      );

      await eventService.createEvent(
        agencyId: authService.currentAgency!.id,
        title: request.title,
        description: request.description ?? '',
        location: request.location ?? '',
        eventDate: request.eventDate,
        price: request.price,
        capacity: request.capacity ?? 0,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to create event: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeProvider.accentColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Event',
          style: TextStyle(
            color: themeProvider.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Event Title *',
              hint: 'e.g., Summer Trek to Sundarbans',
              themeProvider: themeProvider,
              isDark: isDark,
              icon: Icons.title,
            ),
            const SizedBox(height: 20),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Tell people about this event...',
              themeProvider: themeProvider,
              isDark: isDark,
              icon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Event location',
              themeProvider: themeProvider,
              isDark: isDark,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 20),

            // Date & Time
            Text(
              'Date & Time *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              themeProvider.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: themeProvider.accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              themeProvider.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: themeProvider.accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: ['general', 'hiking', 'beach', 'cultural', 'adventure']
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value ?? 'general');
              },
            ),
            const SizedBox(height: 20),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price (TK)',
              hint: '0',
              themeProvider: themeProvider,
              isDark: isDark,
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Capacity
            _buildTextField(
              controller: _capacityController,
              label: 'Capacity (Optional)',
              hint: 'Max participants',
              themeProvider: themeProvider,
              isDark: isDark,
              icon: Icons.people,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.accentColor,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleCreateEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeProvider themeProvider,
    required bool isDark,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: themeProvider.accentColor),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.accentColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
