// screens/agency/messages/agency_message_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/message_service.dart';
import 'agency_chat_page.dart';

class AgencyMessagePage extends StatefulWidget {
  const AgencyMessagePage({super.key});

  @override
  State<AgencyMessagePage> createState() => _AgencyMessagePageState();
}

class _AgencyMessagePageState extends State<AgencyMessagePage> {
  final messageService = MessageService();
  final supabase = Supabase.instance.client;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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

    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: surfaceBorder,
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: surfaceBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE2E8F4)
                      : const Color(0xFF0D1117),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF2E3A56)
                        : const Color(0xFFBBC3D4),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.search_rounded,
                        color: textSecondary, size: 20),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.close_rounded,
                                color: textSecondary, size: 18),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── CONVERSATIONS LIST ──
          Expanded(
            child: userId.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          color: textSecondary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please login to view messages',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: messageService.getAllConversations(userId),
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accentColor),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: textSecondary,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load messages',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Empty state
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                color: textSecondary,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations yet',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final conversations = snapshot.data!;

                      // Filter by search query
                      final filtered = _searchQuery.isEmpty
                          ? conversations
                          : conversations.where((conv) {
                              final user1Name =
                                  (conv['user_1']?['full_name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final user2Name =
                                  (conv['user_2']?['full_name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final lastMsg = (conv['last_message'] ?? '')
                                  .toString()
                                  .toLowerCase();

                              return user1Name.contains(_searchQuery) ||
                                  user2Name.contains(_searchQuery) ||
                                  lastMsg.contains(_searchQuery);
                            }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No conversations found',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final conversation = filtered[index];
                          return _buildConversationItem(
                            conversation: conversation,
                            userId: userId,
                            accentColor: accentColor,
                            isDark: isDark,
                            surface: surface,
                            surfaceBorder: surfaceBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem({
    required Map<String, dynamic> conversation,
    required String userId,
    required Color accentColor,
    required bool isDark,
    required Color surface,
    required Color surfaceBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    // Determine the other user
    final user1Id = conversation['user_1_id'] ?? '';
    final user2Id = conversation['user_2_id'] ?? '';
    final otherUserId = userId == user1Id ? user2Id : user1Id;

    final otherUser =
        userId == user1Id ? conversation['user_2'] : conversation['user_1'];
    final otherUserName = otherUser?['full_name'] ?? 'Unknown';
    final lastMessage = conversation['last_message'] ?? 'No messages yet';
    final lastMessageTime = conversation['last_message_time'];
    final messageCount = (conversation['message_count'] as int?) ?? 0;

    // Format time
    String timeString = '';
    if (lastMessageTime != null) {
      final time = DateTime.parse(lastMessageTime.toString());
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        timeString = 'now';
      } else if (difference.inHours < 1) {
        timeString = '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        timeString = '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        timeString = '${difference.inDays}d';
      } else {
        timeString = '${time.month}/${time.day}';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgencyChatPage(
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: surfaceBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // ── AVATAR ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  otherUserName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── MESSAGE DETAILS ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUserName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Message count badge
                      if (messageCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            messageCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
