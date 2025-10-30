import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057B8)),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
