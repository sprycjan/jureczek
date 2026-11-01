import 'package:flutter/material.dart';

/// Tokeny stylu „Nocturnal Expedition” (resorces/…/nocturnal_expedition/DESIGN.md).
abstract final class Nocturnal {
  static const surface = Color(0xFF0D1511);
  static const surfaceBright = Color(0xFF333B37);
  static const surfaceContainerLowest = Color(0xFF08100C);
  static const surfaceContainerLow = Color(0xFF151D19);
  static const surfaceContainer = Color(0xFF19211D);
  static const surfaceContainerHigh = Color(0xFF242C28);
  static const surfaceContainerHighest = Color(0xFF2E3732);
  static const onSurface = Color(0xFFDCE5DE);
  static const onSurfaceVariant = Color(0xFFBEC9C0);
  static const outline = Color(0xFF89938B);
  static const outlineVariant = Color(0xFF3F4942);
  static const primary = Color(0xFF85D7A9);
  static const onPrimary = Color(0xFF003821);
  static const primaryContainer = Color(0xFF52A378);
  static const onPrimaryContainer = Color(0xFF00341E);
  static const inversePrimary = Color(0xFF116C46);
  static const secondary = Color(0xFFFFB876);
  static const onSecondary = Color(0xFF4B2800);
  static const secondaryContainer = Color(0xFF6E3D00);
  static const onSecondaryContainer = Color(0xFFF1A966);
  static const tertiary = Color(0xFF9ECEDF);
  static const onTertiary = Color(0xFF003542);
  static const tertiaryContainer = Color(0xFF6B9AAB);
  static const onTertiaryContainer = Color(0xFF00313D);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const headlineFont = 'Epilogue';
  static const bodyFont = 'SpaceGrotesk';
}

const _colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Nocturnal.primary,
  onPrimary: Nocturnal.onPrimary,
  primaryContainer: Nocturnal.primaryContainer,
  onPrimaryContainer: Nocturnal.onPrimaryContainer,
  secondary: Nocturnal.secondary,
  onSecondary: Nocturnal.onSecondary,
  secondaryContainer: Nocturnal.secondaryContainer,
  onSecondaryContainer: Nocturnal.onSecondaryContainer,
  tertiary: Nocturnal.tertiary,
  onTertiary: Nocturnal.onTertiary,
  tertiaryContainer: Nocturnal.tertiaryContainer,
  onTertiaryContainer: Nocturnal.onTertiaryContainer,
  error: Nocturnal.error,
  onError: Nocturnal.onError,
  errorContainer: Nocturnal.errorContainer,
  onErrorContainer: Nocturnal.onErrorContainer,
  surface: Nocturnal.surface,
  onSurface: Nocturnal.onSurface,
  onSurfaceVariant: Nocturnal.onSurfaceVariant,
  surfaceDim: Nocturnal.surface,
  surfaceBright: Nocturnal.surfaceBright,
  surfaceContainerLowest: Nocturnal.surfaceContainerLowest,
  surfaceContainerLow: Nocturnal.surfaceContainerLow,
  surfaceContainer: Nocturnal.surfaceContainer,
  surfaceContainerHigh: Nocturnal.surfaceContainerHigh,
  surfaceContainerHighest: Nocturnal.surfaceContainerHighest,
  outline: Nocturnal.outline,
  outlineVariant: Nocturnal.outlineVariant,
  inverseSurface: Nocturnal.onSurface,
  onInverseSurface: Color(0xFF2A322E),
  inversePrimary: Nocturnal.inversePrimary,
  surfaceTint: Nocturnal.primary,
  shadow: Colors.black,
  scrim: Colors.black,
);

TextStyle _epilogue(
  double size,
  double height,
  FontWeight weight, [
  double spacing = 0,
]) => TextStyle(
  fontFamily: Nocturnal.headlineFont,
  fontSize: size,
  height: height / size,
  fontWeight: weight,
  letterSpacing: spacing * size,
);

TextStyle _grotesk(
  double size,
  double height,
  FontWeight weight, [
  double spacing = 0,
]) => TextStyle(
  fontFamily: Nocturnal.bodyFont,
  fontSize: size,
  height: height / size,
  fontWeight: weight,
  letterSpacing: spacing * size,
);

/// Skala typografii z DESIGN.md, przypisana do ról Material 3.
final _textTheme = TextTheme(
  displayLarge: _epilogue(48, 56, FontWeight.w700, -0.02),
  displayMedium: _epilogue(36, 44, FontWeight.w700, -0.02),
  displaySmall: _epilogue(32, 40, FontWeight.w600, -0.01),
  headlineLarge: _epilogue(32, 40, FontWeight.w600, -0.01),
  headlineMedium: _epilogue(26, 32, FontWeight.w600, -0.01),
  headlineSmall: _epilogue(22, 28, FontWeight.w600),
  titleLarge: _epilogue(22, 28, FontWeight.w600),
  titleMedium: _epilogue(18, 24, FontWeight.w600),
  titleSmall: _grotesk(14, 20, FontWeight.w600, 0.03),
  bodyLarge: _grotesk(16, 24, FontWeight.w400, 0.01),
  bodyMedium: _grotesk(14, 20, FontWeight.w400, 0.01),
  bodySmall: _grotesk(12, 16, FontWeight.w400, 0.02),
  labelLarge: _grotesk(14, 20, FontWeight.w600, 0.03),
  labelMedium: _grotesk(12, 16, FontWeight.w500, 0.04),
  labelSmall: _grotesk(10, 14, FontWeight.w600, 0.06),
).apply(bodyColor: Nocturnal.onSurface, displayColor: Nocturnal.onSurface);

const _radius = BorderRadius.all(Radius.circular(12));

/// Ciemny motyw całej aplikacji.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _colorScheme,
  fontFamily: Nocturnal.bodyFont,
  textTheme: _textTheme,
  scaffoldBackgroundColor: Nocturnal.surface,
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Nocturnal.surfaceContainer,
    modalBackgroundColor: Nocturnal.surfaceContainer,
    dragHandleColor: Nocturnal.outlineVariant,
    showDragHandle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Nocturnal.surfaceContainerLow,
    hintStyle: TextStyle(
      color: Nocturnal.onSurfaceVariant.withValues(alpha: 0.5),
    ),
    labelStyle: const TextStyle(color: Nocturnal.onSurfaceVariant),
    border: const OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: Nocturnal.primary, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: Nocturnal.primaryContainer,
      foregroundColor: Nocturnal.onPrimaryContainer,
      minimumSize: const Size(64, 48),
      shape: const RoundedRectangleBorder(borderRadius: _radius),
      textStyle: _textTheme.labelLarge,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: Nocturnal.surfaceContainerHigh,
      foregroundColor: Nocturnal.onSurface,
      side: BorderSide.none,
      minimumSize: const Size(64, 48),
      shape: const RoundedRectangleBorder(borderRadius: _radius),
      textStyle: _textTheme.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Nocturnal.primary,
      textStyle: _textTheme.labelLarge,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Nocturnal.surfaceContainerHighest,
    contentTextStyle: _textTheme.bodyMedium,
    actionTextColor: Nocturnal.primary,
    shape: const RoundedRectangleBorder(borderRadius: _radius),
  ),
  cardTheme: const CardThemeData(
    color: Nocturnal.surfaceContainer,
    shape: RoundedRectangleBorder(borderRadius: _radius),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Nocturnal.surfaceContainerHigh,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Nocturnal.primary,
  ),
);
