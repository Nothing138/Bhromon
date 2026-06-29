// screens/sos/emergency_contacts_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final supabase = Supabase.instance.client;

  List<EmergencyContact> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          contacts =
              (data as List).map((e) => EmergencyContact.fromMap(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _addContact() async {
    showDialog(
      context: context,
      builder: (context) => const _AddContactDialog(),
    ).then((_) => _loadContacts());
  }

  Future<void> _editContact(EmergencyContact contact) async {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(contact: contact),
    ).then((_) => _loadContacts());
  }

  Future<void> _deleteContact(String contactId) async {
    try {
      await supabase.from('emergency_contacts').delete().eq('id', contactId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      }
      _loadContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(EmergencyContact contact) async {
    try {
      await supabase
          .from('emergency_contacts')
          .update({'is_active': !contact.isActive}).eq('id', contact.id);

      _loadContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

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
        elevation: 0,
        backgroundColor: bg,
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
            child: Icon(Icons.arrow_back_rounded, color: accentColor, size: 20),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'Emergency Contacts',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _addContact,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(Icons.add_rounded, color: accentColor, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These contacts will be notified when you send an SOS alert',
                            style: TextStyle(
                              color: Colors.blueAccent.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (contacts.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No emergency contacts yet',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add contacts who should be notified in case of emergency',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addContact,
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Contact'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return _buildContactCard(
                          contact,
                          isDark,
                          surface,
                          surfaceBorder,
                          textPrimary,
                          textSecondary,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  //  FIXED: Using Opacity widget instead of opacity parameter
  Widget _buildContactCard(
    EmergencyContact contact,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Opacity(
      opacity: contact.isActive ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaceBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.contactName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship ?? 'Contact',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: contact.isActive
                        ? Colors.greenAccent.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    contact.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          contact.isActive ? Colors.greenAccent : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              contact.contactPhone,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editContact(contact),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleActive(contact),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: contact.isActive
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : Colors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: contact.isActive
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.greenAccent.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            contact.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            color: contact.isActive
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contact.isActive ? 'Disable' : 'Enable',
                            style: TextStyle(
                              color: contact.isActive
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _deleteContact(contact.id),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  const _AddContactDialog({this.contact});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final supabase = Supabase.instance.client;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController relationshipController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.contact?.contactName ?? '');
    phoneController =
        TextEditingController(text: widget.contact?.contactPhone ?? '');
    relationshipController =
        TextEditingController(text: widget.contact?.relationship ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    relationshipController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (widget.contact != null) {
        // Update existing contact
        await supabase.from('emergency_contacts').update({
          'contact_name': nameController.text,
          'contact_phone': phoneController.text,
          'relationship': relationshipController.text,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.contact!.id);
      } else {
        // Create new contact
        await supabase.from('emergency_contacts').insert({
          'user_id': userId,
          'contact_name': nameController.text,
          'contact_phone': phoneController.text,
          'relationship': relationshipController.text,
          'is_active': true,
          'priority': 0,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.contact != null
                  ? 'Contact updated successfully'
                  : 'Contact added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact != null ? 'Edit Contact' : 'Add Contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Mom, Brother',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'e.g., +8801234567890',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (Optional)',
                hintText: 'e.g., Mother, Close Friend',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveContact,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.contact != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class EmergencyContact {
  final String id;
  final String contactName;
  final String contactPhone;
  final String? relationship;
  final bool isActive;
  final int priority;

  EmergencyContact({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    this.relationship,
    required this.isActive,
    required this.priority,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      contactName: map['contact_name'] ?? 'Unknown',
      contactPhone: map['contact_phone'] ?? '',
      relationship: map['relationship'],
      isActive: map['is_active'] ?? true,
      priority: map['priority'] ?? 0,
    );
  }
}
