import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF101114);
  static const _accent = Color(0xFF6757F5);
  static const _surface = Color(0xFFF6F6F9);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
      surface: dark ? const Color(0xFF0D0E11) : _surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : _ink,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5, color: dark ? Colors.white : _ink),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 38, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -1.4, color: dark ? Colors.white : _ink),
        headlineMedium: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1, color: dark ? Colors.white : _ink),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -.3, color: dark ? Colors.white : _ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dark ? Colors.white : _ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: dark ? Colors.white.withValues(alpha: .90) : const Color(0xFF3F424A)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: dark ? Colors.white.withValues(alpha: .78) : const Color(0xFF4F525A)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF17181D) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF191A20) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _accent.withValues(alpha: .55), width: 1.5)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF111216) : Colors.white,
        indicatorColor: _accent.withValues(alpha: .13),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dark ? Colors.white : _ink)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: dark ? Colors.white : _ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
