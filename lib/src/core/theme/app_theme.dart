import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.gold,
    required this.goldSoft,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.matnBackground,
    required this.divider,
    required this.numberBadge,
    required this.numberBadgeText,
    required this.heroStart,
    required this.heroEnd,
    required this.activeRow,
  });

  final Color gold;
  final Color goldSoft;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color matnBackground;
  final Color divider;
  final Color numberBadge;
  final Color numberBadgeText;
  final Color heroStart;
  final Color heroEnd;
  final Color activeRow;

  @override
  AppPalette copyWith({
    Color? gold,
    Color? goldSoft,
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? matnBackground,
    Color? divider,
    Color? numberBadge,
    Color? numberBadgeText,
    Color? heroStart,
    Color? heroEnd,
    Color? activeRow,
  }) {
    return AppPalette(
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
      matnBackground: matnBackground ?? this.matnBackground,
      divider: divider ?? this.divider,
      numberBadge: numberBadge ?? this.numberBadge,
      numberBadgeText: numberBadgeText ?? this.numberBadgeText,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      activeRow: activeRow ?? this.activeRow,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) {
      return this;
    }
    return AppPalette(
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      cardGradientStart:
          Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
      matnBackground: Color.lerp(matnBackground, other.matnBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      numberBadge: Color.lerp(numberBadge, other.numberBadge, t)!,
      numberBadgeText: Color.lerp(numberBadgeText, other.numberBadgeText, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      activeRow: Color.lerp(activeRow, other.activeRow, t)!,
    );
  }
}

abstract final class AppTheme {
  static const String uiFontFamily = 'IBMPlexSansArabic';
  static const String scriptFontFamily = 'Amiri';

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF12604F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD3EBE1),
    onPrimaryContainer: Color(0xFF00281F),
    secondary: Color(0xFF8A6A20),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6E9C9),
    onSecondaryContainer: Color(0xFF2C2000),
    tertiary: Color(0xFF3B6470),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD3E9F1),
    onTertiaryContainer: Color(0xFF001F27),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFCFAF5),
    onSurface: Color(0xFF1A1C1B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F4EC),
    surfaceContainer: Color(0xFFF1EEE5),
    surfaceContainerHigh: Color(0xFFEBE8DF),
    surfaceContainerHighest: Color(0xFFE5E2D9),
    onSurfaceVariant: Color(0xFF4A5350),
    outline: Color(0xFF7B837F),
    outlineVariant: Color(0xFFCBD3CF),
    inverseSurface: Color(0xFF2E3230),
    onInverseSurface: Color(0xFFF1F1EE),
    inversePrimary: Color(0xFF7BD3B7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7BD3B7),
    onPrimary: Color(0xFF003729),
    primaryContainer: Color(0xFF13513E),
    onPrimaryContainer: Color(0xFF97EFD2),
    secondary: Color(0xFFE0C177),
    onSecondary: Color(0xFF3B2E04),
    secondaryContainer: Color(0xFF544219),
    onSecondaryContainer: Color(0xFFFDE1A0),
    tertiary: Color(0xFFA6CDDA),
    onTertiary: Color(0xFF073541),
    tertiaryContainer: Color(0xFF244C58),
    onTertiaryContainer: Color(0xFFC2E9F6),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF0F1412),
    onSurface: Color(0xFFE2E4E1),
    surfaceContainerLowest: Color(0xFF0A0F0D),
    surfaceContainerLow: Color(0xFF161B19),
    surfaceContainer: Color(0xFF1A201D),
    surfaceContainerHigh: Color(0xFF242A27),
    surfaceContainerHighest: Color(0xFF2F3532),
    onSurfaceVariant: Color(0xFFBCC5C0),
    outline: Color(0xFF869089),
    outlineVariant: Color(0xFF3C4541),
    inverseSurface: Color(0xFFE2E4E1),
    onInverseSurface: Color(0xFF1A201D),
    inversePrimary: Color(0xFF12604F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const AppPalette _lightPalette = AppPalette(
    gold: Color(0xFFB08A2E),
    goldSoft: Color(0xFFF3E7C8),
    cardGradientStart: Color(0xFFFFFFFF),
    cardGradientEnd: Color(0xFFF6F3EA),
    matnBackground: Color(0xFFF4F1E6),
    divider: Color(0xFFDDE2DD),
    numberBadge: Color(0xFF12604F),
    numberBadgeText: Color(0xFFFFFFFF),
    heroStart: Color(0xFF13897A),
    heroEnd: Color(0xFF0C6153),
    activeRow: Color(0xFFE7F3EE),
  );

  static const AppPalette _darkPalette = AppPalette(
    gold: Color(0xFFE0C177),
    goldSoft: Color(0xFF3A331F),
    cardGradientStart: Color(0xFF1A201D),
    cardGradientEnd: Color(0xFF141A17),
    matnBackground: Color(0xFF161D1A),
    divider: Color(0xFF2C3431),
    numberBadge: Color(0xFF7BD3B7),
    numberBadgeText: Color(0xFF00281F),
    heroStart: Color(0xFF10352E),
    heroEnd: Color(0xFF0B211C),
    activeRow: Color(0xFF17332B),
  );

  static ThemeData light() => _build(_lightScheme, _lightPalette);

  static ThemeData dark() => _build(_darkScheme, _darkPalette);

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final TextTheme textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: uiFontFamily,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.divider),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: palette.divider),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: WidgetStateColor.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: palette.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final Color onSurface = scheme.onSurface;
    final Color muted = scheme.onSurfaceVariant;
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: scriptFontFamily,
        fontSize: 34,
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: scriptFontFamily,
        fontSize: 28,
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 22,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 19,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 16.5,
        height: 1.6,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 14.5,
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 16,
        height: 1.9,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 14.5,
        height: 1.85,
        color: muted,
      ),
      bodySmall: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 13,
        height: 1.7,
        color: muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 14.5,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }
}
