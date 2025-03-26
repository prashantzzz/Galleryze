import 'package:flutter/material.dart';

// App constants
class Constants {
  // App theme colors
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Colors.blue;
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.red;
  
  // Text styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );
  
  static const TextStyle subheaderStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: primaryColor,
  );
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Animation durations
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
}
