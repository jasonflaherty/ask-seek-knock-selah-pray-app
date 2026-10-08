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

  static const light = SelahPalette(
    answeredBadgeBg: Color(0xFFFBEBC8),
    answeredBadgeFg: Color(0xFF5C3D00),
    selectedItemBg: Color(0xFFE4F1F6),
    verseSurface: Color(0xFFF3F0EA),
  );

  static const dark = SelahPalette(
    answeredBadgeBg: Color(0xFF3E3112),
    answeredBadgeFg: Color(0xFFF5D78E),
    selectedItemBg: Color(0xFF1F3A47),
    verseSurface: Color(0xFF161A22),
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

  static const double cardRadius = 20;
  static const double controlRadius = 14;
  static const double screenPadding = 20;
  static const double cardPadding = 20;
  static const double cardGap = 12;
  static const double maxContentWidth = 640;
  static const double buttonHeight = 52;
  static const double minTapTarget = 48;

  // Light tokens
  static const Color lightSurface = Color(0xFFFBF8F3);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1E2330);
  static const Color lightOnSurfaceVariant = Color(0xFF4A5060);
  static const Color lightPrimary = Color(0xFF1D5C73);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFF757B89);
  static const Color lightOutlineVariant = Color(0xFFC8CCD4);
  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);

  // Dark tokens
  static const Color darkSurface = Color(0xFF12151C);
  static const Color darkCard = Color(0xFF1B1F29);
  static const Color darkOnSurface = Color(0xFFECEEF3);
  static const Color darkOnSurfaceVariant = Color(0xFFB4BAC8);
  static const Color darkPrimary = Color(0xFF8FCBE0);
  static const Color darkOnPrimary = Color(0xFF08303E);
  static const Color darkOutline = Color(0xFF8C93A3);
  static const Color darkOutlineVariant = Color(0xFF3A4050);
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

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: uiFont,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTapTarget, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTapTarget, buttonHeight),
          side: BorderSide(color: outline),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        extendedTextStyle: textTheme.labelLarge?.copyWith(color: onPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: primary, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: error, width: 3),
        ),
        labelStyle: textTheme.labelLarge,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: palette.selectedItemBg,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.selectedItemBg;
            }
            return card;
          }),
          foregroundColor: WidgetStateProperty.all(onSurface),
          side: WidgetStateProperty.all(BorderSide(color: outline)),
          minimumSize: const WidgetStatePropertyAll(Size(0, minTapTarget)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 26,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 22,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 19,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: uiFont,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: uiFont,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
    );
  }

  /// Scripture text style (Lora, 20 sp, height 1.65).
  static TextStyle scripture(Color color) => TextStyle(
        fontFamily: scriptureFont,
        fontSize: 20,
        height: 1.65,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
