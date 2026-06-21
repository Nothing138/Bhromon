// screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'user_register_screen.dart';
import 'agency_register_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedRole; // 'user' or 'agency'

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeProvider.accentColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              'Join Bhromon',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: themeProvider.accentColor,
              ),
            ),
            const Text(
              'Choose your account type',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 50),

            // User Card
            GestureDetector(
              onTap: () {
                setState(() => _selectedRole = 'user');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedRole == 'user'
                        ? themeProvider.accentColor
                        : Colors.grey[400]!,
                    width: _selectedRole == 'user' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: _selectedRole == 'user'
                      ? themeProvider.accentColor.withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 35,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Traveler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Explore destinations, find travel groups, and share your journey with fellow travelers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_selectedRole == 'user')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Agency Card
            GestureDetector(
              onTap: () {
                setState(() => _selectedRole = 'agency');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedRole == 'agency'
                        ? themeProvider.accentColor
                        : Colors.grey[400]!,
                    width: _selectedRole == 'agency' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: _selectedRole == 'agency'
                      ? themeProvider.accentColor.withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        size: 35,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Travel Agency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Register your travel business, manage bookings, and connect with travelers looking for guided experiences',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_selectedRole == 'agency')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        if (_selectedRole == 'user') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserRegisterScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AgencyRegisterScreen(),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.accentColor,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
