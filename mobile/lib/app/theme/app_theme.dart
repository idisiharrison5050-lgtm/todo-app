import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Todo's visual language: quiet surfaces, editorial typography, and a vivid
/// productivity accent. Keep visual decisions here so every feature feels like
/// the same product rather than a collection of screens.
class AppTheme {
  static const _lightBackground = Color(0xFFF4F5F8);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightRaised = Color(0xFFFAFAFC);
  static const _lightInk = Color(0xFF11131A);
  static const _lightMuted = Color(0xFF6D7180);
  static const _lightOutline = Color(0xFFE1E3EA);
  static const _darkBackground = Color(0xFF08090D);
  static const _darkSurface = Color(0xFF111319);
  static const _darkRaised = Color(0xFF171922);
  static const _darkInk = Color(0xFFF7F7FA);
  static const _darkMuted = Color(0xFFA8ABB8);
  static const _darkOutline = Color(0xFF292C36);
  static const _primary = Color(0xFF5B4BFF);
  static const _primaryLight = Color(0xFFEDEBFF);
  static const _primaryDark = Color(0xFF9A91FF);
  static const _mint = Color(0xFF00A88F);
  static const _coral = Color(0xFFFF705B);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? _primaryDark : _primary,
      onPrimary: dark ? const Color(0xFF17142F) : Colors.white,
      primaryContainer: dark ? const Color(0xFF292650) : _primaryLight,
      onPrimaryContainer: dark ? const Color(0xFFE9E7FF) : const Color(0xFF282064),
      secondary: dark ? const Color(0xFF56D8C4) : _mint,
      onSecondary: dark ? const Color(0xFF00211B) : Colors.white,
      secondaryContainer: dark ? const Color(0xFF123A34) : const Color(0xFFDDF7F1),
      onSecondaryContainer: dark ? const Color(0xFFB5F5EA) : const Color(0xFF003A31),
      tertiary: dark ? const Color(0xFFFF9A87) : _coral,
      onTertiary: dark ? const Color(0xFF35110A) : Colors.white,
      tertiaryContainer: dark ? const Color(0xFF4A211A) : const Color(0xFFFFE8E3),
      onTertiaryContainer: dark ? const Color(0xFFFFDAD3) : const Color(0xFF5C180E),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: dark ? const Color(0xFF690005) : Colors.white,
      errorContainer: dark ? const Color(0xFF541B1B) : const Color(0xFFFFDAD6),
      onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: dark ? _darkBackground : _lightBackground,
      onSurface: dark ? _darkInk : _lightInk,
      surfaceContainerLowest: dark ? const Color(0xFF06070A) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF0D0F14) : _lightRaised,
      surfaceContainer: dark ? _darkSurface : const Color(0xFFF0F1F5),
      surfaceContainerHigh: dark ? const Color(0xFF14161D) : const Color(0xFFECEEF3),
      surfaceContainerHighest: dark ? _darkRaised : const Color(0xFFE5E7ED),
      onSurfaceVariant: dark ? _darkMuted : _lightMuted,
      outline: dark ? const Color(0xFF747886) : const Color(0xFFB9BCC6),
      outlineVariant: dark ? _darkOutline : _lightOutline,
      inverseSurface: dark ? const Color(0xFFF0F0F4) : const Color(0xFF292B32),
      onInverseSurface: dark ? const Color(0xFF292B32) : Colors.white,
      inversePrimary: dark ? _primary : const Color(0xFFC6C1FF),
      scrim: Colors.black,
      shadow: Colors.black,
    );
    final muted = dark ? _darkMuted : _lightMuted;
    final subtle = dark ? const Color(0xFF7E8290) : const Color(0xFF858997);
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
      appBarTheme: AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0, backgroundColor: Colors.transparent, foregroundColor: scheme.onSurface, surfaceTintColor: Colors.transparent, titleSpacing: 22, titleTextStyle: TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -.9, color: scheme.onSurface)),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 46, height: .98, fontWeight: FontWeight.w900, letterSpacing: -2.4, color: scheme.onSurface),
        displayMedium: TextStyle(fontSize: 42, height: 1, fontWeight: FontWeight.w900, letterSpacing: -2.1, color: scheme.onSurface),
        displaySmall: TextStyle(fontSize: 38, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.8, color: scheme.onSurface),
        headlineLarge: TextStyle(fontSize: 31, height: 1.04, fontWeight: FontWeight.w900, letterSpacing: -1.25, color: scheme.onSurface),
        headlineMedium: TextStyle(fontSize: 27, height: 1.07, fontWeight: FontWeight.w900, letterSpacing: -1.0, color: scheme.onSurface),
        headlineSmall: TextStyle(fontSize: 23, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.65, color: scheme.onSurface),
        titleLarge: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.45, color: scheme.onSurface),
        titleMedium: TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w800, color: scheme.onSurface),
        titleSmall: TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w800, color: scheme.onSurface),
        bodyLarge: TextStyle(fontSize: 16, height: 1.48, color: dark ? const Color(0xFFE2E3E9) : const Color(0xFF3D4049)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.42, color: muted),
        bodySmall: TextStyle(fontSize: 12, height: 1.38, color: subtle),
        labelLarge: TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w800, color: scheme.onSurface),
        labelMedium: TextStyle(fontSize: 12, height: 1.1, fontWeight: FontWeight.w800, color: muted),
        labelSmall: TextStyle(fontSize: 11, height: 1.1, fontWeight: FontWeight.w800, color: muted),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: dark ? _darkSurface : _lightSurface, surfaceTintColor: Colors.transparent, shadowColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .9 : .8), width: .8))),
      listTileTheme: ListTileThemeData(contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5), minVerticalPadding: 9, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)), iconColor: scheme.onSurfaceVariant, textColor: scheme.onSurface, titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.onSurface), subtitleTextStyle: TextStyle(fontSize: 12.5, height: 1.3, color: muted)),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: .8, space: 1),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? const Color(0xFF13151B) : Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18), hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w500), border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide(color: scheme.primary, width: 1.7))),
      navigationBarTheme: NavigationBarThemeData(height: 82, elevation: 0, backgroundColor: dark ? const Color(0xFF0C0D12) : Colors.white, surfaceTintColor: Colors.transparent, indicatorColor: scheme.primary.withValues(alpha: .14), labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w600, color: states.contains(WidgetState.selected) ? scheme.onSurface : muted))),
      navigationDrawerTheme: NavigationDrawerThemeData(backgroundColor: dark ? _darkSurface : Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, indicatorColor: scheme.primary.withValues(alpha: .12)),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: BorderSide(color: scheme.outlineVariant), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: scheme.onSurface)),
      segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(visualDensity: VisualDensity.compact, padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 12)), shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      switchTheme: SwitchThemeData(thumbIcon: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Icon(Icons.check_rounded, size: 15) : null)),
      menuTheme: MenuThemeData(style: MenuStyle(backgroundColor: WidgetStateProperty.all(dark ? _darkRaised : Colors.white), surfaceTintColor: WidgetStateProperty.all(Colors.transparent), elevation: WidgetStateProperty.all(12), shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))),
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(11)), textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600)),
      dialogTheme: DialogThemeData(elevation: 0, backgroundColor: dark ? const Color(0xFF15171E) : Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: dark ? const Color(0xFF111319) : Colors.white, surfaceTintColor: Colors.transparent, modalBackgroundColor: dark ? const Color(0xFF111319) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32)))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), backgroundColor: dark ? const Color(0xFFE9E9EF) : const Color(0xFF282A31)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 54), padding: const EdgeInsets.symmetric(horizontal: 23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 21), side: BorderSide(color: scheme.outlineVariant), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.onSurface, foregroundColor: scheme.surface, elevation: 7, highlightElevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19))),
      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: scheme.outline, width: 1.6)),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.outline)),
      progressIndicatorTheme: ProgressIndicatorThemeData(linearTrackColor: scheme.outlineVariant.withValues(alpha: .55), circularTrackColor: scheme.outlineVariant.withValues(alpha: .55)),
    );
  }
}
