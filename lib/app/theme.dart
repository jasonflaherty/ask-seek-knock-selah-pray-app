import 'package:flutter/material.dart';

/// Extra palette tokens not covered by [ColorScheme].
@immutable
class SelahPalette extends ThemeExtension<SelahPalette> {
  const SelahPalette({
    required this.answeredBadgeBg,
    required this.answeredBadgeFg,
    required this.selectedItemBg,
    required this.verseSurface,
  });

  final Color answeredBadgeBg;
  final Color answeredBadgeFg;
  final Color selectedItemBg;
  final Color verseSurface;

  /// Liturgical gold badge; blue selected wash.
  static const light = SelahPalette(
    answeredBadgeBg: Color(0xFFE8D5A3),
    answeredBadgeFg: Color(0xFF3D2E0A),
    selectedItemBg: Color(0xFFD6E2F0),
    verseSurface: Color(0xFFC8D8EB),
  );

  /// Deep wine + gold for answered state in dark mode.
  static const dark = SelahPalette(
    answeredBadgeBg: Color(0xFF5C2814),
    answeredBadgeFg: Color(0xFFF5D78E),
    selectedItemBg: Color(0xFF1E3A55),
    verseSurface: Color(0xFF152536),
  );

  @override
  SelahPalette copyWith({
    Color? answeredBadgeBg,
    Color? answeredBadgeFg,
    Color? selectedItemBg,
    Color? verseSurface,
  }) {
    return SelahPalette(
      answeredBadgeBg: answeredBadgeBg ?? this.answeredBadgeBg,
      answeredBadgeFg: answeredBadgeFg ?? this.answeredBadgeFg,
      selectedItemBg: selectedItemBg ?? this.selectedItemBg,
      verseSurface: verseSurface ?? this.verseSurface,
    );
  }

  @override
  SelahPalette lerp(ThemeExtension<SelahPalette>? other, double t) {
    if (other is! SelahPalette) return this;
    return SelahPalette(
      answeredBadgeBg: Color.lerp(answeredBadgeBg, other.answeredBadgeBg, t)!,
      answeredBadgeFg: Color.lerp(answeredBadgeFg, other.answeredBadgeFg, t)!,
      selectedItemBg: Color.lerp(selectedItemBg, other.selectedItemBg, t)!,
      verseSurface: Color.lerp(verseSurface, other.verseSurface, t)!,
    );
  }
}

extension SelahThemeX on BuildContext {
  SelahPalette get palette => Theme.of(this).extension<SelahPalette>()!;
}

/// Returns [preferred] unless the OS reduce-motion setting is on.
Duration motion(BuildContext context, [Duration preferred = const Duration(milliseconds: 150)]) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return Duration.zero;
  }
  return preferred;
}

abstract final class AppTheme {
  static const String uiFont = 'AtkinsonHyperlegible';
  static const String scriptureFont = 'Lora';

  /// Tighter radii for a modern, crisp UI (still ≥ 8 for touch affordance).
  static const double cardRadius = 12;
  static const double controlRadius = 8;
  static const double chipRadius = 6;
  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double cardGap = 10;
  static const double maxContentWidth = 640;
  static const double buttonHeight = 48;
  static const double minTapTarget = 48;

  // Light — Byzantine blue field; white cards stand out on it
  static const Color lightSurface = Color(0xFFD6E2F0);
  static const Color lightCard = Color(0xFFF8FAFD);
  static const Color lightOnSurface = Color(0xFF1A1F2E);
  static const Color lightOnSurfaceVariant = Color(0xFF4A5163);
  static const Color lightPrimary = Color(0xFF1A3A5C);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFF5C6B7C);
  static const Color lightOutlineVariant = Color(0xFFB4C4D6);
  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);

  // Dark — deeper navy field with liturgical gold
  static const Color darkSurface = Color(0xFF0A1624);
  static const Color darkCard = Color(0xFF152536);
  static const Color darkOnSurface = Color(0xFFECE8DC);
  static const Color darkOnSurfaceVariant = Color(0xFFB4B0A4);
  static const Color darkPrimary = Color(0xFFD4AF37);
  static const Color darkOnPrimary = Color(0xFF1A1408);
  static const Color darkOutline = Color(0xFF8C887C);
  static const Color darkOutlineVariant = Color(0xFF2A3C50);
  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkOnError = Color(0xFF601410);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFFADCDA);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        surface: lightSurface,
        card: lightCard,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
        error: lightError,
        onError: lightOnError,
        errorContainer: lightErrorContainer,
        onErrorContainer: lightOnErrorContainer,
        palette: SelahPalette.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        surface: darkSurface,
        card: darkCard,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        error: darkError,
        onError: darkOnError,
        errorContainer: darkErrorContainer,
        onErrorContainer: darkOnErrorContainer,
        palette: SelahPalette.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color card,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color primary,
    required Color onPrimary,
    required Color outline,
    required Color outlineVariant,
    required Color error,
    required Color onError,
    required Color errorContainer,
    required Color onErrorContainer,
    required SelahPalette palette,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceContainerLowest: card,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: card,
      surfaceContainerHighest: card,
    );

    final textTheme = _textTheme(onSurface, onSurfaceVariant);
    final hairline = BorderSide(color: outlineVariant, width: 1);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: uiFont,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [palette],
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        titleSpacing: 16,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: hairline,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTapTarget, buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTapTarget, buttonHeight),
          side: BorderSide(color: outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTapTarget, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        extendedTextStyle: textTheme.labelLarge?.copyWith(color: onPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: textTheme.labelLarge,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: palette.selectedItemBg,
        side: BorderSide(color: outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          side: hairline,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return card;
        }),
        trackOutlineColor: WidgetStateProperty.all(outline),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          side: hairline,
        ),
        textStyle: textTheme.bodyLarge,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: hairline,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.selectedItemBg;
            }
            return card;
          }),
          foregroundColor: WidgetStateProperty.all(onSurface),
          side: WidgetStateProperty.all(BorderSide(color: outline, width: 1)),
          minimumSize: const WidgetStatePropertyAll(Size(0, minTapTarget)),
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 28,
        height: 1.25,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 20,
        height: 1.3,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 17,
        height: 1.35,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 15,
        height: 1.3,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 13,
        height: 1.3,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: uiFont,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
    );
  }

  /// Scripture text style (Lora) — slightly more open for reading.
  static TextStyle scripture(Color color) => TextStyle(
        fontFamily: scriptureFont,
        fontSize: 19,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
