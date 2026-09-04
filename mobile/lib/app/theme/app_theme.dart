import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF11131A);
  static const _primary = Color(0xFF5B4BFF);
  static const _secondary = Color(0xFF00A896);
  static const _tertiary = Color(0xFFFF7657);
  static const _lightSurface = Color(0xFFF5F6FA);
  static const _darkSurface = Color(0xFF0B0D12);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: dark ? const Color(0xFF29245F) : const Color(0xFFE8E5FF),
      onPrimaryContainer: dark ? Colors.white : const Color(0xFF21196D),
      secondary: _secondary,
      onSecondary: Colors.white,
      secondaryContainer: dark ? const Color(0xFF123B38) : const Color(0xFFD9F5F0),
      onSecondaryContainer: dark ? Colors.white : const Color(0xFF003B35),
      tertiary: _tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: dark ? const Color(0xFF54251B) : const Color(0xFFFFE4DD),
      onTertiaryContainer: dark ? Colors.white : const Color(0xFF5C1F14),
      error: dark ? const Color(0xFFFF8A80) : const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: dark ? const Color(0xFF5B1B18) : const Color(0xFFFFDAD6),
      onErrorContainer: dark ? Colors.white : const Color(0xFF410002),
      surface: dark ? _darkSurface : _lightSurface,
      onSurface: dark ? Colors.white : _ink,
      surfaceContainerHighest: dark ? const Color(0xFF1A1D25) : const Color(0xFFE9EBF2),
      onSurfaceVariant: dark ? const Color(0xFFC6C7D0) : const Color(0xFF555761),
      outline: dark ? const Color(0xFF777983) : const Color(0xFF777983),
      outlineVariant: dark ? const Color(0xFF40434C) : const Color(0xFFD9DAE2),
      inverseSurface: dark ? const Color(0xFFE7E8EF) : const Color(0xFF292B33),
      onInverseSurface: dark ? const Color(0xFF292B33) : Colors.white,
      inversePrimary: dark ? const Color(0xFFC4BEFF) : const Color(0xFFC4BEFF),
      scrim: Colors.black,
      shadow: Colors.black,
    );
    final muted = dark ? Colors.white.withValues(alpha: .72) : const Color(0xFF626570);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.7, color: scheme.onSurface),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 40, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -1.8, color: scheme.onSurface),
        headlineMedium: TextStyle(fontSize: 30, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: scheme.onSurface),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4, color: scheme.onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: dark ? Colors.white.withValues(alpha: .90) : const Color(0xFF3F424A)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: muted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF151820) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: .10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .45 : .8))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF171A21) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _primary, width: 1.7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF101218) : Colors.white,
        indicatorColor: _primary.withValues(alpha: .13),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurface)),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: scheme.onSurface)),
      dialogTheme: DialogThemeData(elevation: 0, backgroundColor: dark ? const Color(0xFF171A21) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: _ink, foregroundColor: Colors.white, elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    );
  }
}
