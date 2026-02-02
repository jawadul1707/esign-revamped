import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      primary: const Color(0xFF005D99),
      secondary: const Color(0xFFC2E7FF),
      tertiary: const Color(0xFFC2FFF0),
      surface: const Color(0xFFF2F2F2),
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F2),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
      bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
    ),
    useMaterial3: true,
  );
}

ButtonStyle customButtonStyle({
  required Color foregroundColor,
  required Color backgroundColor,
}) {
  return ElevatedButton.styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 16),
  );
}