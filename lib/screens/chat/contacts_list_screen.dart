// screens/chat/contacts_list_screen.dart
// screens/chat/contacts_list_screen.dart (FIXED)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../services/message_service.dart';
import 'chat_screen.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final _messageService = MessageService();
  final _searchController = TextEditingController();
  late String _currentUserId;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        elevation: 0,
        backgroundColor: surface,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() => _isSearching = !_isSearching);
                if (!_isSearching) _searchController.clear();
              },
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surfaceBorder, width: 0.5),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

          // Conversations List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messageService.getAllConversations(_currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading conversations',
                      style: TextStyle(color: textSecondary),
                    ),
                  );
                }

                var conversations = snapshot.data ?? [];

                // Filter by search
                if (_searchController.text.isNotEmpty) {
                  conversations = conversations.where((conv) {
                    final user1 = conv['user_1'] as Map<String, dynamic>?;
                    final user2 = conv['user_2'] as Map<String, dynamic>?;
                    final searchText = _searchController.text.toLowerCase();

                    final user1Name =
                        (user1?['full_name'] as String?)?.toLowerCase() ?? '';
                    final user2Name =
                        (user2?['full_name'] as String?)?.toLowerCase() ?? '';

                    return user1Name.contains(searchText) ||
                        user2Name.contains(searchText);
                  }).toList();
                }

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.message_outlined,
                            color: accentColor.withValues(alpha: 0.6),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isSearching
                              ? 'No contacts found'
                              : 'No conversations yet',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSearching
                              ? 'Try a different search term'
                              : 'Start a conversation with someone!',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: conversations.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (_, index) => _buildConversationTile(
                    conversations[index],
                    accentColor,
                    isDark,
                    surface,
                    surfaceBorder,
                    textPrimary,
                    textSecondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Safely extract user data
    final user1 = conversation['user_1'] as Map<String, dynamic>?;
    final user2 = conversation['user_2'] as Map<String, dynamic>?;

    // Determine other user
    final otherUser =
        (user1?['id'] as String?) == _currentUserId ? user2 : user1;
    final otherUserId = (otherUser?['id'] as String?) ?? '';
    final otherUserName =
        (otherUser?['full_name'] as String?) ?? 'Unknown User';
    final otherUserPhone = (otherUser?['phone_number'] as String?);
    final lastMessage = (conversation['last_message'] as String?) ?? '';
    final lastMessageTime = conversation['last_message_time'] != null
        ? DateTime.parse(conversation['last_message_time'] as String)
        : null;

    String timeString = '';
    if (lastMessageTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastMessageTime);

      if (difference.inMinutes < 1) {
        timeString = 'now';
      } else if (difference.inHours < 1) {
        timeString = '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        timeString = '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        timeString = '${difference.inDays}d ago';
      } else {
        timeString =
            '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatar: otherUser?['avatar_url'] as String?,
            otherUserPhone: otherUserPhone,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaceBorder, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    (otherUserName.isNotEmpty ? otherUserName[0] : 'U')
                        .toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherUserName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Time
              Text(
                timeString,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
