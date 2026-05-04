// screens/main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../providers/theme_provider.dart';
import 'home/home_premium.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePremium(), // Index 0
    const HomeScreen(), // Index 1
    const ProfileScreen(), // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    // থিম প্রোভাইডার থেকে ডাটা নেওয়া হচ্ছে
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      // বডি এখন ডাইনামিক পেজ রেন্ডার করবে
      body: _pages[_selectedIndex],

      // বোটম বারটি স্ক্রিনের ওপর ভাসমান (Floating) স্টাইলে রাখা হয়েছে
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20,
        ), // নিচের এবং পাশের স্পেসিং
        decoration: BoxDecoration(
          // ডার্ক মোডে নেভি ব্লু আর লাইট মোডে সাদা
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,

            // ইউজারের সিলেক্ট করা অ্যাকসেন্ট কালার এখন হাইলাইট হিসেবে কাজ করবে
            selectedItemColor: accentColor,
            unselectedItemColor: isDark ? Colors.white38 : Colors.grey[400],

            showSelectedLabels: true,
            showUnselectedLabels:
                false, // আনসিলেক্টেড লেবেল হাইড করলে বেশি ক্লিন লাগে
            type: BottomNavigationBarType
                .fixed, // আইটেমগুলোর পজিশন ফিক্সড রাখার জন্য

            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_rounded),
                label: "Explore",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rss_feed_rounded),
                label: "Feed",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
