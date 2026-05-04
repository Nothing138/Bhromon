// screens/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../../providers/theme_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // থিম প্রোভাইডার থেকে ডাটা নেওয়া হচ্ছে
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // ব্যাকগ্রাউন্ড এখন থিম অনুযায়ী পরিবর্তন হবে
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: isDark ? 0 : 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: 8, // স্যাম্পল হিসেবে ৮টি রাখা হলো
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.white10 : Colors.grey[200],
          indent: 70,
        ),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: accentColor.withOpacity(0.1),
              child: Icon(Icons.notifications, color: accentColor),
            ),
            title: Text(
              "New adventure awaits!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              "A new place has been added to your favorite category.",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            trailing: Text(
              "${index + 1}h ago",
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey,
              ),
            ),
            onTap: () {
              // নোটিফিকেশনে ক্লিক করলে নির্দিষ্ট অ্যাকশন এখানে যোগ করা যাবে
            },
          );
        },
      ),
    );
  }
}
