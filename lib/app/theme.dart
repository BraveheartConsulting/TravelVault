import 'package:flutter/material.dart';

/// TravelVault's visual theme. A calm, trustworthy deep-teal palette — the app
/// sells security and peace of mind, not excitement.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF0F6E6E);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
