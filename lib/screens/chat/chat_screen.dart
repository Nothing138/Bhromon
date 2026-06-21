// screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../services/message_service.dart';
import 'emoji_picker_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserPhone;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _messageService = MessageService();
  final _scrollController = ScrollController();
  late String _currentUserId;
  bool _isTyping = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    // Mark messages as read when opening the chat
    _messageService.markMessagesAsRead(_currentUserId, widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _isTyping = false;
    });
    _messageController.clear();

    await _messageService.sendMessage(
      senderId: _currentUserId,
      receiverId: widget.otherUserId,
      content: content,
      messageType: 'text',
    );

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: EmojiPickerSheet(
          onEmojiSelected: (emoji) {
            _messageController.text += emoji;
            setState(() => _isTyping = _messageController.text.isNotEmpty);
            Navigator.pop(context);
          },
        ),
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surface,
        titleSpacing: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: widget.otherUserAvatar != null &&
                      widget.otherUserAvatar!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.otherUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_outlined, color: accentColor, size: 20),
          ),
          IconButton(
            onPressed: () => _showContactInfo(context, themeProvider, isDark,
                textPrimary, textSecondary, surface),
            icon:
                Icon(Icons.info_outline_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Messages Stream ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // FIX: Use getConversationStream instead of getMessagesStream
              stream: _messageService.getConversationStream(
                _currentUserId,
                widget.otherUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Icon(Icons.chat_outlined,
                              color: accentColor.withValues(alpha: 0.6),
                              size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello to ${widget.otherUserName}!',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, index) => _buildMessageBubble(
                    messages[index],
                    accentColor,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),
                );
              },
            ),
          ),

          // ── Message Input ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(color: surfaceBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Emoji button
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.emoji_emotions_outlined,
                        color: accentColor, size: 18),
                  ),
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A2340)
                          : const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _messageController,
                      onChanged: (v) =>
                          setState(() => _isTyping = v.trim().isNotEmpty),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                            TextStyle(color: textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: (_isTyping && !_isSending) ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (_isTyping && !_isSending)
                          ? accentColor
                          : accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isSending
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: accentColor),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: (_isTyping) ? Colors.white : accentColor,
                            size: 18,
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

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    Color accentColor,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSentByMe = message['sender_id'] == _currentUserId;
    final content = message['content'] as String;
    final createdAt = DateTime.parse(message['created_at'] as String);
    final timeStr =
        '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    final isRead = message['read_status'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user avatar (small)
          if (!isSentByMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: isSentByMe
                  ? () => _showDeleteDialog(message['id'] as String)
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? accentColor
                      : (isDark
                          ? const Color(0xFF1A2340)
                          : const Color(0xFFE8EEF9)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                    bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isSentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isSentByMe ? Colors.white : textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isSentByMe
                                ? Colors.white.withValues(alpha: 0.65)
                                : textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        // Read receipt (only for sent messages)
                        if (isSentByMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 13,
                            color: isRead
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isSentByMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showDeleteDialog(String messageId) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete message?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('This message will be deleted for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _messageService.deleteMessage(messageId);
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showContactInfo(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: themeProvider.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.otherUserName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.otherUserPhone != null &&
                widget.otherUserPhone!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone_outlined,
                    color: themeProvider.accentColor),
                title: Text('Phone',
                    style: TextStyle(color: textSecondary, fontSize: 12)),
                subtitle: Text(
                  widget.otherUserPhone!,
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
