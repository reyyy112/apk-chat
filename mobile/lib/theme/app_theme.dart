import 'package:flutter/material.dart';

class AppTheme {
  // Exact Teal & Mint palette from user screenshots
  static const Color primaryTeal = Color(0xFF179B8E);
  static const Color primaryTealDark = Color(0xFF128277);
  static const Color mintLight = Color(0xFFE6F5F3);
  static const Color mintAccent = Color(0xFFCEECE8);
  
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAF9);
  
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryTeal,
        secondary: primaryTeal,
        surface: backgroundWhite,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Color(0xFF9E9E9E),
        elevation: 10,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
