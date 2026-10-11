import 'package:flutter/material.dart';

/// Apple-inspired auth tokens. Scoped to authentication surfaces so the
/// global theme (and every other page) stays untouched.
class AuthTokens {
  const AuthTokens._();

  // ---- Dark ----
  static const Color darkBackground = Color(0xFF050505);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkElevated = Color(0xFF191919);
  static const Color darkInput = Color(0xFF101010);
  static const Color darkBorder = Color(0xFF292929);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);
  static const Color darkAction = Color(0xFFF5F5F7);
  static const Color darkActionFg = Color(0xFF0A0A0A);

  // ---- Light ----
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E2E6);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightTextMuted = Color(0xFFAEAEB2);
  static const Color lightAction = Color(0xFF1D1D1F);
  static const Color lightActionFg = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFF87171);

  /// Amber reserved for the advisory password-strength meter only.
  static const Color warning = Color(0xFFF59E0B);

  // ---- Shape / motion ----
  static const double radiusCard = 20;
  static const double radiusField = 14;
  static const double radiusButton = 14;
  static const double radiusPill = 999;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration navSlide = Duration(milliseconds: 180);

  /// Zero durations when the OS requests reduced motion.
  static Duration motion(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Glass tints per spec: ~5–9% white on dark, ~55–75% on light.
class GlassTokens {
  const GlassTokens._();

  static Color surface(bool dark) => dark
      ? const Color.fromRGBO(255, 255, 255, 0.07)
      : const Color.fromRGBO(255, 255, 255, 0.65);

  static Color border(bool dark) => dark
      ? const Color.fromRGBO(255, 255, 255, 0.13)
      : const Color(0xFFE0E0E5);

  static Color highlight(bool dark) => dark
      ? const Color.fromRGBO(255, 255, 255, 0.06)
      : const Color.fromRGBO(255, 255, 255, 0.5);
}
