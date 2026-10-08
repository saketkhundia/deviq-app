import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'deviq_colors.dart';

/// Typography: Geist-compatible sans (Inter) + monospace for code/terminal.
/// Section labels are small uppercase with ~0.05em letter spacing.
class DevIQText {
  const DevIQText._();

  static TextStyle hero(BuildContext context, {double? size}) {
    final base = Theme.of(context).textTheme.displayLarge!;
    return base.copyWith(
      fontSize: size ?? 40,
      height: 1.05,
      letterSpacing: -0.02,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01,
          );

  static TextStyle sectionLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05 / 0.012, // ~0.05em expressed in logical px
            // NOTE: Flutter letterSpacing is in logical pixels; 0.6 ≈ 0.05em
            // at 12sp. Keep restrained.
          );

  static TextStyle mono(BuildContext context, {double size = 12.5}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, height: 1.5);
}

ThemeData _base(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? DevIQColors.darkBackground : DevIQColors.lightBackground;
  final surface =
      dark ? DevIQColors.darkSurface : DevIQColors.lightSurface;
  final border =
      dark ? DevIQColors.darkBorder : DevIQColors.lightBorder;
  final textPrimary = dark
      ? DevIQColors.darkTextPrimary
      : DevIQColors.lightTextPrimary;
  final textSecondary = dark
      ? DevIQColors.darkTextSecondary
      : DevIQColors.lightTextSecondary;
  final accent =
      dark ? DevIQColors.darkAccent : DevIQColors.lightAccent;
  final accentFg =
      dark ? DevIQColors.darkAccentFg : DevIQColors.lightAccentFg;

  final sans = GoogleFonts.interTextTheme(
    (dark ? ThemeData.dark() : ThemeData.light()).textTheme,
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: accentFg,
    secondary: textSecondary,
    onSecondary: bg,
    surface: surface,
    onSurface: textPrimary,
    error: DevIQColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: surface,
    dividerColor: border,
    textTheme: sans.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.card),
        side: BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: sans.bodyMedium?.copyWith(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.button),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.button),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.button),
        borderSide: BorderSide(
            color: dark
                ? DevIQColors.darkBorderStrong
                : DevIQColors.lightBorderStrong,
            width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.button),
        borderSide: const BorderSide(color: DevIQColors.error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      labelStyle: sans.labelMedium,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevIQRadius.pill)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DevIQRadius.sheet),
        side: BorderSide(color: border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? DevIQColors.darkSurface : textPrimary,
      contentTextStyle: sans.bodyMedium?.copyWith(
          color: dark ? textPrimary : Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevIQRadius.button)),
    ),
  );
}

class DevIQTheme {
  const DevIQTheme._();
  static ThemeData dark() => _base(Brightness.dark);
  static ThemeData light() => _base(Brightness.light);
}
