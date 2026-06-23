// screens/agency/messages/agency_chat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/message_service.dart';

class AgencyChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const AgencyChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<AgencyChatPage> createState() => _AgencyChatPageState();
}

class _AgencyChatPageState extends State<AgencyChatPage> {
  final messageService = MessageService();
  final supabase = Supabase.instance.client;
  late TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      await messageService.markMessagesAsRead(
        currentUser.id,
        widget.otherUserId,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await messageService.sendMessage(
        senderId: currentUser.id,
        receiverId: widget.otherUserId,
        content: content,
        messageType: 'text',
      );

      // Auto-scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
      // Restore message if failed
      _messageController.text = content;
    }
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.otherUserName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Active now',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () {
              // Call action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.phone_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── MESSAGES LIST ──
          Expanded(
            child: userId.isEmpty
                ? Center(
                    child: Text(
                      'Please login to view messages',
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: messageService.getConversationStream(
                      userId,
                      widget.otherUserId,
                    ),
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
                          child: Text(
                            'Error loading messages',
                            style: TextStyle(color: textSecondary),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      // Empty state
                      if (messages.isEmpty) {
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
                                'No messages yet',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Scroll to bottom on new messages
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message['sender_id'] == userId;

                          return _buildMessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            accentColor: accentColor,
                            isDark: isDark,
                            surface: surface,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── INPUT FIELD ──
          Container(
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(color: surfaceBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                // ── ATTACHMENT BUTTON ──
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File sharing coming soon')),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.attach_file_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── MESSAGE INPUT ──
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: textSecondary.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      minLines: 1,
                      onChanged: (value) {
                        setState(() {
                          _isTyping = value.isNotEmpty;
                        });
                      },
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── SEND BUTTON ──
                GestureDetector(
                  onTap: _isTyping ? _sendMessage : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isTyping
                          ? accentColor
                          : textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isTyping
                          ? Colors.white
                          : textSecondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required bool isCurrentUser,
    required Color accentColor,
    required bool isDark,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final content = message['content'] ?? '';
    final createdAt = message['created_at'] ?? '';

    // Parse time
    String timeString = '';
    if (createdAt.isNotEmpty) {
      try {
        final time = DateTime.parse(createdAt);
        timeString = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        timeString = '';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? accentColor
                    : surface.withOpacity(isDark ? 0.5 : 1),
                borderRadius: BorderRadius.circular(18),
                border: !isCurrentUser
                    ? Border.all(
                        color: textSecondary.withValues(alpha: 0.1),
                        width: 0.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
