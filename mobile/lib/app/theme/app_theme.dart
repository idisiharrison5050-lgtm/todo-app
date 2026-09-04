import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF111318);
  static const _accent = Color(0xFF4F46E5);
  static const _accentLight = Color(0xFFEEF0FF);
  static const _accentDark = Color(0xFF30308C);
  static const _lightBackground = Color(0xFFF7F7F8);
  static const _darkBackground = Color(0xFF090A0D);
  static const _darkSurface = Color(0xFF111318);
  static const _darkRaised = Color(0xFF181A20);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF9A98FF) : _accent,
      onPrimary: dark ? const Color(0xFF18174B) : Colors.white,
      primaryContainer: dark ? const Color(0xFF29285E) : _accentLight,
      onPrimaryContainer: dark ? const Color(0xFFE9E8FF) : const Color(0xFF211E63),
      secondary: dark ? const Color(0xFFB8B9C4) : const Color(0xFF5F626B),
      onSecondary: dark ? const Color(0xFF1C1D22) : Colors.white,
      secondaryContainer: dark ? const Color(0xFF282A31) : const Color(0xFFE9E9EC),
      onSecondaryContainer: dark ? const Color(0xFFE5E5EA) : const Color(0xFF24252A),
      tertiary: dark ? const Color(0xFFC7A9FF) : const Color(0xFF7251A8),
      onTertiary: dark ? const Color(0xFF28143D) : Colors.white,
      tertiaryContainer: dark ? const Color(0xFF3A2850) : const Color(0xFFF0E7FF),
      onTertiaryContainer: dark ? const Color(0xFFF1DFFF) : const Color(0xFF392052),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: dark ? const Color(0xFF690005) : Colors.white,
      errorContainer: dark ? const Color(0xFF5A1A17) : const Color(0xFFFFDAD6),
      onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: dark ? _darkBackground : _lightBackground,
      onSurface: dark ? const Color(0xFFF4F4F6) : _ink,
      surfaceContainerLowest: dark ? const Color(0xFF07080A) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF0D0E12) : const Color(0xFFFAFAFB),
      surfaceContainer: dark ? _darkSurface : const Color(0xFFF1F1F3),
      surfaceContainerHigh: dark ? const Color(0xFF15171C) : const Color(0xFFECECEF),
      surfaceContainerHighest: dark ? _darkRaised : const Color(0xFFE6E6E9),
      onSurfaceVariant: dark ? const Color(0xFFB8B9C2) : const Color(0xFF62646C),
      outline: dark ? const Color(0xFF777983) : const Color(0xFFB9BAC1),
      outlineVariant: dark ? const Color(0xFF34363D) : const Color(0xFFDEDEE2),
      inverseSurface: dark ? const Color(0xFFE9E9ED) : const Color(0xFF292A2F),
      onInverseSurface: dark ? const Color(0xFF292A2F) : Colors.white,
      inversePrimary: dark ? _accentDark : const Color(0xFFC2C1FF),
      scrim: Colors.black,
      shadow: Colors.black,
    );
    final muted = dark ? const Color(0xFFAAABB4) : const Color(0xFF686A72);
    final subtle = dark ? const Color(0xFF777983) : const Color(0xFF85878F);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        titleTextStyle: TextStyle(fontSize: 23, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: scheme.onSurface),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 40, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.9, color: scheme.onSurface),
        headlineLarge: TextStyle(fontSize: 32, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.25, color: scheme.onSurface),
        headlineMedium: TextStyle(fontSize: 30, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: scheme.onSurface),
        titleLarge: TextStyle(fontSize: 21, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.45, color: scheme.onSurface),
        titleMedium: TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: dark ? const Color(0xFFE1E1E6) : const Color(0xFF3E4047)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: muted),
        bodySmall: TextStyle(fontSize: 12, height: 1.35, color: subtle),
        labelLarge: TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w700, color: scheme.onSurface),
        labelMedium: TextStyle(fontSize: 12, height: 1.1, fontWeight: FontWeight.w700, color: muted),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? _darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .72 : .9), width: .8)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scheme.onSurface),
        subtitleTextStyle: TextStyle(fontSize: 12.5, height: 1.3, color: muted),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .8), thickness: .8, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF14161B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .85))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF0D0E12) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600, color: states.contains(WidgetState.selected) ? scheme.onSurface : muted)),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: dark ? _darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: .12),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 13, vertical: 12)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Icon(Icons.check_rounded, size: 15) : null),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(dark ? _darkRaised : Colors.white),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(elevation: 0, backgroundColor: dark ? const Color(0xFF15171C) : Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: dark ? const Color(0xFF111318) : Colors.white, surfaceTintColor: Colors.transparent, modalBackgroundColor: dark ? const Color(0xFF111318) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30)))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: dark ? const Color(0xFFE9E9ED) : const Color(0xFF292A2F)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), padding: const EdgeInsets.symmetric(horizontal: 20), side: BorderSide(color: scheme.outlineVariant), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.onSurface, foregroundColor: scheme.surface, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), side: BorderSide(color: scheme.outline, width: 1.5)),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.outline)),
      progressIndicatorTheme: ProgressIndicatorThemeData(linearTrackColor: scheme.outlineVariant.withValues(alpha: .55), circularTrackColor: scheme.outlineVariant.withValues(alpha: .55)),
    );
  }
}
