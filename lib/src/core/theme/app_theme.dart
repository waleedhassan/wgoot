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
    primary: Color(0xFF6B4226),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF2DFCE),
    onPrimaryContainer: Color(0xFF2A1508),
    secondary: Color(0xFF8A6A20),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6E9C9),
    onSecondaryContainer: Color(0xFF2C2000),
    tertiary: Color(0xFFA05C3C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF7DFD1),
    onTertiaryContainer: Color(0xFF34160A),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFCF8F3),
    onSurface: Color(0xFF1F1A16),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F2EA),
    surfaceContainer: Color(0xFFF2EBE1),
    surfaceContainerHigh: Color(0xFFECE4D9),
    surfaceContainerHighest: Color(0xFFE6DDD1),
    onSurfaceVariant: Color(0xFF55493F),
    outline: Color(0xFF85796E),
    outlineVariant: Color(0xFFD6C9BC),
    inverseSurface: Color(0xFF342C25),
    onInverseSurface: Color(0xFFF4EFE9),
    inversePrimary: Color(0xFFE5B98D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE5B98D),
    onPrimary: Color(0xFF452209),
    primaryContainer: Color(0xFF5E3A1F),
    onPrimaryContainer: Color(0xFFFFD9B8),
    secondary: Color(0xFFE0C177),
    onSecondary: Color(0xFF3B2E04),
    secondaryContainer: Color(0xFF544219),
    onSecondaryContainer: Color(0xFFFDE1A0),
    tertiary: Color(0xFFE7B49B),
    onTertiary: Color(0xFF48210F),
    tertiaryContainer: Color(0xFF633823),
    onTertiaryContainer: Color(0xFFFFDBC9),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF16110D),
    onSurface: Color(0xFFE9E1D9),
    surfaceContainerLowest: Color(0xFF100C09),
    surfaceContainerLow: Color(0xFF1E1814),
    surfaceContainer: Color(0xFF231C17),
    surfaceContainerHigh: Color(0xFF2E2620),
    surfaceContainerHighest: Color(0xFF3A312A),
    onSurfaceVariant: Color(0xFFCDC0B4),
    outline: Color(0xFF96897C),
    outlineVariant: Color(0xFF4A3F36),
    inverseSurface: Color(0xFFE9E1D9),
    onInverseSurface: Color(0xFF231C17),
    inversePrimary: Color(0xFF6B4226),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const AppPalette _lightPalette = AppPalette(
    gold: Color(0xFFB08A2E),
    goldSoft: Color(0xFFF3E7C8),
    cardGradientStart: Color(0xFFFFFFFF),
    cardGradientEnd: Color(0xFFF8F2E9),
    matnBackground: Color(0xFFF5EFE4),
    divider: Color(0xFFE3D9CD),
    numberBadge: Color(0xFF6B4226),
    numberBadgeText: Color(0xFFFFFFFF),
    heroStart: Color(0xFF7E5130),
    heroEnd: Color(0xFF4A2B16),
    activeRow: Color(0xFFF5E8DA),
  );

  static const AppPalette _darkPalette = AppPalette(
    gold: Color(0xFFE0C177),
    goldSoft: Color(0xFF3B3320),
    cardGradientStart: Color(0xFF231C17),
    cardGradientEnd: Color(0xFF1B1511),
    matnBackground: Color(0xFF1E1813),
    divider: Color(0xFF352C25),
    numberBadge: Color(0xFFE5B98D),
    numberBadgeText: Color(0xFF2A1508),
    heroStart: Color(0xFF3C2617),
    heroEnd: Color(0xFF241610),
    activeRow: Color(0xFF33251A),
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
