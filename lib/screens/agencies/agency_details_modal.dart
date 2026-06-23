// screens/agencies/agency_details_modal.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_screen.dart';

class AgencyDetailsModal extends StatefulWidget {
  final Map<String, dynamic> agency;
  final Color accentColor;
  final bool isDark;

  const AgencyDetailsModal({
    super.key,
    required this.agency,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<AgencyDetailsModal> createState() => _AgencyDetailsModalState();
}

class _AgencyDetailsModalState extends State<AgencyDetailsModal> {
  final supabase = Supabase.instance.client;
  final bool _isLoading = false;

  Future<void> _initiateCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _initiateChat(String agencyUserId, String agencyName) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to message')),
      );
      return;
    }

    try {
      Navigator.pop(context); // Close modal

      // FIXED: Updated to match your ChatScreen parameters
      // Adjust the parameters based on your actual ChatScreen constructor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: agencyUserId, // Change if your param name is different
            otherUserName: agencyName, // Change if your param name is different
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agencyName = widget.agency['agency_name'] ?? 'Unknown Agency';
    final ownerName = widget.agency['owner_full_name'] ?? '';
    final location =
        widget.agency['office_address'] ?? 'Location not available';
    final ownerEmail = widget.agency['owner_email'] ?? '';
    final ownerPhone = widget.agency['owner_phone'] ?? '';
    final officePhone = widget.agency['office_phone'] ?? '';
    final website = widget.agency['website_url'] ?? '';
    final userId = widget.agency['user_id'] ?? '';

    final contactPhone = ownerPhone.isNotEmpty ? ownerPhone : officePhone;
    final displayPhone =
        contactPhone.isNotEmpty ? contactPhone : 'Not available';

    final bg =
        widget.isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = widget.isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = widget.isDark
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        widget.isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        widget.isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              color: surface,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // ── HEADER WITH CLOSE BUTTON ──
                  SliverAppBar(
                    backgroundColor: surface,
                    elevation: 0,
                    pinned: true,
                    leading: const SizedBox.shrink(),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Agency Details',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: textSecondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── CONTENT ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── AGENCY HERO SECTION ──
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    widget.accentColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: widget.isDark ? 0.2 : 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Gradient background
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.accentColor
                                            .withValues(alpha: 0.08),
                                        widget.accentColor
                                            .withValues(alpha: 0.03),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                // Icon
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: widget.accentColor
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.accentColor
                                            .withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.travel_explore_rounded,
                                      color: widget.accentColor,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── AGENCY NAME ──
                          Text(
                            agencyName,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── LOCATION ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: widget.accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── DIVIDER ──
                          Container(
                            height: 1,
                            color: surfaceBorder,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                          ),

                          // ── CONTACT INFORMATION ──
                          Text(
                            'Contact Information',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── OWNER NAME ──
                          if (ownerName.isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.person_rounded,
                              label: 'Owner',
                              value: ownerName,
                              textSecondary: textSecondary,
                              textPrimary: textPrimary,
                              isDark: widget.isDark,
                            ),

                          // ── PHONE ──
                          _buildContactRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: displayPhone,
                            textSecondary: textSecondary,
                            textPrimary: textPrimary,
                            isDark: widget.isDark,
                            onTap: contactPhone.isNotEmpty
                                ? () => _initiateCall(contactPhone)
                                : null,
                            accentColor: widget.accentColor,
                          ),

                          // ── EMAIL ──
                          if (ownerEmail.isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.email_rounded,
                              label: 'Email',
                              value: ownerEmail,
                              textSecondary: textSecondary,
                              textPrimary: textPrimary,
                              isDark: widget.isDark,
                            ),

                          // ── WEBSITE ──
                          if (website.isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.language_rounded,
                              label: 'Website',
                              value: website,
                              textSecondary: textSecondary,
                              textPrimary: textPrimary,
                              isDark: widget.isDark,
                            ),

                          const SizedBox(height: 24),

                          // ── DIVIDER ──
                          Container(
                            height: 1,
                            color: surfaceBorder,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                          ),

                          // ── VERIFICATION BADGE ──
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Verified Agency',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── ACTION BUTTONS ──
                          Row(
                            children: [
                              // ── CALL BUTTON ──
                              Expanded(
                                child: GestureDetector(
                                  onTap: contactPhone.isNotEmpty
                                      ? () => _initiateCall(contactPhone)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: widget.accentColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: widget.accentColor
                                            .withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          color: widget.accentColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Call',
                                          style: TextStyle(
                                            color: widget.accentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── MESSAGE BUTTON ──
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _initiateChat(userId, agencyName),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: widget.accentColor,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.accentColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.message_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Message',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // FIXED: All parameters now use named arguments
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textSecondary,
    required Color textPrimary,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: All parameters now use named arguments
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textSecondary,
    required Color textPrimary,
    required bool isDark,
    VoidCallback? onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: onTap != null
              ? accentColor.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(
                  color: accentColor.withValues(alpha: 0.12),
                  width: 0.5,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: onTap != null ? accentColor : textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: onTap != null ? accentColor : textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
