// agency/messages/agency_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/auth_service.dart';

class AgencyMessagesScreen extends StatefulWidget {
  const AgencyMessagesScreen({super.key});

  @override
  State<AgencyMessagesScreen> createState() => _AgencyMessagesScreenState();
}

class _AgencyMessagesScreenState extends State<AgencyMessagesScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'John Doe',
      'lastMessage': 'Are the tickets still available?',
      'time': '2 min ago',
      'unread': 2,
      'avatar': 'JD',
    },
    {
      'id': '2',
      'name': 'Travel Group A',
      'lastMessage': 'Thanks for the event details!',
      'time': '1 hour ago',
      'unread': 0,
      'avatar': 'TG',
    },
    {
      'id': '3',
      'name': 'Sarah Smith',
      'lastMessage': 'Can we book for 5 people?',
      'time': '3 hours ago',
      'unread': 1,
      'avatar': 'SS',
    },
    {
      'id': '4',
      'name': 'Traveler Community',
      'lastMessage': 'Great event! Looking forward to it',
      'time': 'Yesterday',
      'unread': 0,
      'avatar': 'TC',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Messages',
          style: TextStyle(
            color: themeProvider.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: themeProvider.accentColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(
            conversation,
            themeProvider,
            isDark,
            context,
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
    ThemeProvider themeProvider,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: themeProvider.accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Text(
              conversation['avatar'],
              style: TextStyle(
                color: themeProvider.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              conversation['time'],
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
            if (conversation['unread'] > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeProvider.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation['unread'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to chat screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Open chat with ${conversation['name']}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
