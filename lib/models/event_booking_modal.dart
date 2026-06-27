// models/event_booking_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/booking_service.dart';

class EventBookingModal extends StatefulWidget {
  final Map<String, dynamic> event;
  final String userId;
  final VoidCallback onBookingSuccess;

  const EventBookingModal({
    super.key,
    required this.event,
    required this.userId,
    required this.onBookingSuccess,
  });

  @override
  State<EventBookingModal> createState() => _EventBookingModalState();
}

class _EventBookingModalState extends State<EventBookingModal> {
  late final BookingService _bookingService;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedSeats = 1;
  bool _isLoading = false;
  bool _isEventAvailable = false;
  String? _availabilityError;
  Map<String, dynamic>? _bookingStats;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService();
    _checkEventAvailability();
    _loadBookingStats();
  }

  Future<void> _checkEventAvailability() async {
    final available = await _bookingService.isEventAvailableForBooking(
      widget.event['id'] as String,
    );

    String? error;
    if (!available) {
      final eventDate = DateTime.parse(widget.event['event_date'] as String);
      if (eventDate.isBefore(DateTime.now())) {
        error = 'Event date has passed';
      } else if (widget.event['status'] != 'active') {
        error = 'Event is no longer active';
      } else {
        error = 'Event is fully booked';
      }
    }

    setState(() {
      _isEventAvailable = available;
      _availabilityError = error;
    });
  }

  Future<void> _loadBookingStats() async {
    final stats = await _bookingService.getEventBookingStats(
      widget.event['id'] as String,
    );
    setState(() => _bookingStats = stats);
  }

  Future<void> _submitBooking() async {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = (widget.event['price'] as num? ?? 0).toDouble();
      final totalPrice = price * _selectedSeats;

      await _bookingService.createBooking(
        eventId: widget.event['id'] as String,
        userId: widget.userId,
        bookingCount: _selectedSeats,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        totalPrice: totalPrice,
        bookingNotes: _notesController.text.trim(),
      );

      if (mounted) {
        _showSuccess(
          'Booking confirmed for ${_selectedSeats} seat${_selectedSeats > 1 ? 's' : ''}!\n'
          'Total: ৳${totalPrice.toStringAsFixed(0)}',
        );
        widget.onBookingSuccess();
      }
    } catch (e) {
      _showError('Booking failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(_); // Close dialog
              Navigator.pop(context); // Close modal
            },
            child: const Text('Done'),
          ),
        ],
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
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    final price = (widget.event['price'] as num? ?? 0).toDouble();
    final totalPrice = price * _selectedSeats;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // TITLE & EVENT INFO
            // ═══════════════════════════════════════════════════════════
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.event['title'] as String? ?? 'Event',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // AVAILABILITY STATUS
            // ═══════════════════════════════════════════════════════════
            if (!_isEventAvailable)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _availabilityError ?? 'Booking not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_bookingStats != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Available: ${_bookingStats!['available_seats'] ?? 'Unlimited'} seats',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // SEAT SELECTION
            // ═══════════════════════════════════════════════════════════
            Text(
              'Number of Seats',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2340) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  // Minus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isEventAvailable && _selectedSeats > 1
                          ? () => setState(() => _selectedSeats--)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.remove_rounded,
                          color: _isEventAvailable && _selectedSeats > 1
                              ? accentColor
                              : textSecondary.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _selectedSeats.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            _selectedSeats == 1 ? 'seat' : 'seats',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Plus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isEventAvailable
                          ? () {
                              final available =
                                  (_bookingStats?['available_seats'] as int?) ??
                                      999;
                              if (_selectedSeats < available) {
                                setState(() => _selectedSeats++);
                              } else {
                                _showError('No more seats available');
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_rounded,
                          color: _isEventAvailable
                              ? accentColor
                              : textSecondary.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // USER DETAILS
            // ═══════════════════════════════════════════════════════════
            Text(
              'Your Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              textSecondary: textSecondary,
              surfaceBorder: surfaceBorder,
              enabled: _isEventAvailable,
            ),
            const SizedBox(height: 12),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              textSecondary: textSecondary,
              surfaceBorder: surfaceBorder,
              enabled: _isEventAvailable,
            ),
            const SizedBox(height: 12),

            // Phone
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+880 1234 567890',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              textSecondary: textSecondary,
              surfaceBorder: surfaceBorder,
              enabled: _isEventAvailable,
            ),
            const SizedBox(height: 12),

            // Notes (optional)
            _buildTextField(
              controller: _notesController,
              label: 'Special Requests (Optional)',
              hint: 'Any special requests or notes...',
              icon: Icons.note_outlined,
              maxLines: 2,
              isDark: isDark,
              textSecondary: textSecondary,
              surfaceBorder: surfaceBorder,
              enabled: _isEventAvailable,
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // PRICE SUMMARY
            // ═══════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per seat',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        '৳${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        '×$_selectedSeats',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: surfaceBorder, height: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '৳${totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // CONFIRM BUTTON
            // ═══════════════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    !_isEventAvailable || _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? const Color(0xFF1A2340) : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isDark,
    required Color textSecondary,
    required Color surfaceBorder,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: surfaceBorder, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: surfaceBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: surfaceBorder, width: 1),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A2340) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
